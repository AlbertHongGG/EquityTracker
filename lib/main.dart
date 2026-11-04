import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/settings/providers/settings_notifier.dart';
import 'package:equity_tracker/core/theme/app_theme.dart';
import 'package:equity_tracker/core/router/app_router.dart';
import 'package:equity_tracker/core/router/global_navigator.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:equity_tracker/core/providers/shared_prefs_provider.dart';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:equity_tracker/core/providers/package_info_provider.dart';
import 'package:equity_tracker/features/updater/data/github_updater_config.dart';
import 'package:equity_tracker/core/notifications/services/system_notification_service.dart';
import 'package:equity_tracker/core/notifications/providers/notification_providers.dart';
import 'package:equity_tracker/core/notifications/presentation/global_notification_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPreferences = await SharedPreferences.getInstance();
  final packageInfo = await PackageInfo.fromPlatform();
  
  final systemNotificationService = SystemNotificationServiceImpl();
  await systemNotificationService.init();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        packageInfoProvider.overrideWithValue(packageInfo),
        githubUpdaterConfigProvider.overrideWithValue(
          const GithubUpdaterConfig(
            githubOwner: 'JasonHongGG',
            githubRepo: 'EquityTracker',
            downloadFileName: 'EquityTracker_update.apk',
          ),
        ),
        systemNotificationServiceProvider.overrideWithValue(systemNotificationService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsNotifierProvider);
    final themeMode = settingsAsync.value?.themeMode ?? ThemeMode.system;
    final goRouter = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'EquityTracker',
      scaffoldMessengerKey: scaffoldMessengerKey,
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: goRouter,
      builder: (context, child) => GlobalNotificationOverlay(child: child),
      debugShowCheckedModeBanner: false,
    );
  }
}
