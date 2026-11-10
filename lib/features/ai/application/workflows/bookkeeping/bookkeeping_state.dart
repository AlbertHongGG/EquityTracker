import 'package:equity_tracker/features/ai/domain/entities/ai_transaction_draft.dart';
import 'package:equity_tracker/features/ai/domain/enums/ai_intent.dart';
import 'package:equity_tracker/features/ai/domain/models/workflow_step_result.dart';

class BookkeepingRecord {
  AITransactionDraft _data;
  String? _validationQuestion;
  bool isResolved = false;
  final Map<String, dynamic> metadata = {};

  BookkeepingRecord(AITransactionDraft initialData)
      : _data = initialData.copyWith();

  AITransactionDraft get data => _data.copyWith();
  String? get validationQuestion => _validationQuestion;

  void setValidationQuestion(String? question) {
    _validationQuestion = question;
  }

  void markResolved() {
    isResolved = true;
  }

  void updateStore(String storeName) {
    _data = _data.copyWith(store: storeName);
  }

  void updateData(AITransactionDraft newData) {
    _data = newData.copyWith(
      categoryId: newData.categoryId ?? _data.categoryId,
      date: newData.date ?? _data.date,
    );
  }
}

sealed class BookkeepingSuspendedState extends WorkflowSuspendedState {
  final int recordIndex;
  final List<BookkeepingRecord> records;
  final String originalText;

  const BookkeepingSuspendedState({
    required this.recordIndex,
    required this.records,
    required this.originalText,
  }) : super(intent: AIIntent.addTransaction);
}

final class StoreSelectionSuspendedState extends BookkeepingSuspendedState {
  final List<String> options;
  final String message;

  const StoreSelectionSuspendedState({
    required super.recordIndex,
    required super.records,
    required super.originalText,
    required this.options,
    required this.message,
  });
}

final class CorrectionSuspendedState extends BookkeepingSuspendedState {
  final String question;

  const CorrectionSuspendedState({
    required super.recordIndex,
    required super.records,
    required super.originalText,
    required this.question,
  });
}
