import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/settings/providers/settings_notifier.dart';
import 'package:equity_tracker/features/settings/widgets/common/settings_section.dart';
import 'package:equity_tracker/features/settings/widgets/common/settings_tile.dart';
import 'package:equity_tracker/core/widgets/app_switch.dart';
import 'package:equity_tracker/features/settings/widgets/premium_currency_picker.dart';
import 'package:equity_tracker/core/notifications/providers/notification_providers.dart';

class PreferencesSection extends ConsumerWidget {
  const PreferencesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeModeAsync = ref.watch(settingsNotifierProvider);

    return SettingsSection(
      title: 'PREFERENCES',
      children: [
        SettingsTile(
          icon: Icons.dark_mode_rounded,
          title: 'Dark Mode',
          trailing: themeModeAsync.when(
            data: (settings) => AppSwitch(
              value: settings.themeMode == ThemeMode.dark,
              onChanged: (val) {
                ref
                    .read(settingsNotifierProvider.notifier)
                    .setThemeMode(
                      val ? ThemeMode.dark : ThemeMode.light,
                    );
                ref.read(inAppNotificationServiceProvider).showInfo(val ? 'Dark Mode Enabled' : 'Light Mode Enabled');
              },
            ),
            loading: () => const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (e, s) => const Icon(Icons.error, size: 20),
          ),
        ),
        SettingsTile(
          icon: Icons.security_rounded,
          title: 'Privacy Mode',
          subtitle: 'Hide balance on dashboard',
          trailing: themeModeAsync.when(
            data: (settings) => AppSwitch(
              value: settings.isPrivacyModeEnabled,
              onChanged: (val) {
                ref.read(settingsNotifierProvider.notifier).setPrivacyMode(val);
                ref.read(inAppNotificationServiceProvider).showInfo(val ? 'Privacy Mode Enabled' : 'Privacy Mode Disabled');
              },
            ),
            loading: () => const SizedBox(height: 0),
            error: (e, s) => const SizedBox(height: 0),
          ),
        ),
        SettingsTile(
          icon: Icons.currency_exchange,
          title: 'Currency Symbol',
          subtitle: themeModeAsync.when(
            data: (settings) => settings.currencySymbol,
            loading: () => '...',
            error: (e, s) => 'Error',
          ),
          onTap: () {
            if (themeModeAsync.hasValue) {
              _showCurrencyDialog(context, ref, themeModeAsync.value!.currencySymbol);
            }
          },
        ),
        SettingsTile(
          icon: Icons.notifications_active_rounded,
          title: 'Notification Logs',
          onTap: () {
            context.push('/logs/notifications');
          },
          trailing: themeModeAsync.when(
            data: (settings) => AppSwitch(
              value: settings.isNotificationLogEnabled,
              onChanged: (val) {
                ref.read(settingsNotifierProvider.notifier).setNotificationLogEnabled(val);
                ref.read(inAppNotificationServiceProvider).showInfo(
                  val ? 'Notification Logging Enabled' : 'Notification Logging Disabled',
                );
              },
            ),
            loading: () => const SizedBox(height: 0),
            error: (e, s) => const SizedBox(height: 0),
          ),
        ),
      ],
    );
  }

  void _showCurrencyDialog(BuildContext context, WidgetRef ref, String currentSymbol) {
    PremiumCurrencyPicker.show(
      context, 
      currentSymbol, 
      (sym) {
        ref.read(settingsNotifierProvider.notifier).setCurrencySymbol(sym);
        ref.read(inAppNotificationServiceProvider).showSuccess('Currency updated to \$sym');
      },
    );
  }
}
