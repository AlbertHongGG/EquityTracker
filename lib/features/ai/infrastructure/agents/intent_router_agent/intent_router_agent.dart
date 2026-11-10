import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/core/logging/data/api_log_manager.dart';
import 'package:equity_tracker/core/logging/domain/api_log_category.dart';
import 'package:equity_tracker/core/logging/domain/i_api_logger.dart';
import 'package:equity_tracker/features/ai/domain/enums/ai_intent.dart';
import 'package:equity_tracker/features/ai/infrastructure/agents/base_agent.dart';
import 'package:equity_tracker/features/ai/infrastructure/providers/ai_provider.dart';
import 'package:equity_tracker/features/ai/infrastructure/providers/provider_factory.dart';
import 'package:equity_tracker/features/ai/infrastructure/agents/intent_router_agent/prompts.dart';

class IntentRouterResult {
  final AIIntent intent;
  final String explanation;

  const IntentRouterResult({
    required this.intent,
    required this.explanation,
  });

  factory IntentRouterResult.fromMap(Map<String, dynamic> map) {
    return IntentRouterResult(
      intent: AIIntent.fromString(map['intent'] as String?),
      explanation: (map['explanation'] as String?) ?? '',
    );
  }
}

class IntentRouterAgent extends BaseAgent<String, IntentRouterResult> {
  IntentRouterAgent(AIProvider provider, [IApiLogger? logManager])
      : super(
          'IntentRouter',
          provider,
          category: ApiLogCategory.aiIntentRouter,
          logManager: logManager,
        );

  @override
  Future<IntentRouterResult> execute(String input, {void Function(String)? onChunk}) async {
    final systemPrompt = buildIntentRouterSystemPrompt();
    final userPrompt = buildIntentRouterUserPrompt(input);

    String resultText = '';
    final stream = executeStreamPrompt(userPrompt, systemPrompt);

    await for (final chunk in stream) {
      resultText += chunk;
      if (onChunk != null) onChunk(chunk);
    }

    try {
      final map = extractJson<Map<String, dynamic>>(resultText, 'object');
      return IntentRouterResult.fromMap(map);
    } catch (_) {
      // 容錯機制：若解析失敗，預設轉交通用或記帳
      return const IntentRouterResult(
        intent: AIIntent.unsupported,
        explanation: '無法確定意圖',
      );
    }
  }
}

final intentRouterAgentProvider = Provider.autoDispose<IntentRouterAgent>((ref) {
  return IntentRouterAgent(
    ref.watch(aiProviderProvider),
    ref.watch(apiLogManagerProvider.notifier),
  );
});
