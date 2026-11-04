import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/core/notifications/domain/in_app_notification.dart';
import 'package:equity_tracker/core/logging/domain/notification_log_entry.dart';
import 'package:equity_tracker/core/logging/data/log_file_storage.dart';
import 'package:equity_tracker/features/settings/data/settings_repository.dart';
import 'package:equity_tracker/core/providers/repository_providers.dart';

/// 系統通知日誌管理器 (NotificationLogManager)
///
/// 管理系統所有 In-App Notification 的歷史持久化與反應式狀態。
class NotificationLogManager extends AsyncNotifier<List<NotificationLogEntry>> {
  late final LogFileStorage _storage;
  late final SettingsRepository _settingsRepo;

  @override
  Future<List<NotificationLogEntry>> build() async {
    _storage = LogFileStorage();
    _settingsRepo = ref.read(settingsRepositoryProvider);
    return _loadEntries();
  }

  Future<List<NotificationLogEntry>> _loadEntries() async {
    try {
      final files = await _storage.listLogFiles(LogFileStorage.subDirNotifications);
      final List<NotificationLogEntry> entries = [];

      for (final file in files) {
        final content = await _storage.readHeaderPreview(file, maxBytes: 2048);
        final entry = NotificationLogEntry.fromFileWithHeader(file, content);
        entries.add(entry);
      }

      // 最新的排在最前面
      entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return entries;
    } catch (e) {
      print('[NotificationLogManager] Failed to load entries: $e');
      return [];
    }
  }

  Future<List<NotificationLogEntry>> _ensureLoaded() async {
    if (state.hasValue) {
      return state.value!;
    }
    return await future;
  }

  /// 記錄一則通知至磁碟 (內建開關守門)
  Future<void> logNotification({
    required NotificationType type,
    required String message,
    String? title,
  }) async {
    try {
      // 1. 開關守門：若設定關閉，直接短路返回，零磁碟 I/O
      final isEnabled = await _settingsRepo.getNotificationLogEnabled();
      if (!isEnabled) return;

      // 2. 構建持久化模型
      final record = NotificationLogRecord(
        timestamp: DateTime.now().toIso8601String(),
        type: type.name,
        title: title,
        message: message,
      );

      // 3. 產生日誌檔名並寫入
      final fileName = _storage.generateFileName(
        prefix: 'Notification',
        source: type.name,
      );

      final file = await _storage.writeLog(
        LogFileStorage.subDirNotifications,
        fileName,
        record.toJson(),
      );

      if (file != null) {
        final newEntry = record.toEntry(file);
        final current = await _ensureLoaded();
        final filtered = current.where((e) => e.id != newEntry.id).toList();
        state = AsyncValue.data([newEntry, ...filtered]);
      }
    } catch (e) {
      print('[NotificationLogManager] Failed to log notification: $e');
    }
  }

  /// 重新載入日誌清單
  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadEntries());
  }

  /// 刪除單筆通知日誌
  Future<void> deleteLog(NotificationLogEntry entry) async {
    await _storage.deleteLog(entry.file);
    final current = await _ensureLoaded();
    state = AsyncValue.data(current.where((item) => item.id != entry.id).toList());
  }

  /// 清空所有系統通知日誌
  Future<void> clearAllLogs() async {
    await _storage.clearLogs(LogFileStorage.subDirNotifications);
    state = const AsyncValue.data([]);
  }
}

final notificationLogManagerProvider =
    AsyncNotifierProvider<NotificationLogManager, List<NotificationLogEntry>>(
  NotificationLogManager.new,
);
