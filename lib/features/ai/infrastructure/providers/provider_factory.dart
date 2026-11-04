import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/ai/infrastructure/providers/ai_provider.dart';
import 'package:equity_tracker/features/ai/infrastructure/providers/geminiflow/geminiflow_provider.dart';
import 'package:equity_tracker/features/ai/infrastructure/providers/googleaistudio/googleaistudio_provider.dart';
import 'package:equity_tracker/features/ai/infrastructure/providers/ollama/ollama_provider.dart';
import 'package:equity_tracker/features/ai/infrastructure/providers/vertexai/vertexai_provider.dart';
import 'package:equity_tracker/features/ai/presentation/controllers/ai_config_controller.dart';
import 'package:equity_tracker/features/ai/domain/models/ai_provider_config.dart';

class ProviderFactory {
  static AIProvider createProvider(AIConfigState state) {
    final type = state.providerType;
    final config = state.activeConfig;

    switch (type) {
      case AIProviderType.geminiflow:
        final geminiConfig = config as GeminiFlowConfig;
        if (geminiConfig.baseUrl.isEmpty) {
          throw Exception('Geminiflow Base URL is empty. Please set it in Settings.');
        }
        return GeminiFlowProvider(
          baseUrl: geminiConfig.baseUrl,
          modelName: geminiConfig.modelName,
        );
      case AIProviderType.ollama:
        final ollamaConfig = config as OllamaConfig;
        if (ollamaConfig.baseUrl.isEmpty) {
          throw Exception('Ollama Base URL is empty.');
        }
        return OllamaProvider(
          baseUrl: ollamaConfig.baseUrl,
          modelName: ollamaConfig.modelName,
        );
      case AIProviderType.vertexai:
        final vertexConfig = config as VertexAIConfig;
        if (vertexConfig.projectId.isEmpty || vertexConfig.accessToken.isEmpty) {
          throw Exception('Vertex AI Project ID or Access Token is missing.');
        }
        return VertexAIProvider(
          projectId: vertexConfig.projectId,
          region: vertexConfig.region,
          accessToken: vertexConfig.accessToken,
          modelName: vertexConfig.modelName,
        );
      case AIProviderType.googleaistudio:
        final studioConfig = config as GoogleAiStudioConfig;
        if (studioConfig.apiKey.isEmpty) {
          throw Exception('Google AI Studio API Key is empty. Please set it in Settings.');
        }
        return GoogleAiStudioProvider(
          apiKey: studioConfig.apiKey,
          modelName: studioConfig.modelName,
          thinkingLevel: studioConfig.thinkingLevel,
        );
    }
  }
}

final aiProviderProvider = Provider.autoDispose<AIProvider>((ref) {
  final config = ref.watch(aiConfigControllerProvider);
  return ProviderFactory.createProvider(config);
});
