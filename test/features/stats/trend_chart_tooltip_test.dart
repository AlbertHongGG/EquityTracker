import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:equity_tracker/features/stats/domain/chart_tooltip_state.dart';
import 'package:equity_tracker/features/stats/screens/stats_screen/trend_chart_tooltip.dart';

void main() {
  group('TrendChartTooltip Widget Tests (毛玻璃懸浮卡片與淡出動畫)', () {
    testWidgets('當 state 為 hidden 且 day 為 null 時不渲染任何內容', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    TrendChartTooltip(
                      tooltipState: const ChartTooltipState.hidden(),
                      incomeSpots: const {},
                      expenseSpots: const {},
                      daysInMonth: 31,
                      month: DateTime(2026, 8, 1),
                      currencySymbol: '\$',
                      constraints: constraints,
                      incomeColor: Colors.green,
                      expenseColor: Colors.red,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.byType(ClipRRect), findsNothing);
    });

    testWidgets('當 state 為 visible 時以 opacity 1.0 渲染日期與金額', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    TrendChartTooltip(
                      tooltipState: const ChartTooltipState.visible(
                        day: 7,
                        position: Offset(120, 20),
                      ),
                      incomeSpots: const {7: 0},
                      expenseSpots: const {7: 1559},
                      daysInMonth: 31,
                      month: DateTime(2026, 8, 1),
                      currencySymbol: '\$',
                      constraints: constraints,
                      incomeColor: Colors.green,
                      expenseColor: Colors.red,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aug 7'), findsOneWidget);
      expect(find.text('\$0'), findsOneWidget);
      expect(find.text('\$1,559'), findsOneWidget);

      final animatedOpacity = tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity));
      expect(animatedOpacity.opacity, 1.0);
    });

    testWidgets('當 state 由 visible 變更為 isVisible: false 時觸發淡出 (opacity: 0.0)', (tester) async {
      ChartTooltipState state = const ChartTooltipState.visible(
        day: 7,
        position: Offset(120, 20),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        TrendChartTooltip(
                          tooltipState: state,
                          incomeSpots: const {7: 0},

                          expenseSpots: const {7: 1559},
                          daysInMonth: 31,
                          month: DateTime(2026, 8, 1),
                          currencySymbol: '\$',
                          constraints: constraints,
                          incomeColor: Colors.green,
                          expenseColor: Colors.red,
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              state = state.copyWith(isVisible: false);
                            });
                          },
                          child: const Text('Release'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity, 1.0);

      // 模擬鬆手，切換為不可見
      await tester.tap(find.text('Release'));
      await tester.pump(); // 開始淡出動畫

      // 檢查 AnimatedOpacity 目標已轉為 0.0
      expect(tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity, 0.0);

      // 推進 150ms 完成淡出
      await tester.pump(const Duration(milliseconds: 150));
      expect(tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity, 0.0);
    });
  });
}
