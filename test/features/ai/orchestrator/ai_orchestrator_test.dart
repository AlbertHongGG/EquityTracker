import 'package:flutter_test/flutter_test.dart';
import 'package:equity_tracker/features/ai/domain/enums/ai_intent.dart';
import 'package:equity_tracker/features/ai/domain/models/workflow_step_result.dart';
import 'package:equity_tracker/features/ai/domain/workflows/i_ai_workflow.dart';
import 'package:equity_tracker/features/ai/infrastructure/agents/intent_router_agent/intent_router_agent.dart';
import 'package:equity_tracker/features/ai/infrastructure/providers/ai_provider.dart';
import 'package:equity_tracker/features/ai/application/orchestrator/ai_orchestrator.dart';

class FakeAIProvider implements AIProvider {
  @override
  String get name => 'fake';

  @override
  Future<GenerateResponse> generate(GenerateRequest request) async =>
      GenerateResponse(text: '{}');

  @override
  Stream<GenerateResponse> generateStream(GenerateRequest request) async* {
    yield GenerateResponse(text: '{}');
  }
}

class FakeIntentRouterAgent extends IntentRouterAgent {
  AIIntent mockedIntent = AIIntent.addTransaction;

  FakeIntentRouterAgent() : super(FakeAIProvider());

  @override
  Future<IntentRouterResult> execute(String input, {void Function(String)? onChunk}) async {
    return IntentRouterResult(
      intent: mockedIntent,
      explanation: 'mock',
    );
  }
}

class StubWorkflow implements IAIWorkflow {
  @override
  final AIIntent supportedIntent;
  bool startCalled = false;
  bool resumeCalled = false;

  StubWorkflow(this.supportedIntent);

  @override
  Future<WorkflowStepResult> start(String userInput, {void Function(String step)? onProgress}) async {
    startCalled = true;
    return const WorkflowCompleted(message: 'start ok');
  }

  @override
  Future<WorkflowStepResult> resume(
    String userReply,
    WorkflowSuspendedState suspendedState, {
    void Function(String step)? onProgress,
  }) async {
    resumeCalled = true;
    return const WorkflowCompleted(message: 'resume ok');
  }
}

class StubSuspendedState extends WorkflowSuspendedState {
  const StubSuspendedState(AIIntent intent) : super(intent: intent);
}

void main() {
  group('AIOrchestrator Tests', () {
    late FakeIntentRouterAgent fakeRouter;
    late StubWorkflow bookkeepingWf;
    late StubWorkflow reclassifyWf;
    late AIOrchestrator orchestrator;

    setUp(() {
      fakeRouter = FakeIntentRouterAgent();
      bookkeepingWf = StubWorkflow(AIIntent.addTransaction);
      reclassifyWf = StubWorkflow(AIIntent.reclassifyReceipts);
      orchestrator = AIOrchestrator(
        intentRouter: fakeRouter,
        workflows: [bookkeepingWf, reclassifyWf],
      );
    });

    test('當有 suspendedState 時，直接委派給該 workflow 的 resume', () async {
      final result = await orchestrator.handleInput(
        '選全聯',
        suspendedState: const StubSuspendedState(AIIntent.addTransaction),
      );

      expect(bookkeepingWf.resumeCalled, isTrue);
      expect(bookkeepingWf.startCalled, isFalse);
      expect(result, isA<WorkflowCompleted>());
    });

    test('新增記帳意圖分發至 BookkeepingWorkflow', () async {
      fakeRouter.mockedIntent = AIIntent.addTransaction;

      final result = await orchestrator.handleInput('午餐吃 100 元');

      expect(bookkeepingWf.startCalled, isTrue);
      expect(reclassifyWf.startCalled, isFalse);
      expect(result, isA<WorkflowCompleted>());
    });

    test('發票矯正意圖分發至 ReceiptReclassifyWorkflow', () async {
      fakeRouter.mockedIntent = AIIntent.reclassifyReceipts;

      final result = await orchestrator.handleInput('整理發票項目');

      expect(reclassifyWf.startCalled, isTrue);
      expect(bookkeepingWf.startCalled, isFalse);
      expect(result, isA<WorkflowCompleted>());
    });

    test('未支援意圖時，回傳友善引導訊息，不觸發任何工作流', () async {
      fakeRouter.mockedIntent = AIIntent.unsupported;

      final result = await orchestrator.handleInput('明天會下雨嗎？');

      expect(bookkeepingWf.startCalled, isFalse);
      expect(reclassifyWf.startCalled, isFalse);
      expect(result, isA<WorkflowCompleted>());
      final completed = result as WorkflowCompleted;
      expect(completed.message, contains('自動智慧記帳'));
      expect(completed.message, contains('發票類別智慧矯正'));
    });
  });
}
