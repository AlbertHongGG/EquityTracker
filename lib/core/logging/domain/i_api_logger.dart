import 'package:equity_tracker/core/logging/domain/api_log_record.dart';

/// 抽象 API 日誌記錄介面 (IApiLogger)
///
/// 遵循依賴反轉原則 (Dependency Inversion Principle, DIP)：
/// 業務層 (BaseAgent、GoogleMapSearchService、ApiCallRecorder) 僅依賴此抽象介面，
/// 完全解耦於具體的 Riverpod Notifier 或儲存引擎。
abstract interface class IApiLogger {
  Future<void> logInteraction(ApiLogRecord record);
}
