import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/category/providers/category_notifier.dart';
import 'package:equity_tracker/features/category/screens/category_management_screen/category_type_toggle.dart';
import 'package:equity_tracker/features/category/screens/category_management_screen/category_reorderable_grid.dart';
import 'package:equity_tracker/features/category/controllers/category_management_controller.dart';

/// 分類管理畫面 (CategoryManagementScreen)
///
/// 遵循極簡無框設計 (Minimalist Borderless UI)：
/// 1. 徹底移除傳統 AppBar 與返回按鈕，頂部即為操作區。
/// 2. 居中配置物理平移滑動膠囊 (Expense / Income)。
/// 3. 右側配置編輯/完成切換按鈕。
class CategoryManagementScreen extends ConsumerWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(categoryManagementControllerProvider);
    final controller = ref.read(categoryManagementControllerProvider.notifier);
    
    final categoriesAsync = ref.watch(categoryListProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F111A)
          : const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // 頂部列：居中滑動 Tab + 右側編輯動作按鈕
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: CategoryTypeToggle(
                      selectedType: state.selectedType,
                      onChanged: controller.updateType,
                    ),
                  ),
                  Positioned(
                    right: 4,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: controller.toggleEditMode,
                        borderRadius: BorderRadius.circular(22),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: state.isEditMode
                                ? theme.primaryColor.withValues(alpha: 0.15)
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.black.withValues(alpha: 0.05)),
                          ),
                          child: Icon(
                            state.isEditMode ? Icons.check_rounded : Icons.edit_outlined,
                            size: 20,
                            color: state.isEditMode
                                ? theme.primaryColor
                                : (isDark ? Colors.white : const Color(0xFF1F2937)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: categoriesAsync.when(
                data: (categories) {
                  final filteredCats = categories
                      .where((c) => c.type == state.selectedType)
                      .toList();

                  return CategoryReorderableGrid(
                    categories: filteredCats,
                    type: state.selectedType,
                    isEditMode: state.isEditMode,
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
