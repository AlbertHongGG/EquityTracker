import 'package:equity_tracker/core/logging/domain/api_log_category.dart';
import 'package:equity_tracker/core/logging/data/api_log_manager.dart';
import 'package:equity_tracker/core/logging/domain/i_api_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/ai/infrastructure/agents/base_agent.dart';
import 'package:equity_tracker/features/ai/infrastructure/providers/provider_factory.dart';
import 'package:equity_tracker/features/ai/infrastructure/providers/ai_provider.dart';
import 'package:equity_tracker/features/ai/infrastructure/map/i_map_search_service.dart';
import 'package:equity_tracker/features/ai/infrastructure/agents/store_lookup_agent/prompts.dart';

class StoreLookupInput {
  final String originalText;
  final String? hint;
  final String? location;
  final String? item;
  final List<StoreSearchResult> searchResults;

  StoreLookupInput({
    required this.originalText,
    this.hint,
    this.location,
    this.item,
    required this.searchResults,
  });
}

class StoreLookupResult {
  final bool isCertain;
  final String? storeName;
  final List<String>? options;

  StoreLookupResult({
    required this.isCertain,
    this.storeName,
    this.options,
  });

  factory StoreLookupResult.fromMap(Map<String, dynamic> map) {
    return StoreLookupResult(
      isCertain: map['isCertain'] as bool? ?? false,
      storeName: map['storeName'] as String?,
      options: (map['options'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
    );
  }
}


class StoreLookupAgent extends BaseAgent<StoreLookupInput, StoreLookupResult> {
  StoreLookupAgent(AIProvider provider, [IApiLogger? logManager])
      : super(
          'StoreLookup',
          provider,
          category: ApiLogCategory.aiStoreLookup,
          logManager: logManager,
        );

  @override
  Future<StoreLookupResult> execute(StoreLookupInput input, {void Function(String)? onChunk}) async {
    final systemPrompt = buildSystemPrompt();
    final userPrompt = buildUserPrompt(input);

    String resultText = '';
    final stream = executeStreamPrompt(userPrompt, systemPrompt);
    
    await for (final chunk in stream) {
      resultText += chunk;
      if (onChunk != null) onChunk(chunk);
    }
    
    final map = extractJson<Map<String, dynamic>>(resultText, 'object');
    return StoreLookupResult.fromMap(map);
  }
}

final storeLookupAgentProvider = Provider.autoDispose<StoreLookupAgent>((ref) {
  return StoreLookupAgent(
    ref.watch(aiProviderProvider),
    ref.watch(apiLogManagerProvider.notifier),
  );
});
