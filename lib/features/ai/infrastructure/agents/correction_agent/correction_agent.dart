import 'package:equity_tracker/core/logging/data/api_log_manager.dart';
import 'package:equity_tracker/core/logging/domain/i_api_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/ai/domain/models/record_data.dart';
import 'package:equity_tracker/features/ai/infrastructure/agents/base_agent.dart';
import 'package:equity_tracker/features/ai/infrastructure/providers/provider_factory.dart';
import 'package:equity_tracker/features/ai/infrastructure/providers/ai_provider.dart';
import 'package:equity_tracker/features/ai/infrastructure/agents/correction_agent/prompts.dart';
import 'package:equity_tracker/features/category/data/category_model.dart';
import 'package:equity_tracker/core/enums/transaction_type.dart';

class CorrectionInput {
  final RecordData record;
  final String answer;
  final String? question;
  final List<CategoryModel> categories;

  CorrectionInput({
    required this.record,
    required this.answer,
    this.question,
    this.categories = const [],
  });
}

class CorrectionResult {
  final RecordData record;

  CorrectionResult({required this.record});
}


class CorrectionAgent extends BaseAgent<CorrectionInput, CorrectionResult> {
  CorrectionAgent(AIProvider provider, [IApiLogger? logManager])
      : super('Correction', provider, logManager: logManager);

  @override
  Future<CorrectionResult> execute(CorrectionInput input, {void Function(String)? onChunk}) async {
    // 找出「其他」類別的 ID 作為 Fallback (優先找支出類別，若無則隨意挑一個，最糟 fallback 'unknown')
    final otherCategory = input.categories.firstWhere(
      (c) => c.name == '其他',
      orElse: () => CategoryModel(
        id: 'unknown',
        name: 'Unknown',
        iconCodePoint: 0,
        colorValue: 0,
        type: TransactionType.expense,
        isSystem: false,
        isEnabled: true,
      ),
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
    return CorrectionResult(record: RecordData.fromMap(map));
  }
}

final correctionAgentProvider = Provider.autoDispose<CorrectionAgent>((ref) {
  return CorrectionAgent(
    ref.watch(aiProviderProvider),
    ref.watch(apiLogManagerProvider.notifier),
  );
});
