import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:equity_tracker/core/logging/domain/api_log_category.dart';
import 'package:equity_tracker/core/logging/domain/api_log_record.dart';
import 'package:equity_tracker/core/logging/domain/api_log_entry.dart';
import 'package:equity_tracker/core/logging/domain/notification_log_entry.dart';
import 'package:equity_tracker/core/notifications/domain/in_app_notification.dart';

void main() {
  group('LogSanitizer & Zero-Phantom-Field Tests', () {
    test('maskSecret masks sensitive tokens properly', () {
      expect(LogSanitizer.maskSecret('short'), '********');
      expect(LogSanitizer.maskSecret('secret_1234567890_token'), 'secr...ken');
    });

    test('sanitizeHeaders masks Authorization and API key headers', () {
      final headers = {
        'Authorization': 'Bearer secret_token_xyz_123456789',
        'Notion-Version': '2022-06-28',
        'Content-Type': 'application/json',
      };

      final sanitized = LogSanitizer.sanitizeHeaders(headers);
      expect(sanitized, isNotNull);
      expect(sanitized!['Authorization']!.startsWith('Bearer secr...'), isTrue);
      expect(sanitized['Authorization']!.contains('xyz_123456789'), isFalse);
      expect(sanitized['Content-Type'], 'application/json');
    });

    test('sanitizeUrl masks query parameters containing keys or tokens', () {
      const rawUrl = 'https://maps.googleapis.com/maps/api/place/textsearch/json?query=7-11&language=zh-TW&key=AIzaSyD1234567890Abc';
      final sanitized = LogSanitizer.sanitizeUrl(rawUrl);

      expect(sanitized.contains('AIzaSyD1234567890Abc'), isFalse);
      expect(sanitized.contains('key=AIza...Abc'), isTrue);
      expect(sanitized.contains('query=7-11'), isTrue);
    });

    test('cleanPhantomFields strips nulls, empty strings, and empty collections', () {
      final dirty = {
        'title': 'Test',
        'emptyStr': '   ',
        'nullField': null,
        'emptyMap': <String, dynamic>{},
        'emptyList': [],
        'nested': {
          'valid': 123,
          'invalid': null,
        }
      };

      final cleaned = LogSanitizer.cleanPhantomFields(dirty);
      expect(cleaned.containsKey('emptyStr'), isFalse);
      expect(cleaned.containsKey('nullField'), isFalse);
      expect(cleaned.containsKey('emptyMap'), isFalse);
      expect(cleaned.containsKey('emptyList'), isFalse);
      expect(cleaned['title'], 'Test');
      expect(cleaned['nested'], {'valid': 123});
    });
  });

  group('ApiLogRecord Serialization Tests', () {
    test('toJson produces clean output without phantom fields', () {
      final record = ApiLogRecord(
        timestamp: '2026-11-04T10:00:00.000',
        category: ApiLogCategory.notionSync,
        sourceName: 'NotionApiClient',
        durationMs: 350,
        isError: false,
        request: const ApiLogRequest(
          url: 'https://api.notion.com/v1/pages',
          method: 'POST',
          body: {'title': 'Dinner'},
        ),
        response: const ApiLogResponse(
          statusCode: 200,
          body: {'id': 'page_123'},
        ),
      );

      final json = record.toJson();
      expect(json['category'], 'notion_sync');
      expect(json['sourceName'], 'NotionApiClient');
      expect(json['durationMs'], 350);
      expect(json['isError'], false);
      expect(json['request']['method'], 'POST');
      expect(json['request'].containsKey('systemPrompt'), isFalse);
      expect(json['response']['statusCode'], 200);
      expect(json['response'].containsKey('error'), isFalse);
    });
  });

  group('ApiLogEntry 2KB Header Parsing Tests', () {
    test('fromFileWithHeader extracts metadata accurately', () {
      final file = File('20261104_103000_notion_sync_fetchTransactions_123456.json');
      const headerPreview = '''
{
  "timestamp": "2026-11-04T10:30:00.000",
  "category": "notion_sync",
  "sourceName": "fetchTransactions",
  "durationMs": 420,
  "isError": false,
  "request": {"url": "https://api.notion.com"}
}
''';

      final entry = ApiLogEntry.fromFileWithHeader(file, headerPreview);
      expect(entry.category, ApiLogCategory.notionSync);
      expect(entry.sourceName, 'fetchTransactions');
      expect(entry.durationMs, 420);
      expect(entry.isError, false);
      expect(entry.displayTime, '2026/11/04 10:30:00');
    });

    test('fromFileWithHeader extracts error status accurately', () {
      final file = File('20261104_111530_ai_extraction_Extraction_654321.json');
      const headerPreview = '''
{
  "timestamp": "2026-11-04T11:15:30.000",
  "category": "ai_extraction",
  "sourceName": "Extraction",
  "durationMs": 1500,
  "isError": true
}
''';

      final entry = ApiLogEntry.fromFileWithHeader(file, headerPreview);
      expect(entry.category, ApiLogCategory.aiExtraction);
      expect(entry.sourceName, 'Extraction');
      expect(entry.durationMs, 1500);
      expect(entry.isError, true);
    });
  });

  group('NotificationLogEntry Tests', () {
    test('fromFileWithHeader parses notification JSON correctly', () {
      final file = File('20261104_120000_Notification_success_112233.json');
      const content = '''
{
  "timestamp": "2026-11-04T12:00:00.000",
  "type": "success",
  "title": "備份匯出",
  "message": "交易紀錄已成功匯出至本機檔案"
}
''';

      final entry = NotificationLogEntry.fromFileWithHeader(file, content);
      expect(entry.type, NotificationType.success);
      expect(entry.title, '備份匯出');
      expect(entry.message, '交易紀錄已成功匯出至本機檔案');
      expect(entry.displayTime, '2026/11/04 12:00:00');
    });

    test('toEntry directly creates exact NotificationLogEntry with matching type and message', () {
      final file = File('20261104_113630_Notification_success_889900.json');
      const record = NotificationLogRecord(
        timestamp: '2026-11-04T11:36:30.000',
        type: 'success',
        title: null,
        message: 'Transaction deleted',
      );

      final entry = record.toEntry(file);
      expect(entry.id, '20261104_113630_Notification_success_889900');
      expect(entry.type, NotificationType.success);
      expect(entry.title, isNull);
      expect(entry.message, 'Transaction deleted');
      expect(entry.displayTime, '2026/11/04 11:36:30');
    });
  });

  group('ApiLogRecord toEntry Tests', () {
    test('toEntry directly creates exact ApiLogEntry without serialization loss', () {
      final file = File('20261104_100000_notion_sync_NotionApiClient_123456.json');
      final record = ApiLogRecord(
        timestamp: '2026-11-04T10:00:00.000',
        category: ApiLogCategory.notionSync,
        sourceName: 'NotionApiClient',
        durationMs: 350,
        isError: false,
        request: const ApiLogRequest(),
        response: const ApiLogResponse(),
      );

      final entry = record.toEntry(file);
      expect(entry.id, '20261104_100000_notion_sync_NotionApiClient_123456');
      expect(entry.category, ApiLogCategory.notionSync);
      expect(entry.sourceName, 'NotionApiClient');
      expect(entry.durationMs, 350);
      expect(entry.isError, false);
      expect(entry.displayTime, '2026/11/04 10:00:00');
    });

    test('resolvePayload returns safe error map when file does not exist', () async {
      final file = File('non_existent_log_123.json');
      final entry = ApiLogEntry(
        id: 'non_existent_log_123',
        file: file,
        timestamp: DateTime.now(),
        category: ApiLogCategory.notionSync,
        sourceName: 'test',
        durationMs: 100,
        isError: false,
        displayTime: '2026/11/04 12:00:00',
      );

      final payload = await entry.resolvePayload();
      expect(payload.containsKey('error'), isTrue);
    });
  });
}
