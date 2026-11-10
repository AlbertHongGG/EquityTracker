import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/ai/domain/models/chat_message.dart';
import 'package:equity_tracker/features/ai/domain/models/workflow_step_result.dart';
import 'package:equity_tracker/features/ai/application/orchestrator/ai_orchestrator.dart';

export 'package:equity_tracker/features/ai/domain/models/chat_message.dart';

class AISessionState {
  final bool isProcessing;
  final WorkflowSuspendedState? suspendedState;
  final List<ChatMessage> messages;
  final List<String> thinkingSteps;

  AISessionState({
    this.isProcessing = false,
    this.suspendedState,
    this.messages = const [],
    this.thinkingSteps = const [],
  });

  AISessionState copyWith({
    bool? isProcessing,
    WorkflowSuspendedState? suspendedState,
    bool clearSuspendedState = false,
    List<ChatMessage>? messages,
    List<String>? thinkingSteps,
  }) {
    return AISessionState(
      isProcessing: isProcessing ?? this.isProcessing,
      suspendedState: clearSuspendedState ? null : (suspendedState ?? this.suspendedState),
      messages: messages ?? this.messages,
      thinkingSteps: thinkingSteps ?? this.thinkingSteps,
    );
  }
}

class AISessionController extends Notifier<AISessionState> {
  @override
  AISessionState build() {
    return AISessionState();
  }

  void _addMessage(String text, ChatMessageType type, {ChatAttachmentPayload? payload}) {
    final msg = ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: text,
      type: type,
      payload: payload,
    );
    state = state.copyWith(messages: [...state.messages, msg]);
  }

  void _addProgress(String msg) {
    state = state.copyWith(thinkingSteps: [...state.thinkingSteps, msg]);
  }

  Future<void> sendMessage(String input) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return;

    _addMessage(trimmed, ChatMessageType.user);

    final currentSuspended = state.suspendedState;
    state = state.copyWith(
      isProcessing: true,
      thinkingSteps: [],
      clearSuspendedState: true,
    );

    try {
      final orchestrator = ref.read(aiOrchestratorProvider);
      final result = await orchestrator.handleInput(
        trimmed,
        suspendedState: currentSuspended,
        onProgress: _addProgress,
      );

      _handleResult(result);
    } catch (e) {
      _addMessage('處理時發生異常: $e', ChatMessageType.error);
      state = state.copyWith(isProcessing: false, clearSuspendedState: true);
    }
  }

  void _handleResult(WorkflowStepResult result) {
    switch (result) {
      case WorkflowRequiresInput(:final suspendedState):
        state = state.copyWith(
          isProcessing: false,
          suspendedState: suspendedState,
        );
      case WorkflowCompleted(:final message, :final payload):
        _addMessage(message, ChatMessageType.ai, payload: payload);
        state = state.copyWith(
          isProcessing: false,
          clearSuspendedState: true,
        );
      case WorkflowFailed(:final errorMessage):
        _addMessage(errorMessage, ChatMessageType.error);
        state = state.copyWith(
          isProcessing: false,
          clearSuspendedState: true,
        );
    }
  }
}

final aiSessionControllerProvider =
    NotifierProvider<AISessionController, AISessionState>(
  AISessionController.new,
);
