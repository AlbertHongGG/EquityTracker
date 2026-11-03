import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/settings/widgets/common/settings_section.dart';
import 'package:equity_tracker/features/settings/widgets/common/settings_tile.dart';
import 'package:equity_tracker/features/notion_sync/screens/notion_config_screen.dart';
import 'package:equity_tracker/features/auto_bookkeeping/presentation/screens/auto_bookkeeping_settings_screen.dart';

class IntegrationsSection extends ConsumerWidget {
  const IntegrationsSection({super.key});

  void _showNotionConfig(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (ctx) => const NotionConfigScreen()),
    );
  }

  void _showAutoBookkeepingConfig(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (ctx) => const AutoBookkeepingSettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsSection(
      title: 'INTEGRATIONS',
      children: [
        SettingsTile(
          icon: Icons.notifications_active_rounded,
          title: 'Auto Bookkeeping',
          subtitle: '刷卡與行動支付通知自動記帳',
          onTap: () => _showAutoBookkeepingConfig(context),
        ),
        SettingsTile(
          icon: Icons.sync_rounded,
          title: 'Notion Integration',
          subtitle: 'Sync new transactions to Notion',
          onTap: () => _showNotionConfig(context),
        ),
      ],
    );
  }
}
