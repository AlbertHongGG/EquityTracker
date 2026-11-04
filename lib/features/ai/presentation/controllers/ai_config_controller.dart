import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:equity_tracker/features/ai/domain/models/ai_provider_config.dart';

import 'package:equity_tracker/core/providers/shared_prefs_provider.dart';

class AIConfigState {
  final AIProviderType providerType;
  final Map<AIProviderType, ProviderConfig> configs;
  final String googleMapApiKey;
  final bool isAIAgentEnabled;
  final bool isGoogleMapEnabled;

  AIConfigState({
    this.providerType = AIProviderType.geminiflow,
    Map<AIProviderType, ProviderConfig>? configs,
    this.googleMapApiKey = '',
    this.isAIAgentEnabled = false,
    this.isGoogleMapEnabled = false,
  }) : configs = configs ?? {
         AIProviderType.geminiflow: const GeminiFlowConfig(),
         AIProviderType.ollama: const OllamaConfig(),
         AIProviderType.vertexai: const VertexAIConfig(),
         AIProviderType.googleaistudio: const GoogleAiStudioConfig(),
       };

  ProviderConfig get activeConfig => configs[providerType]!;

  AIConfigState copyWith({
    AIProviderType? providerType,
    Map<AIProviderType, ProviderConfig>? configs,
    String? googleMapApiKey,
    bool? isAIAgentEnabled,
    bool? isGoogleMapEnabled,
  }) {
    return AIConfigState(
      providerType: providerType ?? this.providerType,
      configs: configs ?? this.configs,
      googleMapApiKey: googleMapApiKey ?? this.googleMapApiKey,
      isAIAgentEnabled: isAIAgentEnabled ?? this.isAIAgentEnabled,
      isGoogleMapEnabled: isGoogleMapEnabled ?? this.isGoogleMapEnabled,
    );
  }
}

class AIConfigController extends Notifier<AIConfigState> {
  @override
  AIConfigState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    
    final typeStr = prefs.getString('ai_provider_type');
    final type = typeStr != null
        ? AIProviderType.values.firstWhere(
            (e) => e.name == typeStr,
            orElse: () => AIProviderType.geminiflow,
          )
        : AIProviderType.geminiflow;
    
    final Map<AIProviderType, ProviderConfig> loadedConfigs = {
      AIProviderType.geminiflow: const GeminiFlowConfig(),
      AIProviderType.ollama: const OllamaConfig(),
      AIProviderType.vertexai: const VertexAIConfig(),
      AIProviderType.googleaistudio: const GoogleAiStudioConfig(),
    };

    final geminiflowJson = prefs.getString('ai_config_geminiflow');
    if (geminiflowJson != null) loadedConfigs[AIProviderType.geminiflow] = GeminiFlowConfig.fromJson(jsonDecode(geminiflowJson));

    final ollamaJson = prefs.getString('ai_config_ollama');
    if (ollamaJson != null) loadedConfigs[AIProviderType.ollama] = OllamaConfig.fromJson(jsonDecode(ollamaJson));

    final vertexaiJson = prefs.getString('ai_config_vertexai');
    if (vertexaiJson != null) loadedConfigs[AIProviderType.vertexai] = VertexAIConfig.fromJson(jsonDecode(vertexaiJson));

    final googleAiStudioJson = prefs.getString('ai_config_googleaistudio');
    if (googleAiStudioJson != null) loadedConfigs[AIProviderType.googleaistudio] = GoogleAiStudioConfig.fromJson(jsonDecode(googleAiStudioJson));

    final googleMapApiKey = prefs.getString('google_map_api_key') ?? '';
    final isAIAgentEnabled = prefs.getBool('is_ai_agent_enabled') ?? false;
    final isGoogleMapEnabled = prefs.getBool('is_google_map_enabled') ?? false;

    return AIConfigState(
      providerType: type,
      configs: loadedConfigs,
      googleMapApiKey: googleMapApiKey,
      isAIAgentEnabled: isAIAgentEnabled,
      isGoogleMapEnabled: isGoogleMapEnabled,
    );
  }

  Future<void> saveConfig({
    AIProviderType? providerType,
    ProviderConfig? activeProviderConfig,
    String? googleMapApiKey,
    bool? isAIAgentEnabled,
    bool? isGoogleMapEnabled,
  }) async {
    final newConfigs = Map<AIProviderType, ProviderConfig>.from(state.configs);
    
    if (activeProviderConfig != null) {
      newConfigs[providerType ?? state.providerType] = activeProviderConfig;
    }

    state = state.copyWith(
      providerType: providerType,
      configs: newConfigs,
      googleMapApiKey: googleMapApiKey,
      isAIAgentEnabled: isAIAgentEnabled,
      isGoogleMapEnabled: isGoogleMapEnabled,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ai_provider_type', state.providerType.name);
    
    await prefs.setString('ai_config_geminiflow', jsonEncode(state.configs[AIProviderType.geminiflow]!.toJson()));
    await prefs.setString('ai_config_ollama', jsonEncode(state.configs[AIProviderType.ollama]!.toJson()));
    await prefs.setString('ai_config_vertexai', jsonEncode(state.configs[AIProviderType.vertexai]!.toJson()));
    await prefs.setString('ai_config_googleaistudio', jsonEncode(state.configs[AIProviderType.googleaistudio]!.toJson()));
    
    if (googleMapApiKey != null) {
      await prefs.setString('google_map_api_key', googleMapApiKey.trim());
    }
    
    if (isAIAgentEnabled != null) {
      await prefs.setBool('is_ai_agent_enabled', isAIAgentEnabled);
    }
    
    if (isGoogleMapEnabled != null) {
      await prefs.setBool('is_google_map_enabled', isGoogleMapEnabled);
    }
  }
}

final aiConfigControllerProvider = NotifierProvider<AIConfigController, AIConfigState>(
  AIConfigController.new,
);
