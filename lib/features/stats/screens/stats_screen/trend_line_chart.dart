import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:equity_tracker/features/stats/presentation/chart_touch_event_handler.dart';
import 'package:equity_tracker/features/stats/screens/stats_screen/trend_chart_tooltip.dart';

class TrendLineChart extends StatefulWidget {
  final Map<int, double> incomeSpots; // Day -> Amount
  final Map<int, double> expenseSpots; // Day -> Amount
  final int daysInMonth;
  final DateTime month; // For tooltip formatting
  final int? selectedDay;
  final Function(int day)? onDateSelected;
  final String currencySymbol;

  const TrendLineChart({
    super.key,
    required this.incomeSpots,
    required this.expenseSpots,
    required this.daysInMonth,
    required this.month,
    this.selectedDay,
    this.onDateSelected,
    required this.currencySymbol,
  });

  @override
  State<TrendLineChart> createState() => _TrendLineChartState();
}

class _TrendLineChartState extends State<TrendLineChart> {
  late ChartTouchEventHandler _touchHandler;

  @override
  void initState() {
    super.initState();
    _initTouchHandler();
  }

  void _initTouchHandler() {
    _touchHandler = ChartTouchEventHandler(
      daysInMonth: widget.daysInMonth,
      onTooltipStateChanged: (state) {
        if (mounted) setState(() {});
      },
      onDateSelected: widget.onDateSelected,
    );
  }

  @override
  void didUpdateWidget(TrendLineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.daysInMonth != widget.daysInMonth ||
        oldWidget.onDateSelected != widget.onDateSelected) {
      _initTouchHandler();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Define Colors
    final incomeColor = const Color(0xFF34C759); // iOS Green
    final expenseColor = Colors.redAccent.shade200;

    // 1. Calculate Max Y to determine interval
    double maxY = 0;
    if (widget.incomeSpots.isNotEmpty) {
      final maxIncome = widget.incomeSpots.values.reduce(
        (a, b) => a > b ? a : b,
      );
      if (maxIncome > maxY) maxY = maxIncome;
    }
    if (widget.expenseSpots.isNotEmpty) {
      final maxExpense = widget.expenseSpots.values.reduce(
        (a, b) => a > b ? a : b,
      );
      if (maxExpense > maxY) maxY = maxExpense;
    }

    // Default to at least 1000 if empty or small
    if (maxY < 1000) maxY = 1000;

    // Add breathing room for tooltip at the top (20%)
    maxY = maxY * 1.2;

    // 2. Determine Interval based on maxY
    double interval = 5000;
    if (maxY <= 1000) {
      interval = 200;
    } else if (maxY <= 3000) {
      interval = 500;
    } else if (maxY <= 6000) {
      interval = 1000;
    } else if (maxY <= 10000) {
      interval = 2500;
    } else {
      interval = 5000;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: interval,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: isDark
                          ? Colors.white10
                          : Colors.grey.withValues(alpha: 0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: false,
                      reservedSize: 32, // Balance
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 5,
                      getTitlesWidget: (value, meta) {
                        final day = value.toInt();
                        final maxDay = widget.daysInMonth;
                        if (day < 1 || day > maxDay) return const SizedBox.shrink();
                        if (day == 1) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              '1',
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black54,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }
                        if (day % 5 != 0) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            '$day',
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black54,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32, // Tightened
                      interval: interval,
                      getTitlesWidget: (value, meta) {
                        if (value != 0 && value % interval != 0) {
                          return const SizedBox.shrink();
                        }
                        String text = value.toInt().toString();
                        if (value >= 1000) {
                          text = '${(value / 1000).toStringAsFixed(1)}k'.replaceAll(
                            '.0k',
                            'k',
                          );
                        }
                        return Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 2.0),
                            child: Text(
                              text,
                              style: TextStyle(
                                color: isDark ? Colors.white54 : Colors.black54,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 1,
                maxX: widget.daysInMonth.toDouble(),
                minY: 0,
                maxY: maxY, // Apply enhanced maxY
                clipData: const FlClipData.none(),
                lineBarsData: [
                  // Income Line
                  LineChartBarData(
                    spots: _generateSmoothSpots(widget.incomeSpots),
                    isCurved: false, // We use custom dense spots for smoothness
                    color: incomeColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          incomeColor.withValues(alpha: 0.2),
                          incomeColor.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // Expense Line
                  LineChartBarData(
                    spots: _generateSmoothSpots(widget.expenseSpots),
                    isCurved: false, // We use custom dense spots for smoothness
                    color: expenseColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          expenseColor.withValues(alpha: 0.2),
                          expenseColor.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
                    return spotIndexes.map((spotIndex) {
                      return TouchedSpotIndicatorData(
                        FlLine(
                          color: isDark ? Colors.white24 : Colors.black12, 
                          strokeWidth: 2,
                          dashArray: [4, 4], // Dashed line
                        ),
                        FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, bar, index) {
                            return FlDotCirclePainter(
                              radius: 5,
                              color: bar.color!,
                              strokeWidth: 3,
                              strokeColor: bar.color!.withValues(alpha: 0.3), // Halo effect
                            );
                          },
                        ),
                      );
                    }).toList();
                  },
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) => null).toList();
                    },
                  ),
                  touchCallback: (event, response) {
                    _touchHandler.handleTouch(event, response);
                  },
                  handleBuiltInTouches: true,
                ),
              ),
            ),
            // 獨立懸浮卡片層 (支援平滑淡出與手勢解耦)
            TrendChartTooltip(
              tooltipState: _touchHandler.currentState,
              incomeSpots: widget.incomeSpots,
              expenseSpots: widget.expenseSpots,
              daysInMonth: widget.daysInMonth,
              month: widget.month,
              currencySymbol: widget.currencySymbol,
              constraints: constraints,
              incomeColor: incomeColor,
              expenseColor: expenseColor,
            ),
          ],
        );
      },
    );
  }

  List<FlSpot> _generateSmoothSpots(Map<int, double> data) {
    // 1. Get raw points
    List<FlSpot> rawSpots = [];
    for (int i = 1; i <= widget.daysInMonth; i++) {
      rawSpots.add(FlSpot(i.toDouble(), data[i] ?? 0));
    }

    if (rawSpots.length < 3) return rawSpots; 

    // 2. Generate dense points using Catmull-Rom Spline
    List<FlSpot> smoothSpots = [];
    final int resolution = 10; // 10 points between each day for smoothness

    for (int i = 0; i < rawSpots.length - 1; i++) {
      FlSpot p0 = i == 0 ? rawSpots[i] : rawSpots[i - 1];
      FlSpot p1 = rawSpots[i];
      FlSpot p2 = rawSpots[i + 1];
      FlSpot p3 = i + 2 < rawSpots.length ? rawSpots[i + 2] : rawSpots[i + 1];

      for (int j = 0; j < resolution; j++) {
        double t = j / resolution;
        double x = p1.x + (p2.x - p1.x) * t;

        double t2 = t * t;
        double t3 = t2 * t;

        // Standard 1D Catmull-Rom Spline formula
        double y = 0.5 *
            ((2 * p1.y) +
                (-p0.y + p2.y) * t +
                (2 * p0.y - 5 * p1.y + 4 * p2.y - p3.y) * t2 +
                (-p0.y + 3 * p1.y - 3 * p2.y + p3.y) * t3);

        // MATHEMATICAL CLAMP: Prevent dropping below 0
        if (y < 0) y = 0;

        smoothSpots.add(FlSpot(x, y));
      }
    }
    
    // Add the final point
    smoothSpots.add(rawSpots.last);
    return smoothSpots;
  }
}
