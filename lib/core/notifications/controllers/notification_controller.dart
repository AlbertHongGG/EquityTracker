import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/core/notifications/domain/in_app_notification.dart';
import 'package:equity_tracker/core/logging/data/notification_log_manager.dart';

typedef NotificationListenerCallback = void Function(
  NotificationType type,
  String message,
  String? title,
);

/// 全域單一插槽通知控制器 (NotificationController)
///
/// 1:1 復刻 LensWise_Android NotificationController 規範：
/// 1. 單一插槽狀態：畫面至多僅顯示一則通知，徹底廢除垂直疊加與 OverlayEntry 洩漏。
/// 2. 原地平滑覆蓋：新通知進場時立即取消前次倒數並替換狀態。
/// 3. 自動日誌持久化：在 postNotification 時原生調用 NotificationLogManager，
///    保證 100% 確定性寫入，無中介生命週期競態。
class NotificationController extends Notifier<InAppNotification?> {
  Timer? _dismissTimer;
  final List<NotificationListenerCallback> _listeners = [];

  void addListener(NotificationListenerCallback listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  void removeListener(NotificationListenerCallback listener) {
    _listeners.remove(listener);
  }

  @override
  InAppNotification? build() {
    ref.onDispose(() {
      _dismissTimer?.cancel();
      _listeners.clear();
    });
    return null;
  }

  void postNotification(InAppNotification notification) {
    _dismissTimer?.cancel();
    state = notification;

    // 1. 原生直接持久化至 NotificationLogManager (零中介、100% 確定性)
    try {
      ref.read(notificationLogManagerProvider.notifier).logNotification(
        type: notification.type,
        message: notification.message,
        title: notification.title,
      );
    } catch (e) {
      print('[NotificationController] Failed to dispatch to log manager: $e');
    }

    // 2. 派發至外部手動註冊之監聽器 (若有)
    for (final listener in List.of(_listeners)) {
      try {
        listener(notification.type, notification.message, notification.title);
      } catch (e) {
        print('[NotificationController] Error notifying listener: $e');
      }
    }

    _dismissTimer = Timer(notification.duration, () {
      if (state?.id == notification.id) {
        state = null;
      }
    });
  }

  void dismiss() {
    _dismissTimer?.cancel();
    state = null;
  }

  void showSuccess(String message, {String? title}) {
    postNotification(
      InAppNotification(
        message: message,
        type: NotificationType.success,
        title: title,
      ),
    );
  }

  void showError(String message, {String? title}) {
    postNotification(
      InAppNotification(
        message: message,
        type: NotificationType.error,
        title: title,
      ),
    );
  }

  void showInfo(String message, {String? title}) {
    postNotification(
      InAppNotification(
        message: message,
        type: NotificationType.info,
        title: title,
      ),
    );
  }

  void showWarning(String message, {String? title}) {
    postNotification(
      InAppNotification(
        message: message,
        type: NotificationType.warning,
        title: title,
      ),
    );
  }
}

final notificationControllerProvider =
    NotifierProvider<NotificationController, InAppNotification?>(
  NotificationController.new,
);
