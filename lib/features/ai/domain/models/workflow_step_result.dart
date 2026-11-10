import 'package:equity_tracker/features/ai/domain/enums/ai_intent.dart';
import 'package:equity_tracker/features/ai/domain/models/chat_message.dart';

/// 工作流掛起時的使用者互動需求規格抽象基底
abstract class WorkflowSuspendedState {
  final AIIntent intent;
  const WorkflowSuspendedState({required this.intent});
}

/// 工作流單步執行的結果 (Sealed class)
sealed class WorkflowStepResult {
  const WorkflowStepResult();
}

/// 狀態 1：需要使用者進一步輸入/選擇（中斷並掛起狀態）
final class WorkflowRequiresInput extends WorkflowStepResult {
  final WorkflowSuspendedState suspendedState;
  const WorkflowRequiresInput(this.suspendedState);
}

/// 狀態 2：工作流執行完成（附帶回覆文字與可選的結構化展示卡片 Payload）
final class WorkflowCompleted extends WorkflowStepResult {
  final String message;
  final ChatAttachmentPayload? payload;

  const WorkflowCompleted({
    required this.message,
    this.payload,
  });
}

/// 狀態 3：工作流執行失敗
final class WorkflowFailed extends WorkflowStepResult {
  final String errorMessage;
  const WorkflowFailed(this.errorMessage);
}
