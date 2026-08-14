import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:equity_tracker/core/providers/repository_providers.dart';
import 'package:equity_tracker/features/transaction/providers/transaction_notifier.dart';
import 'package:equity_tracker/features/transaction/domain/process_recurring_transactions_usecase.dart';
import 'package:equity_tracker/features/transaction/data/recurring_transaction_model.dart';
import 'package:equity_tracker/core/notifications/providers/notification_providers.dart';


final processRecurringTransactionsUseCaseProvider = Provider<ProcessRecurringTransactionsUseCase>((ref) {
  return ProcessRecurringTransactionsUseCase(ref.watch(transactionRepositoryProvider));
});

final recurringTransactionListProvider =
    AsyncNotifierProvider<
      RecurringTransactionListNotifier,
      List<RecurringTransactionModel>
    >(RecurringTransactionListNotifier.new);

class RecurringTransactionListNotifier extends AsyncNotifier<List<RecurringTransactionModel>> {
  Timer? _timer;

  @override
  Future<List<RecurringTransactionModel>> build() async {
    ref.onDispose(() {
      _timer?.cancel();
    });
    final list = await _fetchExistingRecurringTransactions();
    _scheduleNextTrigger(list);
    return list;
  }

  Future<List<RecurringTransactionModel>> _fetchExistingRecurringTransactions() async {
    return await ref.read(transactionRepositoryProvider).getAllRecurringTransactions();
  }

  Future<void> addRecurringTransaction(RecurringTransactionModel transaction) async {
    await ref.read(transactionRepositoryProvider).insertRecurringTransaction(transaction);
    ref.invalidateSelf();
    await future;
  }

  Future<void> updateRecurringTransaction(RecurringTransactionModel transaction) async {
    await ref.read(transactionRepositoryProvider).updateRecurringTransaction(transaction);
    ref.invalidateSelf();
    await future;
  }

  Future<void> deleteRecurringTransaction(int id) async {
    await ref.read(transactionRepositoryProvider).deleteRecurringTransaction(id);
    ref.invalidateSelf();
    await future;
  }

  bool _isProcessing = false;

  Future<void> checkAndProcess() async {
    if (_isProcessing) return;
    _isProcessing = true;
    try {
      final generated = await ref.read(processRecurringTransactionsUseCaseProvider).execute();
      if (generated.isNotEmpty) {
        ref.invalidate(transactionListProvider);
        final list = await _fetchExistingRecurringTransactions();
        state = AsyncValue.data(list);
        _scheduleNextTrigger(list);
        
        // 發送獨立的推播通知
        final appNotifService = ref.read(appNotificationServiceProvider);
        for (final transaction in generated) {
          await appNotifService.showTransactionAddedNotification(transaction);
        }
      }
    } finally {
      _isProcessing = false;
    }
  }

  void _scheduleNextTrigger(List<RecurringTransactionModel> transactions) {
    _timer?.cancel();

    final enabled = transactions.where((t) => t.isEnabled).toList();
    if (enabled.isEmpty) return;

    enabled.sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
    final earliest = enabled.first;

    final now = DateTime.now();
    final difference = earliest.nextDueDate.difference(now);

    if (difference.isNegative) {
      checkAndProcess();
    } else {
      _timer = Timer(difference + const Duration(seconds: 1), () {
        checkAndProcess();
      });
    }
  }
}
