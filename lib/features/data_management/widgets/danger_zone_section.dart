import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/core/providers/usecase_providers.dart';
import 'package:equity_tracker/features/transaction/providers/transaction_notifier.dart';
import 'package:equity_tracker/core/notifications/providers/notification_providers.dart';
import 'package:equity_tracker/core/widgets/scale_button.dart';
import 'package:equity_tracker/features/settings/widgets/common/settings_section.dart';
import 'package:equity_tracker/features/settings/widgets/common/settings_tile.dart';
import 'package:equity_tracker/core/services/native_backup_service.dart';
import 'package:equity_tracker/core/logging/providers/logging_providers.dart';
import 'package:equity_tracker/features/data_management/providers/snapshot_notifier.dart';
import 'package:equity_tracker/features/notion_sync/controllers/notion_config_controller.dart';
import 'package:equity_tracker/features/auto_bookkeeping/presentation/providers/auto_bookkeeping_notifier.dart';
import 'package:equity_tracker/core/widgets/swipe_to_obliterate_button.dart';

class DangerZoneSection extends ConsumerStatefulWidget {
  const DangerZoneSection({super.key});

  @override
  ConsumerState<DangerZoneSection> createState() => _DangerZoneSectionState();
}

class _DangerZoneSectionState extends ConsumerState<DangerZoneSection> {
  bool _isLoading = false;

  Future<void> _clearAllData() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    
    try {
      // 1. Create a snapshot for undo via Notifier
      await ref.read(snapshotNotifierProvider.notifier).createSnapshot(SnapshotSource.clearData);
      
      // 2. Delegate to the Wipe All Data Use Case for atomic wipe
      await ref.read(wipeAllDataUseCaseProvider).execute();

      // 同步清空日誌管理器記憶體狀態，防止 Split-Brain
      await ref.read(apiLogManagerProvider.notifier).clearAllLogs();
      await ref.read(notificationLogManagerProvider.notifier).clearAllLogs();

      // 3. Refresh state
      // ignore: unused_result
      ref.refresh(transactionNotifierProvider);
      ref.invalidate(titleSuggestionProvider);
      ref.invalidate(notionConfigControllerProvider); // Force Notion UI state to reset
      ref.invalidate(autoBookkeepingNotifierProvider);

      ref.read(inAppNotificationServiceProvider).showSuccess('All data & Notion sync cleared successfully.');
    } catch (e) {
      ref.read(inAppNotificationServiceProvider).showError('Failed to clear data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _undoClearData() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      await ref.read(snapshotNotifierProvider.notifier).restoreFromSnapshot(SnapshotSource.clearData);
      
      // Reload Notion config in case the snapshot restored the sync cursor
      await ref.read(notionConfigControllerProvider.notifier).reloadConfig();
      
      // ignore: unused_result
      ref.refresh(transactionNotifierProvider);
      ref.invalidate(titleSuggestionProvider);
      ref.invalidate(autoBookkeepingNotifierProvider);

      ref.read(inAppNotificationServiceProvider).showSuccess('Data restored successfully!');
      
    } catch (e) {
      ref.read(inAppNotificationServiceProvider).showError('Undo failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showClearDataConfirmation(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7), // Match time picker light background if light mode
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.only(left: 24, right: 24, top: 12, bottom: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle for bottom sheet
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            
            // Refined Header (Time Picker Style from image)
            Center(
              child: Text(
                'CLEAR ALL DATA',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Solid, minimalistic Swipe Button
            SwipeToObliterateButton(
              title: 'SLIDE TO WIPE',
              isLoading: _isLoading,
              activeColor: Colors.redAccent,
              onConfirmed: () async {
                Navigator.pop(ctx);
                await _clearAllData();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasSnapshot = ref.watch(snapshotNotifierProvider.select((state) => state[SnapshotSource.clearData] ?? false));

    return SettingsSection(
      title: 'DANGER ZONE',
      children: [
        SettingsTile(
          icon: Icons.delete_forever_rounded,
          title: 'Clear All Data',
          subtitle: 'Delete all records (with undo option)',
          isDestructive: true,
          onTap: _isLoading ? null : () => _showClearDataConfirmation(context),
        ),
        if (hasSnapshot)
          SettingsTile(
            icon: Icons.undo_rounded,
            iconColor: Colors.orange,
            title: 'Undo Last Action',
            subtitle: 'Revert to previous state',
            onTap: _isLoading ? null : _undoClearData,
          ),
      ],
    );
  }
}
