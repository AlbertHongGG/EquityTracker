import 'package:flutter_test/flutter_test.dart';
import 'package:equity_tracker/features/ai/domain/entities/ai_category_ref.dart';
import 'package:equity_tracker/features/ai/domain/entities/ai_transaction_draft.dart';
import 'package:equity_tracker/features/ai/domain/entities/ai_transaction_summary.dart';
import 'package:equity_tracker/features/ai/domain/entities/ai_transaction_view_item.dart';
import 'package:equity_tracker/features/ai/domain/models/workflow_step_result.dart';
import 'package:equity_tracker/features/ai/domain/models/chat_message.dart';
import 'package:equity_tracker/features/ai/domain/ports/i_ledger_gateway.dart';
import 'package:equity_tracker/features/ai/infrastructure/agents/batch_categorization_agent/batch_categorization_agent.dart';
import 'package:equity_tracker/features/ai/infrastructure/providers/ai_provider.dart';
import 'package:equity_tracker/features/ai/application/workflows/receipt_reclassify/receipt_reclassify_workflow.dart';

class FakeAIProvider implements AIProvider {
  @override
  String get name => 'fake';

  @override
  Future<GenerateResponse> generate(GenerateRequest request) async {
    return GenerateResponse(text: '[]');
  }

  @override
  Stream<GenerateResponse> generateStream(GenerateRequest request) async* {
    yield GenerateResponse(text: '[]');
  }
}

class FakeBatchCategorizationAgent extends BatchCategorizationAgent {
  List<CategorizedProposal> mockProposals = [];

  FakeBatchCategorizationAgent() : super(FakeAIProvider());

  @override
  Future<List<CategorizedProposal>> execute(
    BatchCategorizationInput input, {
    void Function(String)? onChunk,
  }) async {
    return mockProposals;
  }
}

class MockLedgerGateway implements ILedgerGateway {
  AICategoryRef? invoiceCategory;
  List<AICategoryRef> activeCategories = [];
  List<AITransactionSummary> invoiceTransactions = [];
  Map<int, String>? lastBatchUpdates;

  @override
  Future<AICategoryRef?> findCategoryByName(String name, {bool? isExpense}) async {
    if (name == '發票') return invoiceCategory;
    return activeCategories.cast<AICategoryRef?>().firstWhere(
          (c) => c?.name == name,
          orElse: () => null,
        );
  }

  @override
  Future<List<AICategoryRef>> getActiveCategories({bool? isExpense}) async {
    return activeCategories;
  }

  @override
  Future<List<AITransactionSummary>> getTransactionsByCategoryId(String categoryId) async {
    if (invoiceCategory != null && categoryId == invoiceCategory!.id) {
      return invoiceTransactions;
    }
    return [];
  }

  @override
  Future<void> batchUpdateCategories(Map<int, String> txIdToNewCategoryId) async {
    lastBatchUpdates = Map.from(txIdToNewCategoryId);
  }

  @override
  Future<List<AITransactionViewItem>> createTransactions(List<AITransactionDraft> drafts) async {
    return [];
  }
}

void main() {
  group('ReceiptReclassifyWorkflow Tests', () {
    late MockLedgerGateway mockGateway;
    late FakeBatchCategorizationAgent fakeAgent;
    late ReceiptReclassifyWorkflow workflow;

    setUp(() {
      mockGateway = MockLedgerGateway();
      fakeAgent = FakeBatchCategorizationAgent();
      workflow = ReceiptReclassifyWorkflow(
        ledgerGateway: mockGateway,
        categorizationAgent: fakeAgent,
      );
    });

    test('當系統無發票類別時，回傳提示說明', () async {
      mockGateway.invoiceCategory = null;

      final result = await workflow.start('重新分類發票');

      expect(result, isA<WorkflowCompleted>());
      final completed = result as WorkflowCompleted;
      expect(completed.message, contains('沒有找到「發票」這個類別'));
      expect(completed.payload, isNull);
    });

    test('當發票類別下無任何交易時，回傳無需矯正提示', () async {
      mockGateway.invoiceCategory = const AICategoryRef(id: 'cat_invoice', name: '發票');
      mockGateway.invoiceTransactions = [];

      final result = await workflow.start('重新分類發票');

      expect(result, isA<WorkflowCompleted>());
      final completed = result as WorkflowCompleted;
      expect(completed.message, contains('沒有任何類別為「發票」的記帳項目需要矯正'));
      expect(completed.payload, isNull);
    });

    test('成功辨識發票並批次更新為真實類別', () async {
      final invoiceCat = const AICategoryRef(id: 'cat_invoice', name: '發票');
      final foodCat = const AICategoryRef(id: 'cat_food', name: '伙食');
      final otherCat = const AICategoryRef(id: 'cat_other', name: '其他');

      mockGateway.invoiceCategory = invoiceCat;
      mockGateway.activeCategories = [invoiceCat, foodCat, otherCat];
      mockGateway.invoiceTransactions = [
        AITransactionSummary(
          id: 101,
          title: '全聯福利中心',
          note: '吐司、鮮奶',
          amount: 150,
          categoryId: invoiceCat.id,
          date: DateTime.now(),
        ),
      ];

      fakeAgent.mockProposals = [
        const CategorizedProposal(
          transactionId: 101,
          categoryId: 'cat_food',
          reason: '生鮮食品消費',
        ),
      ];

      final result = await workflow.start('重新分類發票');

      expect(result, isA<WorkflowCompleted>());
      final completed = result as WorkflowCompleted;
      expect(completed.message, contains('成功矯正 1 筆發票記帳項目的類別'));
      expect(completed.payload, isA<CategoryCorrectionAttachment>());

      final attachment = completed.payload as CategoryCorrectionAttachment;
      expect(attachment.items.length, 1);
      expect(attachment.items.first.transactionId, 101);
      expect(attachment.items.first.oldCategoryName, '發票');
      expect(attachment.items.first.newCategoryName, '伙食');

      // 驗證是否有透過 Gateway 寫入資料庫
      expect(mockGateway.lastBatchUpdates, isNotNull);
      expect(mockGateway.lastBatchUpdates![101], 'cat_food');
    });

    test('當 AI 回傳不存在的分類 ID 時，自動防呆降級至「其他」分類', () async {
      final invoiceCat = const AICategoryRef(id: 'cat_invoice', name: '發票');
      final foodCat = const AICategoryRef(id: 'cat_food', name: '伙食');
      final otherCat = const AICategoryRef(id: 'cat_other', name: '其他');

      mockGateway.invoiceCategory = invoiceCat;
      mockGateway.activeCategories = [invoiceCat, foodCat, otherCat];
      mockGateway.invoiceTransactions = [
        AITransactionSummary(
          id: 102,
          title: '神秘特約商店',
          note: null,
          amount: 300,
          categoryId: invoiceCat.id,
          date: DateTime.now(),
        ),
      ];

      fakeAgent.mockProposals = [
        const CategorizedProposal(
          transactionId: 102,
          categoryId: 'non_existent_uuid', // 幻覺 ID
          reason: '未知消費',
        ),
      ];

      final result = await workflow.start('重新分類發票');

      expect(result, isA<WorkflowCompleted>());
      final completed = result as WorkflowCompleted;
      final attachment = completed.payload as CategoryCorrectionAttachment;
      expect(attachment.items.first.newCategoryId, 'cat_other');
      expect(attachment.items.first.newCategoryName, '其他');

      expect(mockGateway.lastBatchUpdates![102], 'cat_other');
    });
  });
}
