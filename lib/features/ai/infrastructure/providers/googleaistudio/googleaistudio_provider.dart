import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:equity_tracker/features/ai/domain/models/ai_provider_config.dart';
import 'package:equity_tracker/features/ai/infrastructure/providers/ai_provider.dart';
import 'package:equity_tracker/features/ai/domain/exceptions/ai_connection_error.dart';

/// 原生 Google AI Studio (Gemini API) 供應商實作
/// 1:1 復刻 LensWise GoogleAiStudioProvider.kt 規格：
/// - 透過 Google Generative Language API 端點與 API Key 直接通訊
/// - 支援系統指令 (systemInstruction) 與思考等級 (thinkingConfig.thinkingLevel)
/// - 支援單次 generate 與 streamGenerateContent (SSE) 漸進輸出
/// - 支援 Google REST 結構化錯誤解析與安全調用
class GoogleAiStudioProvider implements AIProvider {
  @override
  final String name = 'google_ai_studio';

  final String _apiKey;
  final String _modelName;
  final GeminiThinkingLevel _thinkingLevel;

  GoogleAiStudioProvider({
    required String apiKey,
    required String modelName,
    GeminiThinkingLevel thinkingLevel = GeminiThinkingLevel.low,
  })  : _apiKey = apiKey,
        _modelName = modelName,
        _thinkingLevel = thinkingLevel;

  Map<String, dynamic> _buildPayload(GenerateRequest request) {
    final contents = [
      {
        'role': 'user',
        'parts': [
          {'text': request.prompt}
        ]
      }
    ];

    final Map<String, dynamic> body = {
      'contents': contents,
    };

    if (request.systemPrompt != null && request.systemPrompt!.isNotEmpty) {
      body['systemInstruction'] = {
        'parts': [
          {'text': request.systemPrompt}
        ]
      };
    }

    if (_thinkingLevel.value.isNotEmpty) {
      body['generationConfig'] = {
        'thinkingConfig': {
          'thinkingLevel': _thinkingLevel.value,
        }
      };
    }

    return body;
  }

  String _extractText(Map<String, dynamic> json) {
    final candidates = json['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) return '';

    final candidate = candidates[0] as Map<String, dynamic>?;
    final content = candidate?['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List<dynamic>?;
    if (parts == null || parts.isEmpty) return '';

    final buffer = StringBuffer();
    for (final part in parts) {
      if (part is Map<String, dynamic>) {
        if (part['thought'] == true) {
          // 忽略思維鏈內部過程，僅保留最終文本
          continue;
        }
        final text = part['text'] as String?;
        if (text != null) {
          buffer.write(text);
        }
      }
    }
    return buffer.toString();
  }

  String _parseErrorMessage(String rawError, int statusCode) {
    try {
      final json = jsonDecode(rawError) as Map<String, dynamic>;
      final error = json['error'] as Map<String, dynamic>?;
      final message = error?['message'] as String?;
      return message ?? rawError;
    } catch (_) {
      return rawError.isNotEmpty ? rawError : 'HTTP $statusCode';
    }
  }

  @override
  Future<GenerateResponse> generate(GenerateRequest request) async {
    if (_apiKey.trim().isEmpty) {
      throw AIConnectionError(name, 'Google AI Studio API Key 未設定，請至 AI 引擎設定中填寫。');
    }

    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$_modelName:generateContent',
      );
      final body = _buildPayload(request);

      final response = await http.post(
        url,
        headers: {
          'x-goog-api-key': _apiKey.trim(),
          'Content-Type': 'application/json; charset=utf-8',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        final errorMsg = _parseErrorMessage(utf8.decode(response.bodyBytes), response.statusCode);
        throw Exception('Google AI Studio error (${response.statusCode}): $errorMsg');
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final text = _extractText(data);

      return GenerateResponse(text: text);
    } catch (e) {
      if (e is AIConnectionError) rethrow;
      throw AIConnectionError(name, e.toString());
    }
  }

  @override
  Stream<GenerateResponse> generateStream(GenerateRequest request) async* {
    if (_apiKey.trim().isEmpty) {
      throw AIConnectionError(name, 'Google AI Studio API Key 未設定，請至 AI 引擎設定中填寫。');
    }

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_modelName:streamGenerateContent?alt=sse',
    );
    final client = http.Client();

    try {
      final httpRequest = http.Request('POST', url);
      httpRequest.headers['x-goog-api-key'] = _apiKey.trim();
      httpRequest.headers['Content-Type'] = 'application/json; charset=utf-8';
      httpRequest.headers['Accept'] = 'text/event-stream';
      httpRequest.body = jsonEncode(_buildPayload(request));

      final response = await client.send(httpRequest);

      if (response.statusCode != 200) {
        final errorBytes = await response.stream.toBytes();
        final errorMsg = _parseErrorMessage(utf8.decode(errorBytes), response.statusCode);
        throw Exception('Google AI Studio stream error (${response.statusCode}): $errorMsg');
      }

      final stream = response.stream.transform(utf8.decoder).transform(const LineSplitter());

      await for (final line in stream) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;

        if (trimmed.startsWith('data: ')) {
          final jsonString = trimmed.substring(6).trim();
          if (jsonString.isEmpty || jsonString == '[DONE]') continue;

          try {
            final json = jsonDecode(jsonString) as Map<String, dynamic>;
            final text = _extractText(json);
            if (text.isNotEmpty) {
              yield GenerateResponse(text: text);
            }
          } catch (_) {
            // 忽略個別 JSON chunk 解析跳過
          }
        }
      }
    } catch (e) {
      if (e is AIConnectionError) rethrow;
      throw AIConnectionError(name, e.toString());
    } finally {
      client.close();
    }
  }
}
