import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/ai/domain/entities/category_correction_item.dart';
import 'package:equity_tracker/features/ai/domain/enums/ai_intent.dart';
import 'package:equity_tracker/features/ai/domain/models/chat_message.dart';
import 'package:equity_tracker/features/ai/domain/models/workflow_step_result.dart';
import 'package:equity_tracker/features/ai/domain/ports/i_ledger_gateway.dart';
import 'package:equity_tracker/features/ai/domain/workflows/i_ai_workflow.dart';
import 'package:equity_tracker/features/ai/infrastructure/agents/batch_categorization_agent/batch_categorization_agent.dart';
import 'package:equity_tracker/features/ai/infrastructure/gateways/ledger_gateway_impl.dart';

class ReceiptReclassifyWorkflow implements IAIWorkflow {
  final ILedgerGateway ledgerGateway;
  final BatchCategorizationAgent categorizationAgent;

  ReceiptReclassifyWorkflow({
    required this.ledgerGateway,
    required this.categorizationAgent,
  });

  @override
  AIIntent get supportedIntent => AIIntent.reclassifyReceipts;

  @override
  Future<WorkflowStepResult> start(
    String userInput, {
    void Function(String step)? onProgress,
  }) async {
    onProgress?.call('正在搜尋類別為「發票」的記帳項目...');
    final invoiceCat = await ledgerGateway.findCategoryByName('發票', isExpense: true);

    if (invoiceCat == null) {
      return const WorkflowCompleted(
        message: '系統目前沒有找到「發票」這個類別，無需進行矯正。',
      );
    }

    final invoiceTransactions =
        await ledgerGateway.getTransactionsByCategoryId(invoiceCat.id);

    if (invoiceTransactions.isEmpty) {
      return const WorkflowCompleted(
        message: '太棒了！目前沒有任何類別為「發票」的記帳項目需要矯正。',
      );
    }

    onProgress?.call('找到 ${invoiceTransactions.length} 筆發票項目，準備進行智慧分類...');
    final allCategories = await ledgerGateway.getActiveCategories(isExpense: true);
    final targetCategories = allCategories.where((c) => c.id != invoiceCat.id).toList();

    final fallbackCat = allCategories.firstWhere(
      (c) => c.name == '其他',
      orElse: () => allCategories.first,
    );

    final categoryMap = {for (final c in allCategories) c.id: c};
    final txMap = {for (final t in invoiceTransactions) t.id: t};

    // 分批處理 (Chunking)，每批 15 筆
    const chunkSize = 15;
    final List<CategorizedProposal> allProposals = [];

    for (var i = 0; i < invoiceTransactions.length; i += chunkSize) {
      final end = (i + chunkSize > invoiceTransactions.length)
          ? invoiceTransactions.length
          : i + chunkSize;
      final chunk = invoiceTransactions.sublist(i, end);

      onProgress?.call('正在分析第 ${i + 1} ~ $end 筆發票 (共 ${invoiceTransactions.length} 筆)...');

      final proposals = await categorizationAgent.execute(
        BatchCategorizationInput(
          items: chunk,
          categories: targetCategories,
          fallbackCategoryId: fallbackCat.id,
        ),
      );

      allProposals.addAll(proposals);
    }

    // 驗證分類合法性並組裝更新清單
    final Map<int, String> txIdToNewCategoryId = {};
    final List<CategoryCorrectionItem> correctionItems = [];

    for (final prop in allProposals) {
      final originalTx = txMap[prop.transactionId];
      if (originalTx == null) continue;

      String finalCatId = prop.categoryId;
      if (!categoryMap.containsKey(finalCatId)) {
        finalCatId = fallbackCat.id;
      }

      final newCat = categoryMap[finalCatId]!;
      txIdToNewCategoryId[originalTx.id] = finalCatId;

      correctionItems.add(
        CategoryCorrectionItem(
          transactionId: originalTx.id,
          title: originalTx.title,
          note: originalTx.note,
          amount: originalTx.amount,
          oldCategoryId: invoiceCat.id,
          oldCategoryName: invoiceCat.name,
          newCategoryId: newCat.id,
          newCategoryName: newCat.name,
          reason: prop.reason,
        ),
      );
    }

    if (txIdToNewCategoryId.isEmpty) {
      return const WorkflowCompleted(
        message: '發票項目分析完畢，未產生需要變更的項目。',
      );
    }

    // 透過 ILedgerGateway 執行原子批次更新並通知刷新
    onProgress?.call('正在儲存 ${txIdToNewCategoryId.length} 筆矯正後的分類...');
    await ledgerGateway.batchUpdateCategories(txIdToNewCategoryId);

    return WorkflowCompleted(
      message: '成功矯正 ${correctionItems.length} 筆發票記帳項目的類別！',
      payload: CategoryCorrectionAttachment(correctionItems),
    );
  }

  @override
  Future<WorkflowStepResult> resume(
    String userReply,
    WorkflowSuspendedState suspendedState, {
    void Function(String step)? onProgress,
  }) async {
    return const WorkflowFailed('發票矯正任務為一次性批次處理，無需補充回覆。');
  }
}

final receiptReclassifyWorkflowProvider =
    Provider.autoDispose<ReceiptReclassifyWorkflow>((ref) {
  return ReceiptReclassifyWorkflow(
    ledgerGateway: ref.watch(ledgerGatewayProvider),
    categorizationAgent: ref.watch(batchCategorizationAgentProvider),
  );
});
