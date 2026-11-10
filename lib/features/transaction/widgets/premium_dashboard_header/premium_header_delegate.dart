import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:equity_tracker/core/utils/currency_formatter.dart';
import 'package:equity_tracker/core/widgets/animated_odometer.dart';

class PremiumHeaderDelegate extends SliverPersistentHeaderDelegate {
  final int totalBalance;
  final int totalIncome;
  final int totalExpense;
  final int monthlyBalance;
  final int monthlyIncome;
  final int monthlyExpense;
  final double topPadding;
  final DateTime selectedDate;
  final bool isMonthlyView;
  final VoidCallback onToggleView;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback? onDateTap;
  final bool isPrivacyMode;
  final String currencySymbol;

  PremiumHeaderDelegate({
    required this.totalBalance,
    required this.totalIncome,
    required this.totalExpense,
    required this.monthlyBalance,
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.topPadding,
    required this.selectedDate,
    required this.isMonthlyView,
    required this.onToggleView,
    required this.onPreviousMonth,
    required this.onNextMonth,
    this.onDateTap,
    this.isPrivacyMode = false,
    required this.currencySymbol,
  });

  @override
  double get minExtent => kToolbarHeight + topPadding;

  @override
  double get maxExtent => 175.0;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return _PremiumHeaderContent(
      shrinkOffset: shrinkOffset,
      maxExtent: maxExtent,
      minExtent: minExtent,
      delegate: this,
    );
  }

  @override
  bool shouldRebuild(PremiumHeaderDelegate oldDelegate) {
    return oldDelegate.totalBalance != totalBalance ||
        oldDelegate.monthlyBalance != monthlyBalance ||
        oldDelegate.isMonthlyView != isMonthlyView ||
        oldDelegate.selectedDate != selectedDate ||
        oldDelegate.topPadding != topPadding ||
        oldDelegate.totalIncome != totalIncome ||
        oldDelegate.monthlyIncome != monthlyIncome ||
        oldDelegate.isPrivacyMode != isPrivacyMode ||
        oldDelegate.currencySymbol != currencySymbol;
  }
}

class _PremiumHeaderContent extends StatefulWidget {
  final double shrinkOffset;
  final double maxExtent;
  final double minExtent;
  final PremiumHeaderDelegate delegate;

  const _PremiumHeaderContent({
    required this.shrinkOffset,
    required this.maxExtent,
    required this.minExtent,
    required this.delegate,
  });

  @override
  State<_PremiumHeaderContent> createState() => _PremiumHeaderContentState();
}

class _PremiumHeaderContentState extends State<_PremiumHeaderContent> {
  bool _isRevealed = false;

  void _toggleReveal() {
    if (widget.delegate.isPrivacyMode) {
      setState(() {
        _isRevealed = !_isRevealed;
      });
    }
  }

  String _formatCurrency(int amount) {
    if (widget.delegate.isPrivacyMode && !_isRevealed) {
      return '****';
    }
    return CurrencyFormatter.format(amount, widget.delegate.currencySymbol);
  }

