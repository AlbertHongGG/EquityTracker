import 'package:flutter/material.dart';
import 'package:equity_tracker/core/theme/app_colors.dart';
import 'package:equity_tracker/core/widgets/app_switch.dart';
import 'package:equity_tracker/features/category/data/category_model.dart';

class AutoBookkeepingConfigCard extends StatelessWidget {
  final bool isEnabled;
  final bool notifyOnSuccess;
  final String? defaultCategoryId;
  final List<CategoryModel> categories;
  final bool isDark;
  final ValueChanged<bool> onToggleEnabled;
  final ValueChanged<bool> onToggleNotifyOnSuccess;
  final ValueChanged<String?> onSelectDefaultCategory;

  const AutoBookkeepingConfigCard({
    super.key,
    required this.isEnabled,
    required this.notifyOnSuccess,
    required this.defaultCategoryId,
    required this.categories,
    required this.isDark,
    required this.onToggleEnabled,
    required this.onToggleNotifyOnSuccess,
    required this.onSelectDefaultCategory,
  });

  String _resolveDefaultCategoryName() {
    if (categories.isEmpty) return '信用卡';

    if (defaultCategoryId != null) {
      final matched = categories.where((c) => c.id == defaultCategoryId);
      if (matched.isNotEmpty) return matched.first.name;
    }

    final creditCard = categories.where((c) => c.name == '信用卡');
    if (creditCard.isNotEmpty) return creditCard.first.name;

    final other = categories.where((c) => c.name == '其他');
    if (other.isNotEmpty) return other.first.name;

    return categories.first.name;
  }

  void _showCategoryPicker(BuildContext context) {
    if (categories.isEmpty) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '選擇預設支出分類',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (ctx, index) {
                    final cat = categories[index];
                    return ListTile(
                      title: Text(cat.name),
                      onTap: () {
                        onSelectDefaultCategory(cat.id);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final defaultCatName = _resolveDefaultCategoryName();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        children: [
          // 總開關
          ListTile(
            title: const Text(
              '啟用自動記帳',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text('收到相符通知時，於本地原生秒級新增消費紀錄'),
            trailing: AppSwitch(
              value: isEnabled,
              onChanged: onToggleEnabled,
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          // 成功通知
          ListTile(
            title: const Text(
              '記帳成功推播通知',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text('自動記帳後發出推播，點擊可直接打開並修改分類'),
            trailing: AppSwitch(
              value: notifyOnSuccess,
              onChanged: onToggleNotifyOnSuccess,
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          // 預設分類選擇
          ListTile(
            title: const Text(
              '預設支出分類',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text('未指定分類之刷卡一律歸類至「$defaultCatName」'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  defaultCatName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded, color: Colors.grey),
              ],
            ),
            onTap: () => _showCategoryPicker(context),
          ),
        ],
      ),
    );
  }
}
