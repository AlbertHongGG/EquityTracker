import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/core/notifications/domain/in_app_notification.dart';

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
/// 3. 自動日誌橋接 (NotificationListener)：任何地方觸發通知，自動派發至監聽器 (如 NotificationLogManager)。
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

    // 自動派發給所有已註冊的監聽器 (如 NotificationLogManager)
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
