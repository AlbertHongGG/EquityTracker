import 'dart:io';
import 'package:intl/intl.dart';
import 'package:equity_tracker/core/logging/domain/api_log_category.dart';
import 'package:equity_tracker/core/logging/domain/api_log_entry.dart';

/// 敏感資訊遮罩工具 (Token & Key Sanitizer)
class LogSanitizer {
  static const List<String> _sensitiveHeaderKeys = [
    'authorization',
    'notion-version',
    'x-api-key',
    'api-key',
  ];

  static const List<String> _sensitiveParamKeys = [
    'key',
    'token',
    'api_key',
    'apikey',
    'secret',
  ];

  /// 遮罩敏感字串，保留前 4 碼與後 3 碼，其餘轉為 `***`
  static String maskSecret(String secret) {
    if (secret.length <= 8) return '********';
    return '${secret.substring(0, 4)}...${secret.substring(secret.length - 3)}';
  }

  /// 遮罩 Header Map
  static Map<String, String>? sanitizeHeaders(Map<String, String>? headers) {
    if (headers == null || headers.isEmpty) return null;
    final Map<String, String> sanitized = {};
    headers.forEach((key, value) {
      final lowerKey = key.toLowerCase();
      if (_sensitiveHeaderKeys.any((s) => lowerKey.contains(s))) {
        if (value.startsWith('Bearer ')) {
          sanitized[key] = 'Bearer ${maskSecret(value.substring(7).trim())}';
        } else {
          sanitized[key] = maskSecret(value);
        }
      } else {
        sanitized[key] = value;
      }
    });
    return sanitized.isEmpty ? null : sanitized;
  }

  /// 遮罩 URL 中包含的 API Key 或 Token
  static String sanitizeUrl(String rawUrl) {
    try {
      final uri = Uri.parse(rawUrl);
      if (!uri.hasQuery) return rawUrl;

      final queryMap = Map<String, dynamic>.from(uri.queryParameters);
      bool modified = false;

      queryMap.forEach((key, value) {
        final lower = key.toLowerCase();
        if (_sensitiveParamKeys.any((s) => lower == s || lower.contains(s))) {
          queryMap[key] = maskSecret(value.toString());
          modified = true;
        }
      });

      if (!modified) return rawUrl;
      return uri.replace(queryParameters: queryMap.map((k, v) => MapEntry(k, v.toString()))).toString();
    } catch (_) {
      return rawUrl;
    }
  }

  /// 移除 Map 中的空值、空字串、空 Map 與空 List (Zero-Phantom-Field 原則)
  static Map<String, dynamic> cleanPhantomFields(Map<String, dynamic> raw) {
    final Map<String, dynamic> result = {};
    raw.forEach((key, value) {
      if (value == null) return;
      if (value is String && value.trim().isEmpty) return;
      if (value is Map) {
        final cleaned = cleanPhantomFields(Map<String, dynamic>.from(value));
        if (cleaned.isNotEmpty) result[key] = cleaned;
      } else if (value is List) {
        if (value.isNotEmpty) result[key] = value;
      } else {
        result[key] = value;
      }
    });
    return result;
  }
}

/// API 請求模型 (ApiLogRequest)
class ApiLogRequest {
  final String? url;
  final String? method;
  final Map<String, String>? headers;
  final Map<String, dynamic>? queryParameters;
  final String? systemPrompt;
  final String? prompt;
  final dynamic body;

  const ApiLogRequest({
    this.url,
    this.method,
    this.headers,
    this.queryParameters,
    this.systemPrompt,
    this.prompt,
    this.body,
  });

  Map<String, dynamic> toMap() {
    final raw = {
      'url': url != null ? LogSanitizer.sanitizeUrl(url!) : null,
      'method': method?.toUpperCase(),
      'headers': LogSanitizer.sanitizeHeaders(headers),
      'queryParameters': queryParameters,
      'systemPrompt': systemPrompt,
      'prompt': prompt,
      'body': body,
    };
    return LogSanitizer.cleanPhantomFields(raw);
  }
}

/// API 回應模型 (ApiLogResponse)
class ApiLogResponse {
  final int? statusCode;
  final Map<String, String>? headers;
  final dynamic body;
  final String? error;

  const ApiLogResponse({
    this.statusCode,
    this.headers,
    this.body,
    this.error,
  });

  Map<String, dynamic> toMap() {
    final raw = {
      'statusCode': statusCode,
      'headers': LogSanitizer.sanitizeHeaders(headers),
      'body': body,
      'error': error,
    };
    return LogSanitizer.cleanPhantomFields(raw);
  }
}

/// 完整 API 與 AI 互動紀錄模型 (ApiLogRecord)
class ApiLogRecord {
  final String timestamp;
  final ApiLogCategory category;
  final String sourceName;
  final int durationMs;
  final bool isError;
  final ApiLogRequest request;
  final ApiLogResponse response;

  const ApiLogRecord({
    required this.timestamp,
    required this.category,
    required this.sourceName,
    required this.durationMs,
    required this.isError,
    required this.request,
    required this.response,
  });

  Map<String, dynamic> toJson() {
    final raw = {
      'timestamp': timestamp,
      'category': category.key,
      'sourceName': sourceName,
      'durationMs': durationMs,
      'isError': isError,
      'request': request.toMap(),
      'response': response.toMap(),
    };
    return LogSanitizer.cleanPhantomFields(raw);
  }

  /// 將記憶體中的強型別 Record 直接轉換為 UI Entry，零反序列化損耗
  ApiLogEntry toEntry(File file) {
    final fileName = file.path.split(Platform.pathSeparator).last;
    final id = fileName.replaceAll('.json', '');
    final dt = DateTime.tryParse(timestamp) ?? DateTime.now();
    final displayTime = DateFormat('yyyy/MM/dd HH:mm:ss').format(dt);

    return ApiLogEntry(
      id: id,
      file: file,
      timestamp: dt,
      category: category,
      sourceName: sourceName,
      durationMs: durationMs,
      isError: isError,
      displayTime: displayTime,
    );
  }
}
