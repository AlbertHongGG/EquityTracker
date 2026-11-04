import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/core/logging/domain/api_log_category.dart';
import 'package:equity_tracker/core/logging/domain/api_log_record.dart';
import 'package:equity_tracker/core/logging/domain/api_log_entry.dart';
import 'package:equity_tracker/core/logging/domain/i_api_logger.dart';
import 'package:equity_tracker/core/logging/data/log_file_storage.dart';
import 'package:equity_tracker/features/settings/data/settings_repository.dart';
import 'package:equity_tracker/core/providers/repository_providers.dart';

/// API 與 AI 日誌管理器 (ApiLogManager)
///
/// 負責所有外部請求 (AI Agent、Google Maps、Notion API、GitHub Updater) 之日誌持久化與反應式狀態。
class ApiLogManager extends AsyncNotifier<List<ApiLogEntry>> implements IApiLogger {
  late final LogFileStorage _storage;
  late final SettingsRepository _settingsRepo;

  @override
  Future<List<ApiLogEntry>> build() async {
    _storage = LogFileStorage();
    _settingsRepo = ref.read(settingsRepositoryProvider);
    return _loadEntries();
  }

  Future<List<ApiLogEntry>> _loadEntries() async {
    try {
      final files = await _storage.listLogFiles(LogFileStorage.subDirApi);
      final List<ApiLogEntry> entries = [];

      for (final file in files) {
        // 僅讀取前 2KB 標頭預覽，維持記憶體輕量
        final preview = await _storage.readHeaderPreview(file, maxBytes: 2048);
        final entry = ApiLogEntry.fromFileWithHeader(file, preview);
        entries.add(entry);
      }

      // 最新的排在最前面
      entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return entries;
    } catch (e) {
      print('[ApiLogManager] Failed to load entries: $e');
      return [];
    }
  }

  /// 記錄一次 API 或 AI 交互 (內建開關守門)
  Future<void> logInteraction(ApiLogRecord record) async {
    try {
      // 1. 開關守門：若設定關閉，直接短路退出，零磁碟 I/O
      final isEnabled = await _settingsRepo.getApiLogEnabled();
      if (!isEnabled) return;

      // 2. 產生日誌檔名: yyyyMMdd_HHmmss_[category]_[sourceName]_[random].json
      final fileName = _storage.generateFileName(
        category: record.category.key,
        source: record.sourceName,
        prefix: 'Api',
      );

      final payload = record.toJson();
      final file = await _storage.writeLog(
        LogFileStorage.subDirApi,
        fileName,
        payload,
      );

      if (file != null) {
        final newEntry = record.toEntry(file);
        final current = state.value ?? [];
        state = AsyncValue.data([newEntry, ...current]);
      }
    } catch (e) {
      print('[ApiLogManager] Failed to log interaction: $e');
    }
  }

  /// 重新載入日誌清單
  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadEntries());
  }

  /// 刪除單筆 API 日誌
  Future<void> deleteLog(ApiLogEntry entry) async {
    await _storage.deleteLog(entry.file);
    final current = state.value ?? [];
    state = AsyncValue.data(current.where((item) => item.id != entry.id).toList());
  }

  /// 依分類清除日誌 (若 category == null 則清除全部 API 日誌)
  Future<void> clearLogsByCategory(ApiLogCategory? category) async {
    if (category == null) {
      await clearAllLogs();
      return;
    }

    final current = state.value ?? [];
    final toDelete = current.where((item) => item.category == category).toList();
    final remaining = current.where((item) => item.category != category).toList();

    for (final entry in toDelete) {
      await _storage.deleteLog(entry.file);
    }

    state = AsyncValue.data(remaining);
  }

  /// 清空所有 API 日誌
  Future<void> clearAllLogs() async {
    await _storage.clearLogs(LogFileStorage.subDirApi);
    state = const AsyncValue.data([]);
  }
}

final apiLogManagerProvider =
    AsyncNotifierProvider<ApiLogManager, List<ApiLogEntry>>(
  ApiLogManager.new,
);
