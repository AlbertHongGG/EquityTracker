import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:equity_tracker/features/stats/domain/chart_tooltip_state.dart';
import 'package:equity_tracker/features/stats/presentation/chart_touch_event_handler.dart';

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
  group('ChartTouchEventHandler Unit Tests (手勢調度器生命週期)', () {
    late List<ChartTooltipState> tooltipStateLog;
    late List<int> selectedDayLog;
    late ChartTouchEventHandler handler;

    setUp(() {
      tooltipStateLog = [];
      selectedDayLog = [];
      handler = ChartTouchEventHandler(
        daysInMonth: 31,
        onTooltipStateChanged: (state) => tooltipStateLog.add(state),
        onDateSelected: (day) => selectedDayLog.add(day),
      );
    });

    test('有效的拖曳更新事件應正確設為可見並派發選取日期', () {
      final updateEvent = FlPanUpdateEvent(
        DragUpdateDetails(
          globalPosition: const Offset(150, 50),
          localPosition: const Offset(150, 50),
        ),
      );

      handler.handleTouch(updateEvent, _createResponse(7, 100));

      expect(tooltipStateLog.length, 1);
      expect(tooltipStateLog.first.isVisible, isTrue);
      expect(tooltipStateLog.first.day, 7);
      expect(tooltipStateLog.first.position, const Offset(150, 50));
      expect(selectedDayLog, [7]);
    });

    test('放手事件 (FlPanEndEvent) 即使 response 為 null 也必須立即隱藏 Tooltip', () {
      // 1. 模擬先前已在觸碰狀態 (Day 7)
      final updateEvent = FlPanUpdateEvent(
        DragUpdateDetails(
          globalPosition: const Offset(150, 50),
          localPosition: const Offset(150, 50),
        ),
      );
      handler.handleTouch(updateEvent, _createResponse(7, 100));
      expect(handler.currentState.isVisible, isTrue);

      // 2. 模擬鬆手事件，且 response 為 null (核心缺陷場景)
      final endEvent = FlPanEndEvent(DragEndDetails());
      handler.handleTouch(endEvent, null);

      expect(handler.currentState.isVisible, isFalse);
      expect(handler.currentState.day, 7); // 保留天數供平滑淡出
      expect(tooltipStateLog.last.isVisible, isFalse);
    });

    test('點擊放開事件 (FlTapUpEvent) 必須正確隱藏 Tooltip', () {
      // 先觸控
      final updateEvent = FlPanUpdateEvent(
        DragUpdateDetails(
          globalPosition: const Offset(100, 30),
          localPosition: const Offset(100, 30),
        ),
      );
      handler.handleTouch(updateEvent, _createResponse(15, 200));
      expect(handler.currentState.isVisible, isTrue);

      // TapUp 鬆手
      final tapUpEvent = FlTapUpEvent(
        TapUpDetails(kind: PointerDeviceKind.touch, localPosition: const Offset(100, 30)),
      );
      handler.handleTouch(tapUpEvent, null);

      expect(handler.currentState.isVisible, isFalse);
    });

    test('滑出邊界事件 (FlPointerExitEvent) 必須正確隱藏 Tooltip', () {
      final updateEvent = FlPanUpdateEvent(
        DragUpdateDetails(
          globalPosition: const Offset(100, 30),
          localPosition: const Offset(100, 30),
        ),
      );
      handler.handleTouch(updateEvent, _createResponse(5, 50));
      expect(handler.currentState.isVisible, isTrue);

      final exitEvent = FlPointerExitEvent(
        const PointerExitEvent(),
      );
      handler.handleTouch(exitEvent, null);

      expect(handler.currentState.isVisible, isFalse);
    });
  });
}
