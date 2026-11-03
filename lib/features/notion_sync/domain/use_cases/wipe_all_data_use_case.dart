import 'package:equity_tracker/features/notion_sync/domain/sync_state_repository.dart';
import 'package:equity_tracker/features/transaction/data/transaction_repository.dart';
import 'package:equity_tracker/features/auto_bookkeeping/data/auto_bookkeeping_repository.dart';

class WipeAllDataUseCase {
  final ISyncStateRepository _syncStateRepository;
  final TransactionRepository _transactionRepository;
  final AutoBookkeepingRepository? _autoBookkeepingRepository;

  WipeAllDataUseCase(
    this._syncStateRepository,
    this._transactionRepository, [
    this._autoBookkeepingRepository,
  ]);

  /// Wipes all local transactions and unlinks Notion sync state atomically.
  Future<void> execute() async {
    // 1. Unlink Notion and wipe cursors to prevent split-brain state
    await _syncStateRepository.resetCursors();
    
    // 2. Wipe all local data
    await _transactionRepository.clearAllTransactions();
    await _transactionRepository.clearAllRecurringTransactions();

    // 3. Reset auto bookkeeping rules to default
    await _autoBookkeepingRepository?.resetToDefaultRules();
  }
}
