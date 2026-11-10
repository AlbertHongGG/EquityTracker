import 'package:flutter/material.dart';
import 'package:equity_tracker/core/enums/transaction_type.dart';
import 'package:equity_tracker/core/theme/app_colors.dart';

/// 類別收支物理平移滑動膠囊 (CategoryTypeToggle)
///
/// 採用 Stack + AnimatedAlign + Curves.easeInOutCubic 物理平移架構，
/// 取代原先顏色閃現（Color Crossfade）的生硬切換，提供絲滑的水平位移動畫。
class CategoryTypeToggle extends StatelessWidget {
  final TransactionType selectedType;
  final ValueChanged<TransactionType> onChanged;

  const CategoryTypeToggle({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isExpense = selectedType == TransactionType.expense;

    const double width = 200;
    const double height = 42;
    const double padding = 3;
    const double pillWidth = (width - padding * 2) / 2;
    const double pillHeight = height - padding * 2;

    final pillColor = isExpense ? AppColors.expense : AppColors.income;

    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2130) : const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(19),
      ),
      child: Stack(
        children: [
          // 1. 物理滑動指示膠囊 (Sliding Pill Indicator)
          AnimatedAlign(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeInOutCubic,
            alignment: isExpense ? Alignment.centerLeft : Alignment.centerRight,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeInOutCubic,
              width: pillWidth,
              height: pillHeight,
              decoration: BoxDecoration(
                color: pillColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: pillColor.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),

          // 2. 可點擊標籤文字層
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(TransactionType.expense),
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 250),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isExpense
                            ? Colors.white
                            : (isDark
                                  ? Colors.white60
                                  : const Color(0xFF6B7280)),
                      ),
                      child: const Text('Expense'),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(TransactionType.income),
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 250),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: !isExpense
                            ? Colors.white
                            : (isDark
                                  ? Colors.white60
                                  : const Color(0xFF6B7280)),
                      ),
                      child: const Text('Income'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
