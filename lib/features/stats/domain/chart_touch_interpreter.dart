import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart';
import 'package:equity_tracker/features/stats/domain/chart_tooltip_state.dart';

/// 圖表觸控手勢純函式解析器 (ChartTouchInterpreter)
///
/// 無狀態 (Stateless)、無副作用 (Pure Function)、無回呼耦合。
/// 將底層 fl_chart 的 FlTouchEvent 與 LineTouchResponse 轉換為明確的領域狀態 [ChartTooltipState]。
class ChartTouchInterpreter {
  const ChartTouchInterpreter._();

  /// 依據當前事件與前一次狀態，計算產出最新的 Tooltip 狀態
  static ChartTooltipState interpret({
    required FlTouchEvent event,
    required LineTouchResponse? response,
    required int daysInMonth,
    required ChartTooltipState previous,
  }) {
    // 1. 最高優先級：判定手勢是否結束、取消或離開
    final bool isInteractionEnd = !event.isInterestedForInteractions ||
        event is FlPanEndEvent ||
        event is FlPanCancelEvent ||
        event is FlTapUpEvent ||
        event is FlTapCancelEvent ||
        event is FlPointerExitEvent ||
        event is FlLongPressEnd;

    if (isInteractionEnd) {
      // 保持先前記錄的 day 與 position，僅變更 isVisible: false，供平滑淡出動畫使用
      return previous.copyWith(isVisible: false);
    }

    // 2. 有效互動事件：確認是否有觸碰到的數據點
    if (response == null ||
        response.lineBarSpots == null ||
        response.lineBarSpots!.isEmpty) {
      return previous;
    }

    final spot = response.lineBarSpots!.first;
    final day = spot.x.round().clamp(1, daysInMonth);
    final position = event.localPosition ?? previous.position ?? Offset.zero;

    return ChartTooltipState(
      day: day,
      position: position,
      isVisible: true,
    );
  }
}
