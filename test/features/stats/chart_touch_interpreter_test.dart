import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:equity_tracker/features/stats/domain/chart_tooltip_state.dart';
import 'package:equity_tracker/features/stats/domain/chart_touch_interpreter.dart';

TouchLineBarSpot _createSpot(double x, double y) {
  final barData = LineChartBarData(spots: [FlSpot(x, y)]);
  return TouchLineBarSpot(barData, 0, FlSpot(x, y), 0);
}

LineTouchResponse _createResponse(double x, double y) {
  return LineTouchResponse(
    touchLocation: const Offset(150, 50),
    touchChartCoordinate: Offset(x, y),
    lineBarSpots: [_createSpot(x, y)],
  );
}

void main() {
  group('ChartTouchInterpreter Unit Tests (純函式狀態轉換)', () {
    test('有效拖曳手勢應產出 visible: true 並帶有計算後天數與座標', () {
      final updateEvent = FlPanUpdateEvent(
        DragUpdateDetails(
          globalPosition: const Offset(150, 50),
          localPosition: const Offset(150, 50),
        ),
      );

      final next = ChartTouchInterpreter.interpret(
        event: updateEvent,
        response: _createResponse(7.2, 100),
        daysInMonth: 31,
        previous: const ChartTooltipState.hidden(),
      );

      expect(next.isVisible, isTrue);
      expect(next.day, 7);
      expect(next.position, const Offset(150, 50));
    });

    test('放手事件 (FlPanEndEvent) 即使 response 為 null 也產出 isVisible: false 並保留 day/pos', () {
      const prev = ChartTooltipState(
        day: 7,
        position: Offset(150, 50),
        isVisible: true,
      );

      final endEvent = FlPanEndEvent(DragEndDetails());

      final next = ChartTouchInterpreter.interpret(
        event: endEvent,
        response: null,
        daysInMonth: 31,
        previous: prev,
      );

      expect(next.isVisible, isFalse);
      expect(next.day, 7);
      expect(next.position, const Offset(150, 50));
    });

    test('點擊放開事件 (FlTapUpEvent) 應產出 isVisible: false', () {
      const prev = ChartTooltipState(
        day: 15,
        position: Offset(100, 30),
        isVisible: true,
      );

      final tapUpEvent = FlTapUpEvent(
        TapUpDetails(kind: PointerDeviceKind.touch, localPosition: const Offset(100, 30)),
      );

      final next = ChartTouchInterpreter.interpret(
        event: tapUpEvent,
        response: null,
        daysInMonth: 31,
        previous: prev,
      );

      expect(next.isVisible, isFalse);
      expect(next.day, 15);
    });

    test('滑出邊界事件 (FlPointerExitEvent) 應產出 isVisible: false', () {
      const prev = ChartTooltipState(
        day: 5,
        position: Offset(100, 30),
        isVisible: true,
      );

      final exitEvent = FlPointerExitEvent(const PointerExitEvent());

      final next = ChartTouchInterpreter.interpret(
        event: exitEvent,
        response: null,
        daysInMonth: 31,
        previous: prev,
      );

      expect(next.isVisible, isFalse);
      expect(next.day, 5);
    });

    test('當手勢非結束且 response 為空時，應保持 previous 狀態不變', () {
      const prev = ChartTooltipState(
        day: 8,
        position: Offset(80, 20),
        isVisible: true,
      );

      final updateEvent = FlPanUpdateEvent(
        DragUpdateDetails(
          globalPosition: const Offset(80, 20),
          localPosition: const Offset(80, 20),
        ),
      );

      final next = ChartTouchInterpreter.interpret(
        event: updateEvent,
        response: null,
        daysInMonth: 31,
        previous: prev,
      );

      expect(next, equals(prev));
    });
  });
}