  @override
  Widget build(BuildContext context) {
    final delegate = widget.delegate;

    // 0.0 -> Expanded, 1.0 -> Collapsed
    final progress = (widget.shrinkOffset / (widget.maxExtent - widget.minExtent)).clamp(0.0, 1.0);

    // EXACT BASELINE MORPHING LOGIC:
    final double topMargin = lerpDouble(8.0, 0, progress)!;
    final double sideMargin = lerpDouble(16, 0, progress)!;
    final double bottomMargin = lerpDouble(12, 0, progress)!;
    final double radius = lerpDouble(28, 0, progress)!;

    final double expandedOpacity = (1.0 - (progress * 4.0)).clamp(0.0, 1.0);
    final double collapsedOpacity = ((progress - 0.7) * 3.3).clamp(0.0, 1.0);

    final isCollapsed = progress > 0.5;
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    
    final overlayStyle = isDarkTheme
        ? SystemUiOverlayStyle.light
        : (isCollapsed ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.dark);

    final int currentBalance = delegate.isMonthlyView ? delegate.monthlyBalance : delegate.totalBalance;
    final int currentIncome = delegate.isMonthlyView ? delegate.monthlyIncome : delegate.totalIncome;
    final int currentExpense = delegate.isMonthlyView ? delegate.monthlyExpense : delegate.totalExpense;
    final String labelTitle = delegate.isMonthlyView ? 'Monthly Balance' : 'Total Balance';

    final cardColor = isDarkTheme 
        ? const Color(0xFF1E1E1E).withValues(alpha: 0.75) 
        : Colors.white.withValues(alpha: 0.85);
    final shadowColor = isDarkTheme 
        ? Colors.black.withValues(alpha: 0.4) 
        : const Color(0xFFE2E8F0);
    final textColor = isDarkTheme ? Colors.white : const Color(0xFF1A1A1A);
    final subTextColor = isDarkTheme ? Colors.white54 : const Color(0xFF6B7280);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // === 1. THE MORPHING BACKGROUND (Baseline implementation) ===
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.fromLTRB(sideMargin, topMargin, sideMargin, bottomMargin),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor, // Blocks shadow bleed-through
                    borderRadius: BorderRadius.circular(radius),
                    boxShadow: [
                      BoxShadow(
                        color: shadowColor,
                        blurRadius: lerpDouble(32, 0, progress)!,
                        offset: Offset(0, lerpDouble(12, 0, progress)!),
                      ),
                    ],
                  ),
                  foregroundDecoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(radius),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: isDarkTheme ? 0.1 : 0.4),
                      width: lerpDouble(1.0, 0.0, progress)!,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(radius),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Removed PremiumAuraBg completely for a pristine, clean look
                            
                            // === 2. EXPANDED CONTENT ===
                            if (expandedOpacity > 0)
                              Positioned.fill(
                                child: Opacity(
                                  opacity: expandedOpacity,
                                  child: OverflowBox(
                                    maxHeight: double.infinity,
                                    alignment: Alignment.center,
                                    child: GestureDetector(
                                      onTap: _toggleReveal,
                                      onHorizontalDragEnd: (details) {
                                        if (details.primaryVelocity != null && details.primaryVelocity!.abs() > 300) {
                                          delegate.onToggleView();
                                        }
                                      },
                                      behavior: HitTestBehavior.opaque,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 24),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              // Left: Balance (Deterministic Fixed-Height Layout to prevent jitter)
                                              Expanded(
                                                flex: 12,
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    SizedBox(
                                                      height: 20,
                                                      child: Align(
                                                        alignment: Alignment.centerLeft,
                                                        child: AnimatedSwitcher(
                                                          duration: const Duration(milliseconds: 300),
                                                          child: Text(
                                                            labelTitle,
                                                            key: ValueKey(labelTitle),
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              fontWeight: FontWeight.w600,
                                                              color: subTextColor,
                                                              height: 1.2,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    SizedBox(
                                                      height: 48,
                                                      child: Align(
                                                        alignment: Alignment.centerLeft,
                                                        child: FittedBox(
                                                          fit: BoxFit.scaleDown,
                                                          alignment: Alignment.centerLeft,
                                                          child: AnimatedOdometer(
                                                            formattedValue: _formatCurrency(currentBalance),
                                                            duration: const Duration(milliseconds: 600),
                                                            style: TextStyle(
                                                              fontSize: 38,
                                                              fontWeight: FontWeight.w800,
                                                              color: textColor,
                                                              fontFamily: 'Outfit',
                                                              letterSpacing: -1.0,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              // Right: Income/Expense
                                              Expanded(
                                                flex: 9,
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    _buildDataRow(
                                                      label: 'Income',
                                                      amount: _formatCurrency(currentIncome),
                                                      iconColor: const Color(0xFF10B981), 
                                                      bgColor: const Color(0xFF10B981).withValues(alpha: 0.15),
                                                      icon: Icons.arrow_downward_rounded,
                                                      textColor: textColor,
                                                      subTextColor: subTextColor,
                                                    ),
                                                    const SizedBox(height: 12),
                                                    _buildDataRow(
                                                      label: 'Expense',
                                                      amount: _formatCurrency(currentExpense),
                                                      iconColor: const Color(0xFFF43F5E),
                                                      bgColor: const Color(0xFFF43F5E).withValues(alpha: 0.15),
                                                      icon: Icons.arrow_upward_rounded,
                                                      textColor: textColor,
                                                      subTextColor: subTextColor,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // === 3. COLLAPSED CONTENT (Pinned to Top) ===
            if (collapsedOpacity > 0)
              Positioned(
                top: delegate.topPadding,
                left: 0,
                right: 0,
                height: kToolbarHeight,
                child: Opacity(
                  opacity: collapsedOpacity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left: Compact Month Selector
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: delegate.onPreviousMonth,
                              iconSize: 22,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: Icon(Icons.chevron_left, color: textColor.withValues(alpha: 0.8)),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: delegate.onDateTap,
                              child: Text(
                                DateFormat('yy / MM').format(delegate.selectedDate),
                                style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 16),
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              onPressed: delegate.onNextMonth,
                              iconSize: 22,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: Icon(Icons.chevron_right, color: textColor.withValues(alpha: 0.8)),
                            ),
                          ],
                        ),
                        
                        // Right: Compact Animated Stats
                        Expanded(
                          child: GestureDetector(
                            onTap: _toggleReveal,
                            onHorizontalDragEnd: (details) {
                              if (details.primaryVelocity != null && details.primaryVelocity!.abs() > 300) {
                                delegate.onToggleView();
                              }
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: AnimatedOdometer(
                                    formattedValue: _formatCurrency(currentBalance),
                                    duration: const Duration(milliseconds: 600),
                                    style: TextStyle(color: textColor, fontWeight: FontWeight.w800, fontSize: 15, fontFamily: 'Outfit'),
                                  ),
                                ),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.arrow_downward_rounded, color: const Color(0xFF10B981), size: 10),
                                      const SizedBox(width: 2),
                                      AnimatedOdometer(
                                        formattedValue: _formatCurrency(currentIncome), 
                                        duration: const Duration(milliseconds: 600),
                                        style: TextStyle(color: textColor.withValues(alpha: 0.7), fontSize: 10)
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(Icons.arrow_upward_rounded, color: const Color(0xFFF43F5E), size: 10),
                                      const SizedBox(width: 2),
                                      AnimatedOdometer(
                                        formattedValue: _formatCurrency(currentExpense), 
                                        duration: const Duration(milliseconds: 600),
                                        style: TextStyle(color: textColor.withValues(alpha: 0.7), fontSize: 10)
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow({
    required String label,
    required String amount,
    required Color iconColor,
    required Color bgColor,
    required IconData icon,
    required Color textColor,
    required Color subTextColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
          child: Center(child: Icon(icon, size: 14, color: iconColor)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 14,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: subTextColor,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              SizedBox(
                height: 20,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: AnimatedOdometer(
                      formattedValue: amount,
                      duration: const Duration(milliseconds: 600),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                        fontFamily: 'Outfit',
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
