import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/core/logging/domain/api_log_category.dart';
import 'package:equity_tracker/core/logging/data/api_log_manager.dart';
import 'package:equity_tracker/core/logging/domain/i_api_logger.dart';
import 'package:equity_tracker/features/ai/domain/entities/ai_category_ref.dart';
import 'package:equity_tracker/features/ai/domain/entities/ai_transaction_draft.dart';
import 'package:equity_tracker/features/ai/infrastructure/agents/base_agent.dart';
import 'package:equity_tracker/features/ai/infrastructure/providers/provider_factory.dart';
import 'package:equity_tracker/features/ai/infrastructure/providers/ai_provider.dart';
import 'package:equity_tracker/features/ai/infrastructure/agents/correction_agent/prompts.dart';

class CorrectionInput {
  final AITransactionDraft record;
  final String answer;
  final String? question;
  final List<AICategoryRef> categories;

  CorrectionInput({
    required this.record,
    required this.answer,
    this.question,
    this.categories = const [],
  });
}

class CorrectionResult {
  final AITransactionDraft record;

  CorrectionResult({required this.record});
}

class CorrectionAgent extends BaseAgent<CorrectionInput, CorrectionResult> {
  CorrectionAgent(AIProvider provider, [IApiLogger? logManager])
      : super(
          'Correction',
          provider,
          category: ApiLogCategory.aiValidation,
          logManager: logManager,
        );

  @override
  Future<CorrectionResult> execute(CorrectionInput input, {void Function(String)? onChunk}) async {
    final otherCategory = input.categories.firstWhere(
      (c) => c.name == '其他',
      orElse: () => input.categories.isNotEmpty
          ? input.categories.first
          : const AICategoryRef(id: 'unknown', name: 'Unknown'),
    );
    final fallbackCategoryId = otherCategory.id;
    final today = DateTime.now().toIso8601String().split('T').first;

    final systemPrompt = buildSystemPrompt(input.categories, fallbackCategoryId, today);
    final userPrompt = buildUserPrompt(input);

    String resultText = '';
    final stream = executeStreamPrompt(userPrompt, systemPrompt);

    await for (final chunk in stream) {
      resultText += chunk;
      if (onChunk != null) onChunk(chunk);
    }

    final map = extractJson<Map<String, dynamic>>(resultText, 'object');
    return CorrectionResult(record: AITransactionDraft.fromMap(map));
  }
}

final correctionAgentProvider = Provider.autoDispose<CorrectionAgent>((ref) {
  return CorrectionAgent(
    ref.watch(aiProviderProvider),
    ref.watch(apiLogManagerProvider.notifier),
  );
});
