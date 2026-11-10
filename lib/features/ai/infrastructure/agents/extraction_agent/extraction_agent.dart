import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/ai/domain/entities/ai_category_ref.dart';
import 'package:equity_tracker/features/ai/domain/entities/ai_transaction_draft.dart';
import 'package:equity_tracker/features/ai/infrastructure/agents/base_agent.dart';
import 'package:equity_tracker/features/ai/infrastructure/providers/provider_factory.dart';
import 'package:equity_tracker/features/ai/infrastructure/providers/ai_provider.dart';
import 'package:equity_tracker/features/ai/infrastructure/agents/extraction_agent/prompts.dart';
import 'package:equity_tracker/core/logging/domain/api_log_category.dart';
import 'package:equity_tracker/core/logging/data/api_log_manager.dart';
import 'package:equity_tracker/core/logging/domain/i_api_logger.dart';

class ExtractionAgent extends BaseAgent<String, List<AITransactionDraft>> {
  ExtractionAgent(AIProvider provider, [IApiLogger? logManager])
      : super(
          'Extraction',
          provider,
          category: ApiLogCategory.aiExtraction,
          logManager: logManager,
        );

  @override
  Future<List<AITransactionDraft>> execute(
    String input, {
    void Function(String)? onChunk,
    List<AICategoryRef> categories = const [],
  }) async {
    // 找出「其他」類別的 ID 作為 Fallback (若無則隨意挑一個，最糟 fallback 'unknown')
    final otherCategory = categories.firstWhere(
      (c) => c.name == '其他',
      orElse: () => categories.isNotEmpty
          ? categories.first
          : const AICategoryRef(id: 'unknown', name: 'Unknown'),
    );
    final fallbackCategoryId = otherCategory.id;
    final today = DateTime.now().toIso8601String().split('T').first;

    final systemPrompt = buildSystemPrompt(categories, fallbackCategoryId, today);
    final userPrompt = buildUserPrompt(input);

    String resultText = '';
    final stream = executeStreamPrompt(userPrompt, systemPrompt);

    await for (final chunk in stream) {
      resultText += chunk;
      if (onChunk != null) onChunk(chunk);
    }

    final List<dynamic> jsonArray = extractJson<List<dynamic>>(resultText, 'array');
    return jsonArray.map((map) => AITransactionDraft.fromMap(map as Map<String, dynamic>)).toList();
  }
}

final extractionAgentProvider = Provider<ExtractionAgent>((ref) {
  return ExtractionAgent(
    ref.watch(aiProviderProvider),
    ref.watch(apiLogManagerProvider.notifier),
  );
});
