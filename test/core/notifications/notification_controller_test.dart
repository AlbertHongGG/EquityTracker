import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/core/notifications/domain/in_app_notification.dart';
import 'package:equity_tracker/core/notifications/controllers/notification_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('NotificationController Unit Tests', () {
    test('initial state is null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(notificationControllerProvider);
      expect(state, isNull);
    });

    test('postNotification sets single notification and dispatches to listener', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(notificationControllerProvider.notifier);

      NotificationType? listenedType;
      String? listenedMessage;
      String? listenedTitle;

      controller.addListener((type, message, title) {
        listenedType = type;
        listenedMessage = message;
        listenedTitle = title;
      });

      controller.showSuccess('資料已成功儲存', title: '成功');

      final current = container.read(notificationControllerProvider);
      expect(current, isNotNull);
      expect(current!.type, NotificationType.success);
      expect(current.message, '資料已成功儲存');
      expect(current.title, '成功');

      // 驗證自動派發監聽器
      expect(listenedType, NotificationType.success);
      expect(listenedMessage, '資料已成功儲存');
      expect(listenedTitle, '成功');
    });

    test('new notification instantly overwrites existing notification (Single-Slot)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(notificationControllerProvider.notifier);

      controller.showInfo('第一次通知');
      final first = container.read(notificationControllerProvider);
      expect(first!.message, '第一次通知');

      controller.showError('第二次錯誤通知');
      final second = container.read(notificationControllerProvider);
      expect(second!.message, '第二次錯誤通知');
      expect(second.type, NotificationType.error);
      expect(second.id != first.id, isTrue);
    });

    test('dismiss clears the notification immediately', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(notificationControllerProvider.notifier);

      controller.showWarning('注意連線狀態');
      expect(container.read(notificationControllerProvider), isNotNull);

      controller.dismiss();
      expect(container.read(notificationControllerProvider), isNull);
    });
  });
}
