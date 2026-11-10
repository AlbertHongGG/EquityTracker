import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/core/logging/data/api_log_manager.dart';
import 'package:equity_tracker/core/logging/domain/api_log_category.dart';
import 'package:equity_tracker/core/logging/domain/i_api_logger.dart';
import 'package:equity_tracker/features/ai/domain/entities/ai_category_ref.dart';
import 'package:equity_tracker/features/ai/domain/entities/ai_transaction_summary.dart';
import 'package:equity_tracker/features/ai/infrastructure/agents/base_agent.dart';
import 'package:equity_tracker/features/ai/infrastructure/providers/ai_provider.dart';
import 'package:equity_tracker/features/ai/infrastructure/providers/provider_factory.dart';
import 'package:equity_tracker/features/ai/infrastructure/agents/batch_categorization_agent/prompts.dart';

class BatchCategorizationInput {
  final List<AITransactionSummary> items;
  final List<AICategoryRef> categories;
  final String fallbackCategoryId;

  BatchCategorizationInput({
    required this.items,
    required this.categories,
    required this.fallbackCategoryId,
  });
}

class CategorizedProposal {
  final int transactionId;
  final String categoryId;
  final String reason;

  const CategorizedProposal({
    required this.transactionId,
    required this.categoryId,
    required this.reason,
  });

  factory CategorizedProposal.fromMap(Map<String, dynamic> map) {
    return CategorizedProposal(
      transactionId: (map['id'] as num).toInt(),
      categoryId: (map['categoryId'] as String).trim(),
      reason: (map['reason'] as String?) ?? '',
    );
  }
}

class BatchCategorizationAgent
    extends BaseAgent<BatchCategorizationInput, List<CategorizedProposal>> {
  BatchCategorizationAgent(AIProvider provider, [IApiLogger? logManager])
      : super(
          'BatchCategorization',
          provider,
          category: ApiLogCategory.aiCategoryCorrection,
          logManager: logManager,
        );

  @override
  Future<List<CategorizedProposal>> execute(
    BatchCategorizationInput input, {
    void Function(String)? onChunk,
  }) async {
    if (input.items.isEmpty) return [];

    final systemPrompt = buildBatchCategorizationSystemPrompt(
      input.categories,
      input.fallbackCategoryId,
    );
    final userPrompt = buildBatchCategorizationUserPrompt(input.items);

    String resultText = '';
    final stream = executeStreamPrompt(userPrompt, systemPrompt);

    await for (final chunk in stream) {
      resultText += chunk;
      if (onChunk != null) onChunk(chunk);
    }

    final List<dynamic> jsonList = extractJson<List<dynamic>>(resultText, 'array');
    return jsonList
        .map((map) => CategorizedProposal.fromMap(map as Map<String, dynamic>))
        .toList();
  }
}

final batchCategorizationAgentProvider =
    Provider.autoDispose<BatchCategorizationAgent>((ref) {
  return BatchCategorizationAgent(
    ref.watch(aiProviderProvider),
    ref.watch(apiLogManagerProvider.notifier),
  );
});
