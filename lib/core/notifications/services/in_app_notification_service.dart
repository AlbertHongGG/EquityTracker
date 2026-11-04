import 'package:equity_tracker/core/notifications/controllers/notification_controller.dart';

abstract class InAppNotificationService {
  void showSuccess(String message, {String? title});
  void showError(String message, {String? title});
  void showInfo(String message, {String? title});
  void showWarning(String message, {String? title});
}

/// 應用程式內通知服務實作 (委派至 NotificationController 單一插槽狀態)
class InAppNotificationServiceImpl implements InAppNotificationService {
  final NotificationController _controller;

  InAppNotificationServiceImpl(this._controller);

  @override
  void showSuccess(String message, {String? title}) {
    _controller.showSuccess(message, title: title);
  }

  @override
  void showError(String message, {String? title}) {
    _controller.showError(message, title: title);
  }

  @override
  void showInfo(String message, {String? title}) {
    _controller.showInfo(message, title: title);
  }

  @override
  void showWarning(String message, {String? title}) {
    _controller.showWarning(message, title: title);
  }
}
