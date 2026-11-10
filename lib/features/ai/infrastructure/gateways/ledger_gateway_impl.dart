import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/core/enums/transaction_type.dart';
import 'package:equity_tracker/core/providers/repository_providers.dart';
import 'package:equity_tracker/features/category/data/category_repository.dart';
import 'package:equity_tracker/features/transaction/data/transaction_repository.dart';
import 'package:equity_tracker/features/transaction/data/transaction_model.dart';
import 'package:equity_tracker/features/transaction/providers/transaction_notifier.dart';
import 'package:equity_tracker/features/notion_sync/controllers/notion_config_controller.dart';
import 'package:equity_tracker/features/notion_sync/services/notion_sync_service.dart';
import 'package:equity_tracker/features/ai/domain/entities/ai_category_ref.dart';
import 'package:equity_tracker/features/ai/domain/entities/ai_transaction_draft.dart';
import 'package:equity_tracker/features/ai/domain/entities/ai_transaction_summary.dart';
import 'package:equity_tracker/features/ai/domain/entities/ai_transaction_view_item.dart';
import 'package:equity_tracker/features/ai/domain/ports/i_ledger_gateway.dart';

class LedgerGatewayImpl implements ILedgerGateway {
  final Ref _ref;

  LedgerGatewayImpl(this._ref);

  CategoryRepository get _categoryRepo => _ref.read(categoryRepositoryProvider);
  TransactionRepository get _transactionRepo => _ref.read(transactionRepositoryProvider);

  @override
  Future<List<AICategoryRef>> getActiveCategories({bool? isExpense}) async {
    final categories = await _categoryRepo.getCategories();
    return categories
        .where((c) => c.isEnabled)
        .where((c) => isExpense == null || (isExpense ? c.type == TransactionType.expense : c.type == TransactionType.income))
        .map((c) => AICategoryRef(
              id: c.id,
              name: c.name,
              isExpense: c.type == TransactionType.expense,
            ))
        .toList();
  }

  @override
  Future<AICategoryRef?> findCategoryByName(String name, {bool? isExpense}) async {
    final categories = await getActiveCategories(isExpense: isExpense);
    final target = name.trim().toLowerCase();
    for (final c in categories) {
      if (c.name.trim().toLowerCase() == target) {
        return c;
      }
    }
    return null;
  }

  @override
  Future<List<AITransactionSummary>> getTransactionsByCategoryId(String categoryId) async {
    final txs = await _transactionRepo.getTransactionsByCategoryId(categoryId);
    return txs
        .where((t) => t.id != null)
        .map((t) => AITransactionSummary(
              id: t.id!,
              title: t.title ?? '',
              note: t.note,
              amount: t.amount,
              categoryId: t.categoryId,
              date: t.date,
            ))
        .toList();
  }

  @override
  Future<List<AITransactionViewItem>> createTransactions(List<AITransactionDraft> drafts) async {
    final transactionNotifier = _ref.read(transactionNotifierProvider.notifier);
    final List<AITransactionViewItem> createdItems = [];

    for (final draft in drafts) {
      if (draft.price == null || draft.item == null) continue;

      final title = (draft.store != null && draft.store!.isNotEmpty)
          ? draft.store!
          : draft.item!;
      final note = draft.item!;

      DateTime txDate = DateTime.now();
      if (draft.date != null && draft.date!.isNotEmpty) {
        txDate = DateTime.tryParse(draft.date!) ?? DateTime.now();
      }

      final tx = TransactionModel(
        title: title,
        amount: draft.price!,
        categoryId: draft.categoryId ?? 'other',
        type: TransactionType.expense,
        date: txDate,
        createdAt: DateTime.now(),
        note: note,
      );

      // 呼叫 Notifier 新增（包含 Optimistic update、Notion sync、以及更新內部列表）
      await transactionNotifier.addTransaction(tx);

      createdItems.add(AITransactionViewItem(
        id: tx.id,
        title: title,
        note: note,
        amount: tx.amount,
        categoryId: tx.categoryId,
        date: txDate,
      ));
    }

    return createdItems;
  }

  @override
  Future<void> batchUpdateCategories(Map<int, String> txIdToNewCategoryId) async {
    if (txIdToNewCategoryId.isEmpty) return;

    final notionConfig = _ref.read(notionConfigControllerProvider);
    final isNotionEnabled = notionConfig.isEnabled;

    // 1. 執行 SQLite Batch 批次更新
    await _transactionRepo.batchUpdateTransactionsCategory(
      txIdToNewCategoryId,
      markPendingSync: isNotionEnabled,
    );

    // 2. 若有開啟 Notion 同步，於背景靜默推進變更
    if (isNotionEnabled) {
      Future.microtask(() {
        _ref.read(notionSyncServiceProvider).pushPendingChanges(silent: true);
      });
    }

    // 3. 刷新交易列表快取，確保所有 UI (如首頁/趨勢/清單) 同步呈現最新分類
    _ref.invalidate(transactionListProvider);
  }
}

final ledgerGatewayProvider = Provider.autoDispose<ILedgerGateway>((ref) {
  return LedgerGatewayImpl(ref);
});
