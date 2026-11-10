import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:equity_tracker/core/logging/domain/deletable_log.dart';
import 'package:equity_tracker/core/logging/domain/api_log_category.dart';

/// 輕量級 API 日誌列表模型 (ApiLogEntry)
///
/// 核心保證：
/// 1. 記憶體解耦 (Memory-Decoupled)：列表讀取時只保留前 2KB 提取的輕量屬性 (耗時、分類、狀態)，
///    不佔用過多記憶體。
/// 2. 延遲載入 (Lazy Payload Loading)：當使用者在 UI 點擊卡片時，呼叫 [resolvePayload]
///    才向磁碟讀取完整 JSON 內容。
/// 3. 實作 [DeletableLog]，支援拖曳至垃圾桶刪除。
class ApiLogEntry implements DeletableLog {
  @override
  final String id;

  @override
  final File file;

  @override
  final DateTime timestamp;

  final ApiLogCategory category;
  final String sourceName;
  final int durationMs;
  final bool isError;
  final String displayTime;

  ApiLogEntry({
    required this.id,
    required this.file,
    required this.timestamp,
    required this.category,
    required this.sourceName,
    required this.durationMs,
    required this.isError,
    required this.displayTime,
  });

  /// 延遲讀取完整 JSON 內容
  Future<Map<String, dynamic>> resolvePayload() async {
    try {
      if (!await file.exists()) {
        return {'error': '日誌檔案已被清理或不存在 (${file.path})'};
      }
      final content = await file.readAsString();
      final decoded = jsonDecode(content);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {'raw': decoded};
    } catch (e) {
      return {'error': '無法解析日誌檔案內容: $e'};
    }
  }

  /// 從檔名與前 2KB 標頭預覽解析 ApiLogEntry
  static ApiLogEntry fromFileWithHeader(File file, String headerPreview) {
    final fileName = file.path.split(Platform.pathSeparator).last;
    final id = fileName.replaceAll('.json', '');

    // 1. 優先由檔名解析時間戳記: yyyyMMdd_HHmmss_category_source_random.json
    DateTime parsedTime = DateTime.now();
    ApiLogCategory parsedCategory = ApiLogCategory.aiExtraction;
    String parsedSourceName = 'Interaction';
    int parsedDuration = 0;
    bool parsedError = false;

    final parts = fileName.split('_');
    if (parts.length >= 2) {
      try {
        final dateStr = parts[0];
        final timeStr = parts[1];
        if (dateStr.length == 8 && timeStr.length >= 6) {
          final year = int.parse(dateStr.substring(0, 4));
          final month = int.parse(dateStr.substring(4, 6));
          final day = int.parse(dateStr.substring(6, 8));
          final hour = int.parse(timeStr.substring(0, 2));
          final min = int.parse(timeStr.substring(2, 4));
          final sec = int.parse(timeStr.substring(4, 6));
          parsedTime = DateTime(year, month, day, hour, min, sec);
        }
      } catch (_) {}
    }

    if (parts.length >= 4) {
      // 支援包含底線之分類鍵值 (如 ai_intent_router, ai_category_correction, notion_sync)
      parsedSourceName = parts[parts.length - 2];
      final categoryKey = parts.sublist(2, parts.length - 2).join('_');
      final categoryFromPart = ApiLogCategory.fromKey(categoryKey);
      if (categoryFromPart != null) {
        parsedCategory = categoryFromPart;
      }
    } else if (parts.length >= 3) {
      final categoryFromPart = ApiLogCategory.fromKey(parts[2]);
      if (categoryFromPart != null) {
        parsedCategory = categoryFromPart;
      }
    }

    // 2. 從 2KB 標頭預覽中精準提取屬性 (JSON 或正則表達式)
    if (headerPreview.isNotEmpty) {
      try {
        // 先嘗試正則快速匹配
        final durationMatch = RegExp(r'"durationMs"\s*:\s*(\d+)').firstMatch(headerPreview);
        if (durationMatch != null) {
          parsedDuration = int.tryParse(durationMatch.group(1) ?? '0') ?? 0;
        }

        final isErrorMatch = RegExp(r'"isError"\s*:\s*(true|false)').firstMatch(headerPreview);
        if (isErrorMatch != null) {
          parsedError = isErrorMatch.group(1) == 'true';
        }

        final categoryMatch = RegExp(r'"category"\s*:\s*"([^"]+)"').firstMatch(headerPreview);
        if (categoryMatch != null) {
          final cat = ApiLogCategory.fromKey(categoryMatch.group(1));
          if (cat != null) parsedCategory = cat;
        }

        final sourceMatch = RegExp(r'"sourceName"\s*:\s*"([^"]+)"').firstMatch(headerPreview);
        if (sourceMatch != null) {
          parsedSourceName = sourceMatch.group(1) ?? parsedSourceName;
        }
      } catch (_) {}
    }

    final displayTime = DateFormat('yyyy/MM/dd HH:mm:ss').format(parsedTime);

    return ApiLogEntry(
      id: id,
      file: file,
      timestamp: parsedTime,
      category: parsedCategory,
      sourceName: parsedSourceName,
      durationMs: parsedDuration,
      isError: parsedError,
      displayTime: displayTime,
    );
  }
}
