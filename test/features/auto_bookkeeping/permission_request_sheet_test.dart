import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:equity_tracker/core/widgets/sheet/permission_request_sheet.dart';
import 'package:equity_tracker/features/auto_bookkeeping/presentation/providers/auto_bookkeeping_notifier.dart';

void main() {
  group('AutoBookkeepingState SSOT Tests', () {
    test('isActive should only be true when both isEnabled and isPermissionGranted are true', () {
      // 1. 預設狀態 (isEnabled = true, isPermissionGranted = false) -> isActive 必須為 false
      const state1 = AutoBookkeepingState(
        isEnabled: true,
        isPermissionGranted: false,
      );
      expect(state1.isActive, isFalse, reason: '未獲權限時即使設定開啟亦不能視為生效');

      // 2. 使用者關閉狀態 (isEnabled = false, isPermissionGranted = true) -> isActive 為 false
      const state2 = AutoBookkeepingState(
        isEnabled: false,
        isPermissionGranted: true,
      );
      expect(state2.isActive, isFalse);

      // 3. 雙重滿足狀態 (isEnabled = true, isPermissionGranted = true) -> isActive 為 true
      const state3 = AutoBookkeepingState(
        isEnabled: true,
        isPermissionGranted: true,
      );
      expect(state3.isActive, isTrue);

      // 4. 兩者皆為 false
      const state4 = AutoBookkeepingState(
        isEnabled: false,
        isPermissionGranted: false,
      );
      expect(state4.isActive, isFalse);
    });
  });

  group('PermissionRequestSheet Widget Tests', () {
    testWidgets('renders LensWise header, icon, title, subtitle and confirms action', (tester) async {
      bool confirmed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    PermissionRequestSheet.show(
                      context: context,
                      headerTitle: 'AUTO BOOKKEEPING',
                      icon: Icons.notifications_active_rounded,
                      title: '開啟通知存取權限',
                      subtitle: '授權讀取銀行與支付推播，即時自動記錄消費',
                      buttonText: '設定權限',
                      onConfirm: () {
                        confirmed = true;
                      },
                    );
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );

      // 點擊按鈕開啟抽屜
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // 驗證標題列
      expect(find.text('AUTO BOOKKEEPING'), findsOneWidget);

      // 驗證圖示與文字
      expect(find.byIcon(Icons.notifications_active_rounded), findsOneWidget);
      expect(find.text('開啟通知存取權限'), findsOneWidget);
      expect(find.text('授權讀取銀行與支付推播，即時自動記錄消費'), findsOneWidget);
      expect(find.text('設定權限'), findsOneWidget);

      // 點擊「設定權限」按鈕
      await tester.tap(find.text('設定權限'));
      await tester.pumpAndSettle();

      // 驗證回呼被觸發且抽屜已關閉
      expect(confirmed, isTrue);
      expect(find.text('開啟通知存取權限'), findsNothing);
    });
  });
}
