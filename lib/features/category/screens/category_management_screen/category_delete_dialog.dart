import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/core/notifications/providers/notification_providers.dart';
import 'package:equity_tracker/core/widgets/sheet/swipe_to_confirm_drawer.dart';
import 'package:equity_tracker/features/category/data/category_model.dart';
import 'package:equity_tracker/features/category/providers/category_notifier.dart';

/// 分類刪除確認抽屜 (CategoryDeleteDialog / Sheet)
/// 全面升級為 1:1 LensWise 滑動抹除抽屜 (SwipeToConfirmDrawer)
class CategoryDeleteDialog {
  static Future<void> show(BuildContext context, CategoryModel category) {
    return SwipeToConfirmDrawer.show(
      context: context,
      title: 'CLEAR ${category.name} CATEGORY',
      sliderTitle: 'SLIDE TO WIPE',
      confirmedTitle: 'RELEASE TO CLEAR',
      activeColor: const Color(0xFFEF4444),
      onConfirm: () {
        final container = ProviderScope.containerOf(context, listen: false);
        container
            .read(categoryListProvider.notifier)
            .deleteCategoryModel(category.id, category.type);
        container
            .read(inAppNotificationServiceProvider)
            .showSuccess('Category deleted');
      },
    );
  }
}
