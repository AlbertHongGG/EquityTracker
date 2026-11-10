import 'package:equity_tracker/features/ai/domain/enums/ai_intent.dart';
import 'package:equity_tracker/features/ai/domain/models/workflow_step_result.dart';

/// 獨立技能工作流契約 (Workflow Port)
///
/// 每個具體的 AI 功能（如記帳、發票矯正、查詢、修改等）皆實作此介面，
/// 擁有自治的業務邏輯與多輪互動生命週期。
abstract interface class IAIWorkflow {
  /// 此工作流支援的目標意圖
  AIIntent get supportedIntent;

  /// 啟動全新任務流程
  Future<WorkflowStepResult> start(
    String userInput, {
    void Function(String step)? onProgress,
  });

  /// 當任務處於 WorkflowRequiresInput 掛起狀態時，繼續處理使用者的補充回答
  Future<WorkflowStepResult> resume(
    String userReply,
    WorkflowSuspendedState suspendedState, {
    void Function(String step)? onProgress,
  });
}
