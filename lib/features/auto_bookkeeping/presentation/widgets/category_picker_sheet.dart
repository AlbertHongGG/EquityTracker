import 'package:flutter/material.dart';
import 'package:equity_tracker/features/category/data/category_model.dart';

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
    this.title = '選擇預設支出分類',
    this.showDefaultOption = false,
  });

  static Future<void> show({
    required BuildContext context,
    required List<CategoryModel> categories,
    required String? selectedCategoryId,
    required ValueChanged<String?> onCategorySelected,
    String title = '選擇預設支出分類',
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

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.65,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              // Handle Bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              // Title
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1A1D2B),
                ),
              ),
              const SizedBox(height: 20),
              // Grid View (對齊圖一，5 列網格，圓形圖示+文字，無任何分割線)
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      childAspectRatio: 0.78,
                      mainAxisSpacing: 14,
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
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isSelected
                  ? color
                  : color.withValues(alpha: 0.16),
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: Colors.white, width: 2)
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : color,
              size: icon.fontPackage == null ? 26 : 22,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: TextStyle(
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
