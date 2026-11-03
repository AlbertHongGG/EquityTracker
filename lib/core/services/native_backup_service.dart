import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import 'package:equity_tracker/features/notion_sync/domain/sync_state_repository.dart';
import 'package:equity_tracker/features/auto_bookkeeping/data/auto_bookkeeping_repository.dart';

import 'package:equity_tracker/features/category/data/category_repository.dart';
import 'package:equity_tracker/features/transaction/data/transaction_repository.dart';
import 'package:equity_tracker/features/category/data/category_model.dart';
import 'package:equity_tracker/features/transaction/data/transaction_model.dart';
import 'package:equity_tracker/features/transaction/data/recurring_transaction_model.dart';

class BackupRestoreResult {
  final int categoriesImported;
  final int transactionsImported;
  final int recurringTransactionsImported;
  const BackupRestoreResult(this.categoriesImported, this.transactionsImported, this.recurringTransactionsImported);
}

enum SnapshotSource {
  importBackup,
  clearData,
}

class NativeBackupService {
  final CategoryRepository _categoryRepo;
  final TransactionRepository _transactionRepo;
  final ISyncStateRepository _syncStateRepo;
  final AutoBookkeepingRepository? _autoBookkeepingRepo;

  NativeBackupService(
    this._categoryRepo,
    this._transactionRepo,
    this._syncStateRepo, [
    this._autoBookkeepingRepo,
  ]);

  Future<String> createBackupJson() async {
    final categories = await _categoryRepo.getCategories();
    final transactions = await _transactionRepo.getAllTransactions();
    final recurring = await _transactionRepo.getAllRecurringTransactions();
    
    final notionConfig = await _syncStateRepo.exportState();
    final autoBookkeepingConfig = await _autoBookkeepingRepo?.exportState();

    final backupData = {
      'version': 2,
      'timestamp': DateTime.now().toIso8601String(),
      'categories': categories.map((c) => c.toMap()).toList(),
      'transactions': transactions.map((t) => t.toMap()).toList(),
      'recurring_transactions': recurring.map((r) => r.toMap()).toList(),
      'notion_config': notionConfig,
      if (autoBookkeepingConfig != null) 'auto_bookkeeping_config': autoBookkeepingConfig,
    };

    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(backupData);
  }

  String _getSnapshotFileName(SnapshotSource source) {
    switch (source) {
      case SnapshotSource.importBackup:
        return 'snapshot_import_backup.json';
      case SnapshotSource.clearData:
        return 'snapshot_clear_data.json';
    }
  }

  /// Creates a snapshot of the current database before a restore operation.
  Future<void> createSnapshot(SnapshotSource source) async {
    final jsonContent = await createBackupJson();
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/${_getSnapshotFileName(source)}');
    await file.writeAsString(jsonContent);
  }

  /// Checks if a snapshot exists.
  Future<bool> hasSnapshot(SnapshotSource source) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/${_getSnapshotFileName(source)}');
    return await file.exists();
  }

  /// Restores from the snapshot, effectively undoing the last restore.
  Future<BackupRestoreResult> restoreFromSnapshot(SnapshotSource source) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/${_getSnapshotFileName(source)}');
    if (!await file.exists()) {
      throw Exception('No snapshot found for $source.');
    }
    final content = await file.readAsString();
    final result = await replaceDatabaseFromContent(content);
    // Delete snapshot after successful undo so it can only be used once
    await file.delete();
    return result;
  }

  /// Replaces the entire database with the provided JSON content.
  Future<BackupRestoreResult> replaceDatabaseFromContent(String jsonContent) async {
    dynamic json = jsonDecode(jsonContent);
    if (json is! Map<String, dynamic>) throw const FormatException('Root must be object');

    final List<dynamic> catList = json['categories'] ?? [];
    final List<dynamic> txnList = json['transactions'] ?? [];
    final List<dynamic> recurringList = json['recurring_transactions'] ?? [];

    // Clear existing data
    await _transactionRepo.clearAllTransactions();
    await _transactionRepo.clearAllRecurringTransactions();
    await _categoryRepo.clearAllCategories();

    int categoriesImported = 0;
    int transactionsImported = 0;
    int recurringTransactionsImported = 0;

    // Insert Categories
    for (var catMap in catList) {
      if (catMap is! Map<String, dynamic>) continue;
      try {
        final importedCat = CategoryModel.fromMap(catMap);
        await _categoryRepo.addCategoryModel(importedCat);
        categoriesImported++;
      } catch (e) {
        // ignore
      }
    }

    // Insert Transactions
    for (var txnMap in txnList) {
      if (txnMap is! Map<String, dynamic>) continue;
      try {
        final importedTxn = TransactionModel.fromMap(txnMap);
        await _transactionRepo.insertTransaction(importedTxn);
        transactionsImported++;
      } catch (e) {
        // ignore
      }
    }

    // Insert Recurring Transactions
    for (var recMap in recurringList) {
      if (recMap is! Map<String, dynamic>) continue;
      try {
        final importedRec = RecurringTransactionModel.fromMap(recMap);
        await _transactionRepo.insertRecurringTransaction(importedRec);
        recurringTransactionsImported++;
      } catch (e) {
        // ignore
      }
    }

    // Restore Notion Config if present
    if (json.containsKey('notion_config') && json['notion_config'] is Map<String, dynamic>) {
      final notionConfig = json['notion_config'] as Map<String, dynamic>;
      await _syncStateRepo.importState(notionConfig);
    } else {
      // If the backup doesn't have notion config (e.g. older version), wipe the sync cursor to prevent split-brain
      await _syncStateRepo.resetCursors();
      await _syncStateRepo.importState({'token': null, 'database_id': null});
    }

    // Restore Auto Bookkeeping Config if present
    if (json.containsKey('auto_bookkeeping_config') && json['auto_bookkeeping_config'] is Map<String, dynamic>) {
      final autoConfig = json['auto_bookkeeping_config'] as Map<String, dynamic>;
      await _autoBookkeepingRepo?.importState(autoConfig);
    }

    return BackupRestoreResult(categoriesImported, transactionsImported, recurringTransactionsImported);
  }
}
