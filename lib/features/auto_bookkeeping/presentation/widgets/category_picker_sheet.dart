import 'package:flutter/material.dart';
import 'package:equity_tracker/core/widgets/sheet/lens_wise_sheet_handle.dart';
import 'package:equity_tracker/features/category/data/category_model.dart';

/// 支出分類選擇抽屜 (CategoryPickerSheet)
/// 1:1 復刻 LensWise 抽屜規範：
/// 1. Handle Bar：高度 32dp 置中，48 × 5dp 膠囊，半徑 2.5dp
/// 2. Header：左右對稱 (48dp Spacer + 13sp 字距 2.0 灰色大寫粗體置中標題 + 48dp Spacer)
/// 3. 格局：5 列圓形圖示網格，充裕垂直空間，杜絕任何溢位 (0.70 childAspectRatio)
class CategoryPickerSheet extends StatelessWidget {
  final List<CategoryModel> categories;
  final String? selectedCategoryId;
  final ValueChanged<String?> onCategorySelected;
  final String title;
  final bool showDefaultOption;

  const CategoryPickerSheet({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
    this.title = '選擇支出分類',
    this.showDefaultOption = false,
  });

  static Future<void> show({
    required BuildContext context,
    required List<CategoryModel> categories,
    required String? selectedCategoryId,
    required ValueChanged<String?> onCategorySelected,
    String title = '選擇支出分類',
    bool showDefaultOption = false,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => CategoryPickerSheet(
        categories: categories,
        selectedCategoryId: selectedCategoryId,
        onCategorySelected: onCategorySelected,
        title: title,
        showDefaultOption: showDefaultOption,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondaryTextColor = isDark
        ? Colors.white.withOpacity(0.54)
        : Colors.black.withOpacity(0.54);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.70,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. LensWise 頂部把手 (32dp 置中)
              LensWiseSheetHandle(isDark: isDark),

              // 2. LensWise Header 導航列 (1:1 對齊 RuleEditBottomSheet 規格)
              Row(
                children: [
                  const SizedBox(width: 48), // 左側 Spacer 平衡
                  Expanded(
                    child: Text(
                      title.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                        color: secondaryTextColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // 右側 Spacer 平衡
                ],
              ),

              const SizedBox(height: 16),

              // 3. Grid View (對齊圖一，5 列網格，圓形圖示+文字，無任何分割線與溢位)
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      childAspectRatio: 0.70,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: (showDefaultOption ? 1 : 0) + categories.length,
                    itemBuilder: (ctx, index) {
                      if (showDefaultOption && index == 0) {
                        final isSelected = selectedCategoryId == null;
                        return _buildItem(
                          icon: Icons.auto_awesome_rounded,
                          color: Colors.blueGrey,
                          name: '全域預設',
                          isSelected: isSelected,
                          onTap: () {
                            onCategorySelected(null);
                            Navigator.pop(ctx);
                          },
                        );
                      }

                      final catIndex = showDefaultOption ? index - 1 : index;
                      final cat = categories[catIndex];
                      final isSelected = cat.id == selectedCategoryId;

                      return _buildItem(
                        icon: cat.iconData,
                        color: cat.color,
                        name: cat.name,
                        isSelected: isSelected,
                        onTap: () {
                          onCategorySelected(cat.id);
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem({
    required IconData icon,
    required Color color,
    required String name,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isSelected
                  ? color
                  : color.withOpacity(0.16),
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: Colors.white, width: 2)
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : color,
              size: icon.fontPackage == null ? 24 : 20,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? color : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
