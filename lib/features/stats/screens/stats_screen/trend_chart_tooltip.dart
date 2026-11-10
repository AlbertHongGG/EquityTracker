import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:equity_tracker/core/utils/currency_formatter.dart';
import 'package:equity_tracker/features/stats/domain/chart_tooltip_state.dart';

/// 統計圖表懸浮毛玻璃卡片 (TrendChartTooltip)
///
/// 獨立封裝手勢懸浮資訊的渲染、幾何計算與平滑淡出 (Fade-out) 動畫。
class TrendChartTooltip extends StatelessWidget {
  final ChartTooltipState tooltipState;
  final Map<int, double> incomeSpots;
  final Map<int, double> expenseSpots;
  final int daysInMonth;
  final DateTime month;
  final String currencySymbol;
  final BoxConstraints constraints;
  final Color incomeColor;
  final Color expenseColor;

  const TrendChartTooltip({
    super.key,
    required this.tooltipState,
    required this.incomeSpots,
    required this.expenseSpots,
    required this.daysInMonth,
    required this.month,
    required this.currencySymbol,
    required this.constraints,
    required this.incomeColor,
    required this.expenseColor,
  });

  @override
  Widget build(BuildContext context) {
    final day = tooltipState.day;
    if (day == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final income = incomeSpots[day] ?? 0;
    final expense = expenseSpots[day] ?? 0;

    final dateStr = DateFormat('MMM d').format(DateTime(month.year, month.month, day));

    // Tooltip 寬度適度保留 (避免金額較大時橫向溢出)
    const double tooltipWidth = 112.0;

    // 依據 Y 軸預留 padding 與繪圖區計算精確 X 座標
    const double leftPadding = 32.0; // FlTitlesData left reservedSize
    final double plotWidth = constraints.maxWidth - leftPadding;
    final double dayPercent = (day - 1) / (daysInMonth - 1);
    final double exactX = leftPadding + (dayPercent * plotWidth);

    // 水平居中對齊垂直線，並在兩側保留 8px 安全留白防溢出
    double left = exactX - (tooltipWidth / 2);
    left = left.clamp(8.0, constraints.maxWidth - tooltipWidth - 8.0);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOutCubic,
      left: left,
      top: 8,
      child: IgnorePointer(
        ignoring: !tooltipState.isVisible,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          opacity: tooltipState.isVisible ? 1.0 : 0.0,
          child: Container(
            width: tooltipWidth,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1C1C1E).withValues(alpha: 0.55)
                        : Colors.white.withValues(alpha: 0.65),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.8),
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        dateStr,
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // 收入 (綠色向上箭頭)
                      Row(
                        children: [
                          Icon(Icons.arrow_upward_rounded, color: incomeColor, size: 14),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              CurrencyFormatter.format(income.toInt(), currencySymbol),
                              textAlign: TextAlign.right,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: incomeColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      // 支出 (紅色向下箭頭)
                      Row(
                        children: [
                          Icon(Icons.arrow_downward_rounded, color: expenseColor, size: 14),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              CurrencyFormatter.format(expense.toInt(), currencySymbol),
                              textAlign: TextAlign.right,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: expenseColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
