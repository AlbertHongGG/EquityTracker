import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/core/services/native_backup_service.dart';
import 'package:equity_tracker/core/providers/repository_providers.dart';

final nativeBackupServiceProvider = Provider<NativeBackupService>((ref) {
  return NativeBackupService(
    ref.read(categoryRepositoryProvider),
    ref.read(transactionRepositoryProvider),
    ref.read(syncStateRepositoryProvider),
    ref.read(autoBookkeepingRepositoryProvider),
  );
});

final snapshotNotifierProvider = NotifierProvider<SnapshotNotifier, Map<SnapshotSource, bool>>(
  SnapshotNotifier.new,
);

class SnapshotNotifier extends Notifier<Map<SnapshotSource, bool>> {
  @override
  Map<SnapshotSource, bool> build() {
    _checkAllSnapshots();
    return {};
  }

  Future<void> _checkAllSnapshots() async {
    final backupService = ref.read(nativeBackupServiceProvider);
    final newState = <SnapshotSource, bool>{};
    for (final source in SnapshotSource.values) {
      newState[source] = await backupService.hasSnapshot(source);
    }
    state = newState;
  }

  Future<void> createSnapshot(SnapshotSource source) async {
    final backupService = ref.read(nativeBackupServiceProvider);
    await backupService.createSnapshot(source);
    state = {...state, source: true};
  }

  Future<BackupRestoreResult> restoreFromSnapshot(SnapshotSource source) async {
    final backupService = ref.read(nativeBackupServiceProvider);
    final result = await backupService.restoreFromSnapshot(source);
    state = {...state, source: false};
    return result;
  }
}
