import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/ai/domain/entities/ai_category_ref.dart';
import 'package:equity_tracker/features/ai/domain/enums/ai_intent.dart';
import 'package:equity_tracker/features/ai/domain/models/chat_message.dart';
import 'package:equity_tracker/features/ai/domain/models/workflow_step_result.dart';
import 'package:equity_tracker/features/ai/domain/ports/i_ledger_gateway.dart';
import 'package:equity_tracker/features/ai/domain/workflows/i_ai_workflow.dart';
import 'package:equity_tracker/features/ai/infrastructure/agents/correction_agent/correction_agent.dart';
import 'package:equity_tracker/features/ai/infrastructure/agents/extraction_agent/extraction_agent.dart';
import 'package:equity_tracker/features/ai/infrastructure/agents/store_lookup_agent/store_lookup_agent.dart';
import 'package:equity_tracker/features/ai/infrastructure/agents/validation_agent/validation_agent.dart';
import 'package:equity_tracker/features/ai/infrastructure/gateways/ledger_gateway_impl.dart';
import 'package:equity_tracker/features/ai/infrastructure/map/i_map_search_service.dart';
import 'package:equity_tracker/features/ai/infrastructure/map/google_map_search_service.dart';
import 'package:equity_tracker/features/ai/presentation/controllers/ai_config_controller.dart';
import 'package:equity_tracker/features/ai/application/workflows/bookkeeping/bookkeeping_state.dart';
import 'package:equity_tracker/features/ai/application/workflows/bookkeeping/workers/i_bookkeeping_worker.dart';
import 'package:equity_tracker/features/ai/application/workflows/bookkeeping/workers/store_lookup_worker.dart';
import 'package:equity_tracker/features/ai/application/workflows/bookkeeping/workers/validation_worker.dart';
import 'package:equity_tracker/features/ai/application/workflows/bookkeeping/workers/correction_worker.dart';

class BookkeepingWorkflow implements IAIWorkflow {
  final ILedgerGateway ledgerGateway;
  final ExtractionAgent extractionAgent;
  final List<IBookkeepingWorker> workers;

  BookkeepingWorkflow({
    required this.ledgerGateway,
    required this.extractionAgent,
    required StoreLookupAgent storeLookupAgent,
    required IMapSearchService mapSearchService,
    required ValidationAgent validationAgent,
    required CorrectionAgent correctionAgent,
    required bool isGoogleMapEnabled,
  }) : workers = [
          StoreLookupWorker(storeLookupAgent, mapSearchService, isGoogleMapEnabled: isGoogleMapEnabled),
          ValidationWorker(validationAgent),
          CorrectionWorker(correctionAgent),
        ];

  @override
  AIIntent get supportedIntent => AIIntent.addTransaction;

  @override
  Future<WorkflowStepResult> start(
    String userInput, {
    void Function(String step)? onProgress,
  }) async {
    onProgress?.call('正在提取花費資訊...');
    final categories = await ledgerGateway.getActiveCategories(isExpense: true);

    final drafts = await extractionAgent.execute(
      userInput,
      categories: categories,
      onChunk: null,
    );

    if (drafts.isEmpty) {
      return const WorkflowCompleted(message: '未能在您的輸入中辨識出記帳資訊，請重新描述看看。');
    }

    final validCategoryIds = categories.map((c) => c.id).toSet();
    final otherCategoryId = categories
        .firstWhere(
          (c) => c.name == '其他',
          orElse: () => categories.first,
        )
        .id;

    final records = drafts.map((draft) {
      String safeCategoryId = draft.categoryId ?? otherCategoryId;
      if (!validCategoryIds.contains(safeCategoryId)) {
        safeCategoryId = otherCategoryId;
      }
      return BookkeepingRecord(draft.copyWith(categoryId: safeCategoryId));
    }).toList();

    return _runBlackboardLoop(records, userInput, categories, onProgress: onProgress);
  }

  @override
  Future<WorkflowStepResult> resume(
    String userReply,
    WorkflowSuspendedState suspendedState, {
    void Function(String step)? onProgress,
  }) async {
    if (suspendedState is! BookkeepingSuspendedState) {
      return const WorkflowFailed('無效的工作流狀態');
    }

    final categories = await ledgerGateway.getActiveCategories(isExpense: true);
    final record = suspendedState.records[suspendedState.recordIndex];

    if (suspendedState is StoreSelectionSuspendedState) {
      if (suspendedState.options.contains(userReply)) {
        onProgress?.call('收到選項「$userReply」，準備更新店家名稱...');
        record.updateStore(userReply);
      } else {
        record.metadata['CorrectionWorker_Input'] = userReply;
        record.metadata['CorrectionWorker_Question'] = suspendedState.message;
        record.metadata['CorrectionWorker_Categories'] = categories;
        record.metadata['User_Corrected_Store'] = true;
      }
    } else if (suspendedState is CorrectionSuspendedState) {
      record.metadata['CorrectionWorker_Input'] = userReply;
      record.metadata['CorrectionWorker_Question'] = suspendedState.question;
      record.metadata['CorrectionWorker_Categories'] = categories;
    }

    return _runBlackboardLoop(
      suspendedState.records,
      suspendedState.originalText,
      categories,
      onProgress: onProgress,
    );
  }

  Future<WorkflowStepResult> _runBlackboardLoop(
    List<BookkeepingRecord> records,
    String originalText,
    List<AICategoryRef> categories, {
    void Function(String)? onProgress,
  }) async {
    for (int i = 0; i < records.length; i++) {
      final record = records[i];
      if (record.isResolved) continue;

      bool changed = true;
      while (changed && !record.isResolved) {
        changed = false;

        for (final worker in workers) {
          if (await worker.requiresProcessing(record)) {
            final result = await worker.process(
              i,
              record,
              records,
              originalText,
              onProgress: onProgress,
            );

            if (result != null) {
              return result;
            }

            changed = true;
            break;
          }
        }
      }

      if (!changed) {
        record.markResolved();
      }
    }

    // 當所有紀錄皆處理完成，透過 ILedgerGateway 儲存至資料庫
    onProgress?.call('正在儲存 ${records.length} 筆資料...');
    final drafts = records.map((r) => r.data).toList();
    final createdItems = await ledgerGateway.createTransactions(drafts);

    return WorkflowCompleted(
      message: '成功新增 ${createdItems.length} 筆帳務！',
      payload: CreatedTransactionsAttachment(createdItems),
    );
  }
}

final bookkeepingWorkflowProvider = Provider.autoDispose<BookkeepingWorkflow>((ref) {
  final ledgerGateway = ref.watch(ledgerGatewayProvider);
  final extractionAgent = ref.watch(extractionAgentProvider);
  final storeLookupAgent = ref.watch(storeLookupAgentProvider);
  final mapSearchService = ref.watch(mapSearchServiceProvider);
  final validationAgent = ref.watch(validationAgentProvider);
  final correctionAgent = ref.watch(correctionAgentProvider);
  final isGoogleMapEnabled = ref.watch(aiConfigControllerProvider).isGoogleMapEnabled;

  return BookkeepingWorkflow(
    ledgerGateway: ledgerGateway,
    extractionAgent: extractionAgent,
    storeLookupAgent: storeLookupAgent,
    mapSearchService: mapSearchService,
    validationAgent: validationAgent,
    correctionAgent: correctionAgent,
    isGoogleMapEnabled: isGoogleMapEnabled,
  );
});
