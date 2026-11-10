import 'package:uuid/uuid.dart';

enum NotificationType {
  success,
  error,
  info,
  warning;

  /// 嚴格依據名稱反序列化，若非約定值則安全 Fallback 為 info
  static NotificationType fromKey(String? key) {
    if (key == null) return NotificationType.info;
    final normalized = key.trim().toLowerCase();
    for (final type in NotificationType.values) {
      if (type.name == normalized) {
        return type;
      }
    }
    return NotificationType.info;
  }
}

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
