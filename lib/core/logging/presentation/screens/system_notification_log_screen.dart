import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/core/logging/domain/notification_log_entry.dart';
import 'package:equity_tracker/core/logging/data/notification_log_manager.dart';
import 'package:equity_tracker/core/logging/presentation/widgets/generic_log_viewer_scaffold.dart';
import 'package:equity_tracker/core/logging/presentation/widgets/notification_log_card.dart';
import 'package:equity_tracker/core/logging/presentation/widgets/premium_empty_state.dart';
import 'package:equity_tracker/core/widgets/sheet/swipe_to_confirm_drawer.dart';

/// 系統通知日誌畫面 (SystemNotificationLogScreen)
class SystemNotificationLogScreen extends ConsumerWidget {
  const SystemNotificationLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(notificationLogManagerProvider);
    final items = logsAsync.value ?? [];
    final isLoading = logsAsync.isLoading;

    return GenericLogViewerScaffold<NotificationLogEntry>(
      title: '系統通知日誌',
      subtitle: 'SYSTEM NOTIFICATION LOG',
      items: items,
      isLoading: isLoading,
      emptyState: const PremiumEmptyState(
        title: '尚無通知日誌',
        description: '尚未產生任何系統通知',
        icon: Icons.notifications_none_rounded,
      ),
      itemBuilder: (context, item, isDragging) {
        return NotificationLogCard(
          entry: item,
          isDragging: isDragging,
        );
      },
      onDeleteItem: (item) async {
        await ref.read(notificationLogManagerProvider.notifier).deleteLog(item);
      },
      onClearAll: () {
        SwipeToConfirmDrawer.show(
          context: context,
          title: 'CLEAR NOTIFICATION LOGS',
          sliderTitle: 'SLIDE TO WIPE',
          confirmedTitle: 'RELEASE TO CLEAR',
          onConfirm: () async {
            await ref.read(notificationLogManagerProvider.notifier).clearAllLogs();
          },
        );
      },
    );
  }
}
