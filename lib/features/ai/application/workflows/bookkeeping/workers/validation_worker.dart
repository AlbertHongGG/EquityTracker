import 'package:equity_tracker/features/ai/domain/models/workflow_step_result.dart';
import 'package:equity_tracker/features/ai/infrastructure/agents/validation_agent/validation_agent.dart';
import 'package:equity_tracker/features/ai/application/workflows/bookkeeping/bookkeeping_state.dart';
import 'package:equity_tracker/features/ai/application/workflows/bookkeeping/workers/i_bookkeeping_worker.dart';

class ValidationWorker implements IBookkeepingWorker {
  final ValidationAgent validationAgent;

  ValidationWorker(this.validationAgent);

  @override
  Future<bool> requiresProcessing(BookkeepingRecord record) async {
    if (record.isResolved) return false;

    final currentDataHash = record.data.toMap().toString();
    final lastValidatedHash =
        record.metadata['ValidationWorker_LastHash'] as String?;

    if (currentDataHash == lastValidatedHash) {
      return false;
    }

    return true;
  }

  @override
  Future<WorkflowStepResult?> process(
    int recordIndex,
    BookkeepingRecord record,
    List<BookkeepingRecord> allRecords,
    String originalText, {
    void Function(String)? onProgress,
  }) async {
    onProgress?.call('驗證商品資訊...');
    final validationResponse = await validationAgent.execute(
      ValidationInput(record: record.data),
    );

    record.metadata['ValidationWorker_LastHash'] =
        record.data.toMap().toString();

    if (validationResponse.isValid) {
      onProgress?.call('資訊確認無誤。');
      return null;
    } else {
      final question = validationResponse.question ?? '請補充缺失的資訊。';
      record.setValidationQuestion(question);
      return WorkflowRequiresInput(
        CorrectionSuspendedState(
          recordIndex: recordIndex,
          records: allRecords,
          originalText: originalText,
          question: question,
        ),
      );
    }
  }
}
