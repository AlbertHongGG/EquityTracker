import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// 圖表懸浮卡片狀態模型 (ChartTooltipState)
///
/// 明確定義懸浮視窗的領域狀態，完全解耦於底層圖表元件。
@immutable
class ChartTooltipState {
  final int? day;
  final Offset? position;
  final bool isVisible;

  const ChartTooltipState({
    this.day,
    this.position,
    this.isVisible = false,
  });

  const ChartTooltipState.hidden()
      : day = null,
        position = null,
        isVisible = false;

  const ChartTooltipState.visible({
    required this.day,
    required this.position,
  }) : isVisible = true;

  ChartTooltipState copyWith({
    int? day,
    Offset? position,
    bool? isVisible,
  }) {
    return ChartTooltipState(
      day: day ?? this.day,
      position: position ?? this.position,
      isVisible: isVisible ?? this.isVisible,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChartTooltipState &&
        other.day == day &&
        other.position == position &&
        other.isVisible == isVisible;
  }

  @override
  int get hashCode => Object.hash(day, position, isVisible);

  @override
  String toString() => 'ChartTooltipState(day: $day, pos: $position, visible: $isVisible)';
}
