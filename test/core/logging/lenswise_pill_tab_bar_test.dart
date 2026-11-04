import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:equity_tracker/core/logging/domain/api_log_category.dart';
import 'package:equity_tracker/core/logging/presentation/widgets/lenswise_pill_tab_bar.dart';

void main() {
  group('LensWisePillTabBar Widget Tests', () {
    final testTabs = ApiLogTabConfig.defaultTabs; // 7 tabs

    testWidgets('accurately sizes tabs to 1/3 viewport and renders with zero overflow', (tester) async {
      // Set a fixed screen size of 360 x 800
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      int selectedIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return LensWisePillTabBar(
                  tabs: testTabs,
                  selectedIndex: selectedIndex,
                  onTabSelected: (index) {
                    setState(() {
                      selectedIndex = index;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Viewport width = 360 - 32 (margin) - 8 (padding) = 320
      // Single Tab width = 320 / 3 = 106.666...
      expect(find.text('全部'), findsOneWidget);
      expect(find.text('記帳解析'), findsOneWidget);
      expect(find.text('店家查詢'), findsOneWidget);

      // Tap on Tab 1 ('記帳解析')
      await tester.tap(find.text('記帳解析'));
      await tester.pump(); // Start animation
      expect(selectedIndex, 1);

      // Mid-flight animation frame
      await tester.pump(const Duration(milliseconds: 130));
      // End of animation
      await tester.pumpAndSettle();

      expect(selectedIndex, 1);
    });

    testWidgets('triggers smooth scroll and displacement when selecting boundary tabs', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      int selectedIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return LensWisePillTabBar(
                  tabs: testTabs,
                  selectedIndex: selectedIndex,
                  onTabSelected: (index) {
                    setState(() {
                      selectedIndex = index;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Programmatically select tab 3 ('驗證修正')
      await tester.tap(find.text('店家查詢'));
      await tester.pumpAndSettle();
      expect(selectedIndex, 2);
    });
  });
}
