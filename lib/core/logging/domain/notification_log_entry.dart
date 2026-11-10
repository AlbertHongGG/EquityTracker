import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:equity_tracker/core/notifications/domain/in_app_notification.dart';
import 'package:equity_tracker/core/logging/domain/deletable_log.dart';

/// 系統通知持久化紀錄結構 (NotificationLogRecord)
class NotificationLogRecord {
  final String timestamp;
  final String type;
  final String? title;
  final String message;

  const NotificationLogRecord({
    required this.timestamp,
    required this.type,
    this.title,
    required this.message,
  });

  Map<String, dynamic> toJson() {
    final raw = {
      'timestamp': timestamp,
      'type': type,
      'title': title,
      'message': message,
    };
    raw.removeWhere((key, value) => value == null || value.trim().isEmpty);
    return raw;
  }

  /// 將記憶體中的強型別 Record 直接轉換為 UI Entry，零字串化與零反序列化損耗
  NotificationLogEntry toEntry(File file) {
    final fileName = file.path.split(Platform.pathSeparator).last;
    final id = fileName.replaceAll('.json', '');

    final dt = DateTime.tryParse(timestamp) ?? DateTime.now();
    final parsedType = NotificationType.fromKey(type);
    final displayTime = DateFormat('yyyy/MM/dd HH:mm:ss').format(dt);

    return NotificationLogEntry(
      id: id,
      file: file,
      timestamp: dt,
      type: parsedType,
      title: title,
      message: message,
      displayTime: displayTime,
    );
  }
}

/// 輕量級系統通知日誌列表模型 (NotificationLogEntry)
///
/// 實作 [DeletableLog]，可直接被 GenericLogViewerScaffold 使用。
class NotificationLogEntry implements DeletableLog {
  @override
  final String id;

  @override
  final File file;

  @override
  final DateTime timestamp;

  final NotificationType type;
  final String? title;
  final String message;
  final String displayTime;

  NotificationLogEntry({
    required this.id,
    required this.file,
    required this.timestamp,
    required this.type,
    this.title,
    required this.message,
    required this.displayTime,
  });

  /// 從檔案內容或前 2KB 解析 NotificationLogEntry
  static NotificationLogEntry fromFileWithHeader(File file, String content) {
    final fileName = file.path.split(Platform.pathSeparator).last;
    final id = fileName.replaceAll('.json', '');

    DateTime parsedTime = DateTime.now();
    NotificationType parsedType = NotificationType.info;
    String? parsedTitle;
    String parsedMessage = '';

    if (content.isNotEmpty) {
      try {
        final decoded = jsonDecode(content) as Map<String, dynamic>;
        final ts = decoded['timestamp'] as String?;
        if (ts != null) {
          final dt = DateTime.tryParse(ts);
          if (dt != null) parsedTime = dt;
        }

        parsedType = NotificationType.fromKey(decoded['type'] as String?);
        parsedTitle = decoded['title'] as String?;
        parsedMessage = decoded['message'] as String? ?? '';
      } catch (_) {}
    }

    // 若解析時間失敗，嘗試從檔名解析: yyyyMMdd_HHmmss_Notification_random.json
    if (parsedMessage.isEmpty) {
      final parts = fileName.split('_');
      if (parts.length >= 2) {
        try {
          final dateStr = parts[0];
          final timeStr = parts[1];
          if (dateStr.length == 8 && timeStr.length >= 6) {
            final year = int.parse(dateStr.substring(0, 4));
            final month = int.parse(dateStr.substring(4, 6));
            final day = int.parse(dateStr.substring(6, 8));
            final hour = int.parse(timeStr.substring(0, 2));
            final min = int.parse(timeStr.substring(2, 4));
            final sec = int.parse(timeStr.substring(4, 6));
            parsedTime = DateTime(year, month, day, hour, min, sec);
          }
        } catch (_) {}
      }
    }

    final displayTime = DateFormat('yyyy/MM/dd HH:mm:ss').format(parsedTime);

    return NotificationLogEntry(
      id: id,
      file: file,
      timestamp: parsedTime,
      type: parsedType,
      title: parsedTitle,
      message: parsedMessage,
      displayTime: displayTime,
    );
  }
}
