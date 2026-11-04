import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:equity_tracker/core/logging/domain/api_log_category.dart';
import 'package:equity_tracker/core/logging/domain/api_log_entry.dart';
import 'package:equity_tracker/core/logging/presentation/widgets/log_inspector_header.dart';
import 'package:equity_tracker/core/logging/presentation/screens/api_log_detail_screen.dart';

class _MockApiLogEntry extends ApiLogEntry {
  final Map<String, dynamic> mockPayload;

  _MockApiLogEntry({
    required super.id,
    required super.file,
    required super.timestamp,
    required super.category,
    required super.sourceName,
    required super.durationMs,
    required super.isError,
    required super.displayTime,
    required this.mockPayload,
  });

  @override
  Future<Map<String, dynamic>> resolvePayload() async => mockPayload;
}

void main() {
  group('LogInspectorHeader Widget Tests (方案 1: 緊湊兩行流)', () {
    testWidgets('renders category, SUCCESS badge, duration, and timestamp correctly', (tester) async {
      final entry = ApiLogEntry(
        id: 'test_log_1',
        file: File('test.json'),
        timestamp: DateTime(2026, 11, 4, 12, 58, 17),
        category: ApiLogCategory.aiExtraction,
        sourceName: 'Extraction',
        durationMs: 1774,
        isError: false,
        displayTime: '2026/11/04 12:58:17',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: LogInspectorHeader(
              entry: entry,
              method: 'POST',
            ),
          ),
        ),
      );

      // 驗證分類文字與 Method
      expect(find.text('AI 記帳解析'), findsOneWidget);
      expect(find.text('POST'), findsOneWidget);

      // 驗證狀態徽章為 SUCCESS
      expect(find.text('SUCCESS'), findsOneWidget);

      // 驗證耗時與時間戳記
      expect(find.text('1774 ms'), findsOneWidget);
      expect(find.text('2026/11/04 12:58:17'), findsOneWidget);
    });

    testWidgets('renders ERROR badge and error duration color on failure', (tester) async {
      final entry = ApiLogEntry(
        id: 'test_log_error',
        file: File('test_error.json'),
        timestamp: DateTime(2026, 11, 4, 13, 0, 0),
        category: ApiLogCategory.notionSync,
        sourceName: 'NotionSync',
        durationMs: 3450,
        isError: true,
        displayTime: '2026/11/04 13:00:00',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: LogInspectorHeader(
              entry: entry,
            ),
          ),
        ),
      );

      // 驗證 ERROR 狀態
      expect(find.text('ERROR'), findsOneWidget);
      expect(find.text('Notion 同步'), findsOneWidget);
      expect(find.text('3450 ms'), findsOneWidget);
      expect(find.text('2026/11/04 13:00:00'), findsOneWidget);
    });

    testWidgets('ApiLogDetailScreen integrates LogInspectorHeader cleanly without AppBar actions', (tester) async {
      final entry = _MockApiLogEntry(
        id: 'test_screen_log',
        file: File('mock.json'),
        timestamp: DateTime.now(),
        category: ApiLogCategory.aiExtraction,
        sourceName: 'Extraction',
        durationMs: 1200,
        isError: false,
        displayTime: '2026/11/04 12:00:00',
        mockPayload: {
          'request': {'method': 'POST', 'prompt': 'test input'},
          'response': {'status': 'ok'},
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ApiLogDetailScreen(entry: entry),
        ),
      );

      // 讓 FutureBuilder 完成微任務
      await tester.pump();
      await tester.pump();

      // 標題顯示在 AppBar
      expect(find.text('Extraction'), findsOneWidget);

      // AppBar 上不再有孤立的 actions，SUCCESS 與分類位於 LogInspectorHeader 內部
      expect(find.text('SUCCESS'), findsOneWidget);
      expect(find.text('AI 記帳解析'), findsOneWidget);
      expect(find.text('POST'), findsOneWidget);
      expect(find.text('1200 ms'), findsOneWidget);
    });
  });
}
