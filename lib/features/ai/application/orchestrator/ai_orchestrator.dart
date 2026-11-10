import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/ai/domain/enums/ai_intent.dart';
import 'package:equity_tracker/features/ai/domain/models/workflow_step_result.dart';
import 'package:equity_tracker/features/ai/domain/workflows/i_ai_workflow.dart';
import 'package:equity_tracker/features/ai/infrastructure/agents/intent_router_agent/intent_router_agent.dart';
import 'package:equity_tracker/features/ai/application/workflows/bookkeeping/bookkeeping_workflow.dart';
import 'package:equity_tracker/features/ai/application/workflows/receipt_reclassify/receipt_reclassify_workflow.dart';

class AIOrchestrator {
  final IntentRouterAgent _intentRouter;
  final Map<AIIntent, IAIWorkflow> _workflows;

  AIOrchestrator({
    required IntentRouterAgent intentRouter,
    required List<IAIWorkflow> workflows,
  })  : _intentRouter = intentRouter,
        _workflows = {for (final w in workflows) w.supportedIntent: w};

  Future<WorkflowStepResult> handleInput(
    String input, {
    WorkflowSuspendedState? suspendedState,
    void Function(String step)? onProgress,
  }) async {
    // 1. 若當前已有處於掛起等待狀態的工作流，直接委派 resume
    if (suspendedState != null) {
      final workflow = _workflows[suspendedState.intent];
      if (workflow != null) {
        return workflow.resume(input, suspendedState, onProgress: onProgress);
      }
    }

    // 2. 無掛起任務：透過意圖路由器分析使用者意圖
    onProgress?.call('正在理解您的需求...');
    final routerResult = await _intentRouter.execute(input);

    if (routerResult.intent == AIIntent.unsupported) {
      return const WorkflowCompleted(
        message: '抱歉，我目前支援「自動智慧記帳」（例如：午餐吃排骨飯 100 元）'
            '以及「發票類別智慧矯正」（例如：幫我把發票類別重新整理）。\n請問需要我協助您哪一項呢？',
      );
    }

    // 3. 取得意圖對應的工作流並啟動
    final workflow = _workflows[routerResult.intent];
    if (workflow == null) {
      return WorkflowCompleted(
        message: '尚未實作此意圖處理器: ${routerResult.intent.name}',
      );
    }

    return workflow.start(input, onProgress: onProgress);
  }
}

final aiOrchestratorProvider = Provider.autoDispose<AIOrchestrator>((ref) {
  final intentRouter = ref.watch(intentRouterAgentProvider);
  final bookkeepingWorkflow = ref.watch(bookkeepingWorkflowProvider);
  final receiptReclassifyWorkflow = ref.watch(receiptReclassifyWorkflowProvider);

  return AIOrchestrator(
    intentRouter: intentRouter,
    workflows: [
      bookkeepingWorkflow,
      receiptReclassifyWorkflow,
    ],
  );
});
