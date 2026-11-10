import 'package:equity_tracker/features/ai/domain/models/workflow_step_result.dart';
import 'package:equity_tracker/features/ai/application/workflows/bookkeeping/bookkeeping_state.dart';

abstract interface class IBookkeepingWorker {
  Future<bool> requiresProcessing(BookkeepingRecord record);

  Future<WorkflowStepResult?> process(
    int recordIndex,
    BookkeepingRecord record,
    List<BookkeepingRecord> allRecords,
    String originalText, {
    void Function(String)? onProgress,
  });
}
