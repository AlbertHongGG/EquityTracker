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

/// 領域帳本防腐閘道實作 (LedgerGatewayImpl)
///
/// 遵循 Clean Architecture 與依賴注入 (DI) 原則：
/// 1. 不持有任何狀態管理框架內部的 Ref 物件，為純粹的領域適配器。
/// 2. 所有資料庫存取、狀態變更皆透過明確建構子參數注入。
class LedgerGatewayImpl implements ILedgerGateway {
  final CategoryRepository _categoryRepo;
  final TransactionRepository _transactionRepo;
  final TransactionList _transactionList;
  final bool Function() _isNotionSyncEnabled;
  final void Function() _pushNotionPendingChanges;
  final void Function() _onTransactionsChanged;

  LedgerGatewayImpl({
    required CategoryRepository categoryRepo,
    required TransactionRepository transactionRepo,
    required TransactionList transactionList,
    required bool Function() isNotionSyncEnabled,
    required void Function() pushNotionPendingChanges,
    required void Function() onTransactionsChanged,
  })  : _categoryRepo = categoryRepo,
        _transactionRepo = transactionRepo,
        _transactionList = transactionList,
        _isNotionSyncEnabled = isNotionSyncEnabled,
        _pushNotionPendingChanges = pushNotionPendingChanges,
        _onTransactionsChanged = onTransactionsChanged;

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
      await _transactionList.addTransaction(tx);

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

    final isNotionEnabled = _isNotionSyncEnabled();

    // 1. 執行 SQLite Batch 批次更新
    await _transactionRepo.batchUpdateTransactionsCategory(
      txIdToNewCategoryId,
      markPendingSync: isNotionEnabled,
    );

    // 2. 若有開啟 Notion 同步，於背景靜默推進變更
    if (isNotionEnabled) {
      _pushNotionPendingChanges();
    }

    // 3. 刷新交易列表快取，確保所有 UI (如首頁/趨勢/清單) 同步呈現最新分類
    _onTransactionsChanged();
  }
}

/// 領域帳本閘道 Provider (根作用域單例，非 autoDispose)
final ledgerGatewayProvider = Provider<ILedgerGateway>((ref) {
  return LedgerGatewayImpl(
    categoryRepo: ref.watch(categoryRepositoryProvider),
    transactionRepo: ref.watch(transactionRepositoryProvider),
    transactionList: ref.watch(transactionNotifierProvider.notifier),
    isNotionSyncEnabled: () => ref.read(notionConfigControllerProvider).isEnabled,
    pushNotionPendingChanges: () {
      Future.microtask(() {
        ref.read(notionSyncServiceProvider).pushPendingChanges(silent: true);
      });
    },
    onTransactionsChanged: () {
      ref.invalidate(transactionListProvider);
    },
  );
});
