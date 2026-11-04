import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/core/notifications/controllers/notification_controller.dart';
import 'package:equity_tracker/core/notifications/services/in_app_notification_service.dart';
import 'package:equity_tracker/core/notifications/services/system_notification_service.dart';
import 'package:equity_tracker/core/notifications/services/app_notification_service.dart';
import 'package:equity_tracker/core/providers/repository_providers.dart';
import 'package:equity_tracker/core/logging/data/notification_log_manager.dart';

export 'package:equity_tracker/core/notifications/controllers/notification_controller.dart';

/// 全域 InAppNotificationService Provider
final inAppNotificationServiceProvider = Provider<InAppNotificationService>((ref) {
  final controller = ref.watch(notificationControllerProvider.notifier);

  // 自動橋接 NotificationListener 至 NotificationLogManager
  // 任何呼叫 showSuccess / showError / showInfo / showWarning 都會自動持久化日誌
  controller.addListener((type, message, title) {
    ref.read(notificationLogManagerProvider.notifier).logNotification(
      type: type,
      message: message,
      title: title,
    );
  });

  return InAppNotificationServiceImpl(controller);
});

final systemNotificationServiceProvider = Provider<SystemNotificationService>((ref) {
  throw UnimplementedError('systemNotificationServiceProvider must be overridden in main.dart');
});

final appNotificationServiceProvider = Provider<AppNotificationService>((ref) {
  return AppNotificationService(
    ref.read(systemNotificationServiceProvider),
    ref.read(categoryRepositoryProvider),
  );
});
