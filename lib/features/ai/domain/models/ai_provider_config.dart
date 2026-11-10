
enum AIProviderType {
  geminiflow,
  ollama,
  vertexai,
  googleaistudio,
}

abstract class ProviderConfig {
  final String modelName;
  
  const ProviderConfig({required this.modelName});
  
  Map<String, dynamic> toJson();
}

class GeminiFlowConfig extends ProviderConfig {
  final String baseUrl;

  const GeminiFlowConfig({
    super.modelName = 'gemini-3.6-flash',
    this.baseUrl = 'http://127.0.0.1:8000',
  });

  @override
  Map<String, dynamic> toJson() => {
        'modelName': modelName,
        'baseUrl': baseUrl,
      };

  factory GeminiFlowConfig.fromJson(Map<String, dynamic> json) {
    return GeminiFlowConfig(
      modelName: json['modelName'] ?? 'gemini-3.6-flash',
      baseUrl: json['baseUrl'] ?? 'http://127.0.0.1:8000',
    );
  }
  
  GeminiFlowConfig copyWith({String? modelName, String? baseUrl}) {
    return GeminiFlowConfig(
      modelName: modelName ?? this.modelName,
      baseUrl: baseUrl ?? this.baseUrl,
    );
  }
}

class OllamaConfig extends ProviderConfig {
  final String baseUrl;

  const OllamaConfig({
    super.modelName = 'llama3',
    this.baseUrl = 'http://localhost:11434',
  });

  @override
  Map<String, dynamic> toJson() => {
        'modelName': modelName,
        'baseUrl': baseUrl,
      };

  factory OllamaConfig.fromJson(Map<String, dynamic> json) {
    return OllamaConfig(
      modelName: json['modelName'] ?? 'llama3',
      baseUrl: json['baseUrl'] ?? 'http://localhost:11434',
    );
  }
  
  OllamaConfig copyWith({String? modelName, String? baseUrl}) {
    return OllamaConfig(
      modelName: modelName ?? this.modelName,
      baseUrl: baseUrl ?? this.baseUrl,
    );
  }
}

class VertexAIConfig extends ProviderConfig {
  final String projectId;
  final String region;
  final String accessToken;

  const VertexAIConfig({
    super.modelName = 'gemini-1.5-pro-preview-0409',
    this.projectId = '',
    this.region = 'us-central1',
    this.accessToken = '',
  });

  @override
  Map<String, dynamic> toJson() => {
        'modelName': modelName,
        'projectId': projectId,
        'region': region,
        'accessToken': accessToken,
      };

  factory VertexAIConfig.fromJson(Map<String, dynamic> json) {
    return VertexAIConfig(
      modelName: json['modelName'] ?? 'gemini-1.5-pro-preview-0409',
      projectId: json['projectId'] ?? '',
      region: json['region'] ?? 'us-central1',
      accessToken: json['accessToken'] ?? '',
    );
  }
  
  VertexAIConfig copyWith({
    String? modelName,
    String? projectId,
    String? region,
    String? accessToken,
  }) {
    return VertexAIConfig(
      modelName: modelName ?? this.modelName,
      projectId: projectId ?? this.projectId,
      region: region ?? this.region,
      accessToken: accessToken ?? this.accessToken,
    );
  }
}

class GoogleAiStudioModelItem {
  final String id;
  final String displayName;
  final String description;

  const GoogleAiStudioModelItem({
    required this.id,
    required this.displayName,
    required this.description,
  });
}

class GoogleAiStudioModel {
  static const String flash38 = 'gemini-3.8-flash';
  static const String flash36 = 'gemini-3.6-flash';
  static const String flashLite35 = 'gemini-3.5-flash-lite';

  static const List<GoogleAiStudioModelItem> items = [
    GoogleAiStudioModelItem(
      id: flash38,
      displayName: 'Gemini 3.8 Flash',
      description: '最新旗艦極速',
    ),
    GoogleAiStudioModelItem(
      id: flash36,
      displayName: 'Gemini 3.6 Flash',
      description: '平衡推理',
    ),
    GoogleAiStudioModelItem(
      id: flashLite35,
      displayName: 'Gemini 3.5 Flash Lite',
      description: '超輕量低延遲',
    ),
  ];

  static String getDisplayName(String id) {
    final match = items.where((item) => item.id.toLowerCase() == id.trim().toLowerCase());
    return match.isNotEmpty ? match.first.displayName : id;
  }
}

enum GeminiThinkingLevel {
  low('low', '低', '極速回應'),
  medium('medium', '中', '平衡推理'),
  high('high', '高', '極致思維鏈');

  final String value;
  final String label;
  final String description;

  const GeminiThinkingLevel(this.value, this.label, this.description);

  static GeminiThinkingLevel fromValue(String? raw) {
    if (raw == null) return GeminiThinkingLevel.low;
    final lower = raw.trim().toLowerCase();
    return GeminiThinkingLevel.values.firstWhere(
      (e) => e.value == lower || e.name.toLowerCase() == lower || e.label == raw.trim(),
      orElse: () => GeminiThinkingLevel.low,
    );
  }
}

/// Google AI Studio 供應商專屬配置 (1:1 對齊 LensWise)
class GoogleAiStudioConfig extends ProviderConfig {
  final String apiKey;
  final String thinkingLevel;

  const GoogleAiStudioConfig({
    super.modelName = GoogleAiStudioModel.flash38,
    this.apiKey = '',
    this.thinkingLevel = 'low',
  });

  @override
  Map<String, dynamic> toJson() => {
        'modelName': modelName,
        'apiKey': apiKey,
        'thinkingLevel': thinkingLevel,
      };

  factory GoogleAiStudioConfig.fromJson(Map<String, dynamic> json) {
    return GoogleAiStudioConfig(
      modelName: json['modelName'] ?? GoogleAiStudioModel.flash38,
      apiKey: json['apiKey'] ?? '',
      thinkingLevel: json['thinkingLevel'] ?? 'low',
    );
  }

  GoogleAiStudioConfig copyWith({
    String? modelName,
    String? apiKey,
    String? thinkingLevel,
  }) {
    return GoogleAiStudioConfig(
      modelName: modelName ?? this.modelName,
      apiKey: apiKey ?? this.apiKey,
      thinkingLevel: thinkingLevel ?? this.thinkingLevel,
    );
  }
}
