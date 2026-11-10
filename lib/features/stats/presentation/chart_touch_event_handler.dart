import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart';
import 'package:equity_tracker/features/stats/domain/chart_tooltip_state.dart';

/// 圖表觸控手勢事件調度器 (ChartTouchEventHandler)
///
/// 負責將底層 fl_chart 的 FlTouchEvent 與 LineTouchResponse 轉換為清晰的領域互動狀態。
/// 徹底解決離手事件被 early-return 短路攔截的缺陷，並保障手勢生命週期的完整性。
class ChartTouchEventHandler {
  final int daysInMonth;
  final void Function(ChartTooltipState state)? onTooltipStateChanged;
  final void Function(int day)? onDateSelected;

  ChartTooltipState _currentState = const ChartTooltipState.hidden();
  int? _lastSelectedDay;

  ChartTouchEventHandler({
    required this.daysInMonth,
    this.onTooltipStateChanged,
    this.onDateSelected,
  });

  ChartTooltipState get currentState => _currentState;

  /// 處理圖表手勢事件
  void handleTouch(FlTouchEvent event, LineTouchResponse? response) {
    // 1. 最高優先級：判定手勢是否結束、取消或離開
    final bool isInteractionEnd = !event.isInterestedForInteractions ||
        event is FlPanEndEvent ||
        event is FlPanCancelEvent ||
        event is FlTapUpEvent ||
        event is FlTapCancelEvent ||
        event is FlPointerExitEvent ||
        event is FlLongPressEnd;

    if (isInteractionEnd) {
      if (_currentState.isVisible) {
        // 保留最後的 day 與 position，僅切換 isVisible: false，確保淡出動畫不會位置跳躍
        _currentState = _currentState.copyWith(isVisible: false);
        onTooltipStateChanged?.call(_currentState);
      }
      return;
    }

    // 2. 有效互動事件：確認是否有觸碰到的數據點
    if (response == null ||
        response.lineBarSpots == null ||
        response.lineBarSpots!.isEmpty) {
      return;
    }

    final spot = response.lineBarSpots!.first;
    final day = spot.x.round().clamp(1, daysInMonth);
    final position = event.localPosition ?? _currentState.position ?? Offset.zero;

    _currentState = ChartTooltipState(
      day: day,
      position: position,
      isVisible: true,
    );
    onTooltipStateChanged?.call(_currentState);

    if (_lastSelectedDay != day) {
      _lastSelectedDay = day;
      onDateSelected?.call(day);
    }
  }

  /// 重置內部狀態（例如圖表月份切換時調用）
  void reset() {
    _currentState = const ChartTooltipState.hidden();
    _lastSelectedDay = null;
  }
}
