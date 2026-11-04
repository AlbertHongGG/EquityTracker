import 'package:equity_tracker/core/logging/data/api_log_manager.dart';
import 'package:equity_tracker/core/logging/domain/i_api_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/ai/domain/models/record_data.dart';
import 'package:equity_tracker/features/ai/infrastructure/agents/base_agent.dart';
import 'package:equity_tracker/features/ai/infrastructure/providers/provider_factory.dart';
import 'package:equity_tracker/features/ai/infrastructure/providers/ai_provider.dart';
import 'package:equity_tracker/features/ai/infrastructure/agents/validation_agent/prompts.dart';

class ValidationInput {
  final RecordData record;

  ValidationInput({required this.record});
}

class ValidationResult {
  final bool isValid;
  final String? question;

  ValidationResult({
    required this.isValid,
    this.question,
  });

  factory ValidationResult.fromMap(Map<String, dynamic> map) {
    return ValidationResult(
      isValid: map['isValid'] as bool? ?? false,
      question: map['question'] as String?,
    );
  }
}


class ValidationAgent extends BaseAgent<ValidationInput, ValidationResult> {
  ValidationAgent(AIProvider provider, [IApiLogger? logManager])
      : super('Validation', provider, logManager: logManager);

  @override
  Future<ValidationResult> execute(ValidationInput input, {void Function(String)? onChunk}) async {
    final systemPrompt = buildSystemPrompt();
    final userPrompt = buildUserPrompt(input);

    String resultText = '';
    final stream = executeStreamPrompt(userPrompt, systemPrompt);
    
    await for (final chunk in stream) {
      resultText += chunk;
      if (onChunk != null) onChunk(chunk);
    }
    
    final map = extractJson<Map<String, dynamic>>(resultText, 'object');
    return ValidationResult.fromMap(map);
  }
}

final validationAgentProvider = Provider.autoDispose<ValidationAgent>((ref) {
  return ValidationAgent(
    ref.watch(aiProviderProvider),
    ref.watch(apiLogManagerProvider.notifier),
  );
});
