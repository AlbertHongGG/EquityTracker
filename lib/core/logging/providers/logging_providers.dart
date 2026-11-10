import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/core/logging/domain/api_log_category.dart';
import 'package:equity_tracker/core/logging/domain/api_log_entry.dart';
import 'package:equity_tracker/core/logging/data/log_file_storage.dart';
import 'package:equity_tracker/core/logging/data/api_log_manager.dart';

import 'package:equity_tracker/core/logging/data/api_call_recorder.dart';

export 'package:equity_tracker/core/logging/data/api_log_manager.dart';
export 'package:equity_tracker/core/logging/data/notification_log_manager.dart';
export 'package:equity_tracker/core/logging/data/api_call_recorder.dart';

/// 底層檔案儲存 Provider
final logFileStorageProvider = Provider<LogFileStorage>((ref) {
  return LogFileStorage();
});

/// 通用 API 呼叫攔截器 Provider
final apiCallRecorderProvider = Provider<ApiCallRecorder>((ref) {
  return ApiCallRecorder(ref.watch(apiLogManagerProvider.notifier));
});

/// 依分類篩選 API 日誌的 Family Provider
final filteredApiLogsProvider =
    Provider.family<List<ApiLogEntry>, ApiLogCategory?>((ref, category) {
  final allLogsAsync = ref.watch(apiLogManagerProvider);
  final allLogs = allLogsAsync.value ?? [];

  if (category == null) {
    return allLogs;
  }
  return allLogs.where((log) => log.category == category).toList();
});
