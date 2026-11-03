import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:equity_tracker/core/services/native_backup_service.dart';
import 'package:equity_tracker/features/transaction/providers/transaction_notifier.dart';
import 'package:equity_tracker/features/settings/providers/settings_notifier.dart';
import 'package:equity_tracker/core/notifications/providers/notification_providers.dart';
import 'package:equity_tracker/features/settings/widgets/common/settings_section.dart';
import 'package:equity_tracker/features/settings/widgets/common/settings_tile.dart';
import 'package:equity_tracker/features/data_management/providers/snapshot_notifier.dart';
import 'package:equity_tracker/features/notion_sync/controllers/notion_config_controller.dart';
import 'package:equity_tracker/features/auto_bookkeeping/presentation/providers/auto_bookkeeping_notifier.dart';
import 'package:go_router/go_router.dart';

class DataManagementSection extends ConsumerStatefulWidget {
  const DataManagementSection({super.key});

  @override
  ConsumerState<DataManagementSection> createState() => _DataManagementSectionState();
}

class _DataManagementSectionState extends ConsumerState<DataManagementSection> {
  bool _isLoading = false;

  Future<void> _exportBackup() async {
    try {
      final String? selectedDirectory = await FilePicker.getDirectoryPath();
      if (selectedDirectory == null) return;

      setState(() => _isLoading = true);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );
      }

      final backupService = ref.read(nativeBackupServiceProvider);
      final jsonContent = await backupService.createBackupJson();

      final now = DateTime.now();
      final yyyy = now.year.toString();
      final mm = now.month.toString().padLeft(2, '0');
      final dd = now.day.toString().padLeft(2, '0');
      final hh = now.hour.toString().padLeft(2, '0');
      final min = now.minute.toString().padLeft(2, '0');
      final ss = now.second.toString().padLeft(2, '0');
      final timestamp = '$yyyy${mm}${dd}_$hh$min$ss';
      final filename = 'equity_tracker_backup_$timestamp.json';
      final path = '$selectedDirectory/$filename';

      final file = File(path);
      await file.writeAsString(jsonContent);

      if (mounted) {
        Navigator.of(context).pop();
        setState(() => _isLoading = false);
      }
      ref.read(inAppNotificationServiceProvider).showSuccess('Backup saved to: $filename');
    } catch (e) {
      if (mounted) {
        if (_isLoading) {
          Navigator.of(context).pop();
          setState(() => _isLoading = false);
        }
      }
      ref.read(inAppNotificationServiceProvider).showError('Export failed: $e');
    }
  }

  Future<void> _importBackup() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() => _isLoading = true);

        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(child: CircularProgressIndicator()),
          );
        }

        final path = result.files.single.path!;
        final file = File(path);
        final content = await file.readAsString();

        // 1. Create a snapshot for undo via Notifier
        await ref.read(snapshotNotifierProvider.notifier).createSnapshot(SnapshotSource.importBackup);
        
        // 2. Replace database
        final backupService = ref.read(nativeBackupServiceProvider);
        final report = await backupService.replaceDatabaseFromContent(content);

        // Reload Notion config in case the backup restored the sync cursor
        await ref.read(notionConfigControllerProvider.notifier).reloadConfig();

        // ignore: unused_result
        ref.refresh(transactionNotifierProvider);
        // ignore: unused_result
        ref.refresh(settingsNotifierProvider);
        ref.invalidate(autoBookkeepingNotifierProvider);

        if (mounted) {
          Navigator.of(context).pop();
          setState(() => _isLoading = false);
        }
        ref.read(inAppNotificationServiceProvider).showSuccess(
          'Restored: ${report.categoriesImported} Categories, ${report.transactionsImported} Transactions, ${report.recurringTransactionsImported} Recurring',
        );
      }
    } catch (e) {
      if (mounted) {
        if (_isLoading) {
          Navigator.of(context).pop();
          setState(() => _isLoading = false);
        }
      }
      ref.read(inAppNotificationServiceProvider).showError('Restore failed: $e');
    }
  }

  Future<void> _undoRestore() async {
    try {
      setState(() => _isLoading = true);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );
      }

      await ref.read(snapshotNotifierProvider.notifier).restoreFromSnapshot(SnapshotSource.importBackup);
      
      // Reload Notion config in case the snapshot restored the sync cursor
      await ref.read(notionConfigControllerProvider.notifier).reloadConfig();
      
      // ignore: unused_result
      ref.refresh(transactionNotifierProvider);
      // ignore: unused_result
      ref.refresh(settingsNotifierProvider);
      ref.invalidate(autoBookkeepingNotifierProvider);

      if (mounted) {
        Navigator.of(context).pop();
        setState(() => _isLoading = false);
      }
      ref.read(inAppNotificationServiceProvider).showSuccess('Restore reverted successfully.');
    } catch (e) {
      if (mounted) {
        if (_isLoading) {
          Navigator.of(context).pop();
          setState(() => _isLoading = false);
        }
      }
      ref.read(inAppNotificationServiceProvider).showError('Undo failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSnapshot = ref.watch(snapshotNotifierProvider.select((state) => state[SnapshotSource.importBackup] ?? false));

    return SettingsSection(
      title: 'DATA MANAGEMENT',
      children: [
        SettingsTile(
          icon: Icons.category_rounded,
          title: 'Manage Categories',
          subtitle: 'Add, Edit, or Remove',
          onTap: () => context.push('/manage-categories'),
        ),
        SettingsTile(
          icon: Icons.file_download_rounded,
          title: 'Export Backup',
          subtitle: 'Save to JSON',
          onTap: _isLoading ? null : _exportBackup,
        ),
        SettingsTile(
          icon: Icons.restore_page_rounded,
          title: 'Restore Backup',
          subtitle: 'Replace current data with backup',
          onTap: _isLoading ? null : _importBackup,
        ),
        if (hasSnapshot)
          SettingsTile(
            icon: Icons.undo_rounded,
            iconColor: Colors.orange,
            title: 'Undo Last Action',
            subtitle: 'Revert to previous state',
            onTap: _isLoading ? null : _undoRestore,
          ),
      ],
    );
  }
}
