import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:equity_tracker/features/stats/screens/stats_screen/trend_line_chart.dart';
import 'package:equity_tracker/features/stats/screens/stats_screen/trend_chart_tooltip.dart';

void main() {
  group('TrendLineChart End-to-End Regression Tests (整合父層 Rebuild 與手勢生命週期)', () {
    testWidgets('在父層因 onDateSelected 觸發 setState rebuild 時，Tooltip 仍持續可見且不被重置', (tester) async {
      int? selectedDay;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    SizedBox(
                      width: 400,
                      height: 250,
                      child: TrendLineChart(
                        incomeSpots: const {7: 0},
                        expenseSpots: const {7: 1559},
                        daysInMonth: 31,
                        month: DateTime(2026, 8, 1),
                        selectedDay: selectedDay,
                        currencySymbol: '\$',
                        onDateSelected: (day) {
                          // 模擬 MonthlyTrendTab 的行內閉包與 setState
                          setState(() {
                            selectedDay = day;
                          });
                        },
                      ),
                    ),
                    Text('Selected: $selectedDay'),
                  ],
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 一開始未觸碰，Tooltip 不可見
      expect(find.byType(TrendChartTooltip), findsOneWidget);
      expect(find.text('Aug 7'), findsNothing);

      // 模擬手指按下並在圖表上移動至第 7 天的橫向位置
      // 圖表左 padding 為 32，總寬 400，plotWidth = 368，Day 7 percent = 6/30 = 0.2，X ≈ 32 + 73.6 = 105.6
      final chartCenter = tester.getCenter(find.byType(TrendLineChart));
      final gesture = await tester.startGesture(Offset(105.6, chartCenter.dy));
      await tester.pump();

      // 此時手指按住，應觸發 onDateSelected(7)，父層完成 setState
      expect(selectedDay, 7);
      expect(find.text('Selected: 7'), findsOneWidget);

      // 核心驗證：即便父層 rebuild，Tooltip 必須持續顯示！
      expect(find.text('Aug 7'), findsOneWidget);
      expect(find.text('\$1,559'), findsOneWidget);
      final animatedOpacity = tester.widget<AnimatedOpacity>(
        find.descendant(of: find.byType(TrendChartTooltip), matching: find.byType(AnimatedOpacity)),
      );
      expect(animatedOpacity.opacity, 1.0);

      // 模擬放手 (PointerUp)
      await gesture.up();
      await tester.pump(); // 觸發放手事件

      // 核心驗證：放手後，Tooltip 進入淡出狀態 (opacity == 0.0)
      final opacityAfterRelease = tester.widget<AnimatedOpacity>(
        find.descendant(of: find.byType(TrendChartTooltip), matching: find.byType(AnimatedOpacity)),
      );
      expect(opacityAfterRelease.opacity, 0.0);

      // 下方的選取狀態不受影響，依然為 7
      expect(selectedDay, 7);
      expect(find.text('Selected: 7'), findsOneWidget);

      // 動畫播放結束
      await tester.pump(const Duration(milliseconds: 200));
    });
  });
}
