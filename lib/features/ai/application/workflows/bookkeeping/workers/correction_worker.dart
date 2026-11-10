import 'package:equity_tracker/features/ai/domain/entities/ai_category_ref.dart';
import 'package:equity_tracker/features/ai/domain/models/workflow_step_result.dart';
import 'package:equity_tracker/features/ai/infrastructure/agents/correction_agent/correction_agent.dart';
import 'package:equity_tracker/features/ai/application/workflows/bookkeeping/bookkeeping_state.dart';
import 'package:equity_tracker/features/ai/application/workflows/bookkeeping/workers/i_bookkeeping_worker.dart';

class CorrectionWorker implements IBookkeepingWorker {
  final CorrectionAgent correctionAgent;

  CorrectionWorker(this.correctionAgent);

  @override
  Future<bool> requiresProcessing(BookkeepingRecord record) async {
    return record.metadata.containsKey('CorrectionWorker_Input');
  }

  @override
  Future<WorkflowStepResult?> process(
    int recordIndex,
    BookkeepingRecord record,
    List<BookkeepingRecord> allRecords,
    String originalText, {
    void Function(String)? onProgress,
  }) async {
    final userInput = record.metadata.remove('CorrectionWorker_Input') as String;
    final categories =
        record.metadata.remove('CorrectionWorker_Categories') as List<AICategoryRef>;
    final question =
        record.metadata.remove('CorrectionWorker_Question') as String?;

    onProgress?.call('處理您的補充資訊...');
    final correctionResponse = await correctionAgent.execute(
      CorrectionInput(
        record: record.data,
        answer: userInput,
        question: question ?? record.validationQuestion,
        categories: categories,
      ),
    );

    record.updateData(correctionResponse.record);
    return null;
  }
}
