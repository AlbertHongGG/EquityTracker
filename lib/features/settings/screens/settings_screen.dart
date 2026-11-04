import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/core/widgets/premium_config_header.dart';
import 'package:equity_tracker/core/widgets/immersive_scaffold.dart';

import 'package:equity_tracker/features/settings/screens/settings_screen/preferences_section.dart';
import 'package:equity_tracker/features/settings/providers/settings_notifier.dart';
import 'package:equity_tracker/features/data_management/widgets/data_management_section.dart';
import 'package:equity_tracker/features/data_management/widgets/integrations_section.dart';
import 'package:equity_tracker/features/data_management/widgets/danger_zone_section.dart';
import 'package:equity_tracker/features/updater/presentation/widgets/app_update_section.dart';
import 'package:equity_tracker/features/ai/presentation/screens/ai_settings_screen.dart';
import 'package:equity_tracker/core/widgets/app_switch.dart';
import 'package:equity_tracker/core/notifications/providers/notification_providers.dart';
import 'package:equity_tracker/features/settings/widgets/common/settings_section.dart';
import 'package:equity_tracker/features/settings/widgets/common/settings_tile.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ImmersiveScaffold(
      body: ListView(
        padding: const EdgeInsets.only(bottom: 20),
        children: [
          const PremiumConfigHeader(
            title: 'Settings',
            subtitle: 'PREFERENCES & SYSTEM CONFIG',
          ),
          const PreferencesSection(),
          SettingsSection(
            title: 'AI ASSISTANT',
            children: [
              SettingsTile(
                icon: Icons.smart_toy_rounded,
                title: 'AI Configuration',
                subtitle: 'Manage API keys and models',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AiSettingsScreen(),
                    ),
                  );
                },
              ),
              SettingsTile(
                icon: Icons.terminal_rounded,
                title: 'API & AI Logs',
                onTap: () {
                  context.push('/logs/api');
                },
                trailing: ref.watch(settingsNotifierProvider).when(
                  data: (settings) => AppSwitch(
                    value: settings.isApiLogEnabled,
                    onChanged: (val) {
                      ref.read(settingsNotifierProvider.notifier).setApiLogEnabled(val);
                      ref.read(inAppNotificationServiceProvider).showInfo(
                        val ? 'API & AI Logging Enabled' : 'API & AI Logging Disabled',
                      );
                    },
                  ),
                  loading: () => const SizedBox(height: 0),
                  error: (e, s) => const SizedBox(height: 0),
                ),
              ),
            ],
          ),
          const DataManagementSection(),
          IntegrationsSection(), // Contains Notion Sync & Import
          DangerZoneSection(),
          AppUpdateSection(),
        ],
      ),
    );
  }
}
