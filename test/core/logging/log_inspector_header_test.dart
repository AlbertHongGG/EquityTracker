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
  group('LogInspectorHeader Widget Tests (LensWise 風格隨動看板)', () {
    testWidgets('renders sourceName, status code badge (200), duration, timestamp, and copy button', (tester) async {
      bool copied = false;
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
              onCopyLog: () => copied = true,
            ),
          ),
        ),
      );

      // 驗證標題與 200 徽章
      expect(find.text('Extraction'), findsOneWidget);
      expect(find.text('200'), findsOneWidget);

      // 驗證耗時與時間戳記
      expect(find.text('1774 ms'), findsOneWidget);
      expect(find.text('2026/11/04 12:58:17'), findsOneWidget);

      // 驗證複製按鈕與點擊互動
      final copyBtn = find.byIcon(Icons.copy_rounded);
      expect(copyBtn, findsOneWidget);
      await tester.tap(copyBtn);
      expect(copied, isTrue);
    });

    testWidgets('renders 500 status code badge on error', (tester) async {
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

      // 驗證 500 錯誤狀態碼
      expect(find.text('NotionSync'), findsOneWidget);
      expect(find.text('500'), findsOneWidget);
      expect(find.text('3450 ms'), findsOneWidget);
      expect(find.text('2026/11/04 13:00:00'), findsOneWidget);
    });

    testWidgets('ApiLogDetailScreen renders without AppBar and integrates LogInspectorHeader cleanly', (tester) async {
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
          'request': {'prompt': 'test input'},
          'response': {'status_code': 200, 'result': 'ok'},
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ApiLogDetailScreen(entry: entry),
        ),
      );

      // 讓 FutureBuilder 完成
      await tester.pump();
      await tester.pump();

      // 驗證畫面上無任何 AppBar
      expect(find.byType(AppBar), findsNothing);

      // 驗證標題與 200 徽章隨動呈現 (Header 內部)
      expect(find.descendant(of: find.byType(LogInspectorHeader), matching: find.text('Extraction')), findsOneWidget);
      expect(find.descendant(of: find.byType(LogInspectorHeader), matching: find.text('200')), findsOneWidget);
      expect(find.descendant(of: find.byType(LogInspectorHeader), matching: find.text('1200 ms')), findsOneWidget);
      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
    });
  });
}
