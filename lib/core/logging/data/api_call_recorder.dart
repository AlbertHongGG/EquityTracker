import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:equity_tracker/core/logging/domain/api_log_category.dart';
import 'package:equity_tracker/core/logging/domain/api_log_record.dart';
import 'package:equity_tracker/core/logging/domain/i_api_logger.dart';

/// 通用 API 呼叫計時與結構化紀錄器 (ApiCallRecorder)
///
/// 消除所有外部 API 通訊盲區，自動處理：
/// 1. 執行時間精確測量 (Stopwatch -> durationMs)
/// 2. 敏感資訊與 Token 遮罩 (LogSanitizer)
/// 3. HTTP 狀態碼與例外錯誤結構化封裝
/// 4. 委派至 ApiLogManager 進行零幽靈欄位持久化
class ApiCallRecorder {
  final IApiLogger _manager;

  ApiCallRecorder(this._manager);

  /// 記錄一次非同步操作 (通用型)
  Future<T> recordOperation<T>({
    required ApiLogCategory category,
    required String sourceName,
    required ApiLogRequest request,
    required Future<T> Function() action,
    required ApiLogResponse Function(T result, int durationMs) onResponse,
  }) async {
    final sw = Stopwatch()..start();
    final startTime = DateTime.now().toIso8601String();

    try {
      final result = await action();
      sw.stop();

      final durationMs = sw.elapsedMilliseconds;
      final response = onResponse(result, durationMs);

      await _manager.logInteraction(
        ApiLogRecord(
          timestamp: startTime,
          category: category,
          sourceName: sourceName,
          durationMs: durationMs,
          isError: response.error != null,
          request: request,
          response: response,
        ),
      );

      return result;
    } catch (e, st) {
      sw.stop();
      final durationMs = sw.elapsedMilliseconds;

      await _manager.logInteraction(
        ApiLogRecord(
          timestamp: startTime,
          category: category,
          sourceName: sourceName,
          durationMs: durationMs,
          isError: true,
          request: request,
          response: ApiLogResponse(
            error: '$e\n$st',
          ),
        ),
      );

      rethrow;
    }
  }

  /// 記錄一次 HTTP 呼叫
  Future<http.Response> recordHttpCall({
    required ApiLogCategory category,
    required String sourceName,
    required String method,
    required Uri url,
    Map<String, String>? headers,
    dynamic body,
    required Future<http.Response> Function() action,
  }) async {
    final sw = Stopwatch()..start();
    final startTime = DateTime.now().toIso8601String();

    final request = ApiLogRequest(
      url: url.toString(),
      method: method,
      headers: headers,
      body: body,
    );

    try {
      final response = await action();
      sw.stop();

      final durationMs = sw.elapsedMilliseconds;
      dynamic parsedBody = response.body;
      try {
        parsedBody = jsonDecode(response.body);
      } catch (_) {}

      final isError = response.statusCode < 200 || response.statusCode >= 300;

      await _manager.logInteraction(
        ApiLogRecord(
          timestamp: startTime,
          category: category,
          sourceName: sourceName,
          durationMs: durationMs,
          isError: isError,
          request: request,
          response: ApiLogResponse(
            statusCode: response.statusCode,
            headers: response.headers,
            body: parsedBody,
            error: isError ? 'HTTP ${response.statusCode}: ${response.reasonPhrase ?? ''}' : null,
          ),
        ),
      );

      return response;
    } catch (e, st) {
      sw.stop();
      final durationMs = sw.elapsedMilliseconds;

      await _manager.logInteraction(
        ApiLogRecord(
          timestamp: startTime,
          category: category,
          sourceName: sourceName,
          durationMs: durationMs,
          isError: true,
          request: request,
          response: ApiLogResponse(
            error: '$e\n$st',
          ),
        ),
      );

      rethrow;
    }
  }
}
