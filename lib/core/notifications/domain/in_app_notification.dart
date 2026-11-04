import 'package:uuid/uuid.dart';

enum NotificationType { success, error, info, warning }

/// 應用程式內部彈窗通知模型 (InAppNotification)
class InAppNotification {
  final String id;
  final String message;
  final NotificationType type;
  final String? title;
  final Duration duration;
  final DateTime timestamp;

  InAppNotification({
    String? id,
    required this.message,
    required this.type,
    this.title,
    Duration? duration,
    DateTime? timestamp,
  })  : id = id ?? const Uuid().v4(),
        duration = duration ??
            (type == NotificationType.error
                ? const Duration(milliseconds: 4500)
                : const Duration(milliseconds: 3500)),
        timestamp = timestamp ?? DateTime.now();
}
