import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/core/widgets/immersive_scaffold.dart';
import 'package:equity_tracker/core/widgets/premium_config_header.dart';
import 'package:equity_tracker/core/notifications/providers/notification_providers.dart';
import 'package:equity_tracker/core/enums/transaction_type.dart';
import 'package:equity_tracker/features/category/providers/category_notifier.dart';
import 'package:equity_tracker/features/auto_bookkeeping/domain/models/raw_notification_data.dart';
import 'package:equity_tracker/features/auto_bookkeeping/presentation/providers/auto_bookkeeping_notifier.dart';
import 'package:equity_tracker/features/auto_bookkeeping/presentation/widgets/permission_status_card.dart';
import 'package:equity_tracker/features/auto_bookkeeping/presentation/widgets/auto_bookkeeping_config_card.dart';
import 'package:equity_tracker/features/auto_bookkeeping/presentation/widgets/notification_simulator_card.dart';
import 'package:equity_tracker/features/auto_bookkeeping/presentation/widgets/notification_rule_tile.dart';
import 'package:equity_tracker/features/auto_bookkeeping/presentation/widgets/add_custom_rule_dialog.dart';
import 'package:equity_tracker/features/auto_bookkeeping/presentation/widgets/custom_simulate_dialog.dart';

class AutoBookkeepingSettingsScreen extends ConsumerStatefulWidget {
  const AutoBookkeepingSettingsScreen({super.key});

  @override
  ConsumerState<AutoBookkeepingSettingsScreen> createState() =>
      _AutoBookkeepingSettingsScreenState();
}

class _AutoBookkeepingSettingsScreenState
    extends ConsumerState<AutoBookkeepingSettingsScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() {
      ref.read(autoBookkeepingNotifierProvider.notifier).checkPermission();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(autoBookkeepingNotifierProvider.notifier).checkPermission();
    }
  }

  void _simulatePreset({
    required String packageName,
    required String title,
    required String body,
  }) async {
    final raw = RawNotificationData(
      packageName: packageName,
      title: title,
      body: body,
      timestamp: DateTime.now(),
    );
    final success = await ref
        .read(autoBookkeepingNotifierProvider.notifier)
        .simulateNotification(raw);
    if (success) {
      ref
          .read(inAppNotificationServiceProvider)
          .showSuccess('原生管線成功解析並入帳：「$title - $body」');
    } else {
      ref
          .read(inAppNotificationServiceProvider)
          .showWarning('通知未命中任何啟用中規則，或為重複通知');
    }
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(autoBookkeepingNotifierProvider);
    final categoriesAsync = ref.watch(categoryListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ImmersiveScaffold(
      body: stateAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('載入失敗: $e')),
        data: (state) {
          final expenseCategories = (categoriesAsync.value ?? [])
              .where((c) => c.type == TransactionType.expense && c.isEnabled)
              .toList();

          return ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              PremiumConfigHeader(
                title: 'Auto Bookkeeping',
                subtitle: 'NOTIFICATION PARSING & RULES',
                trailing: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              // 1. 權限卡片
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: PermissionStatusCard(
                  isGranted: state.isPermissionGranted,
                  isDark: isDark,
                  onOpenSettings: () {
                    ref.read(autoBookkeepingNotifierProvider.notifier).openPermissionSettings();
                  },
                ),
              ),
              // 2. 主設定卡片
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: AutoBookkeepingConfigCard(
                  isEnabled: state.isEnabled,
                  notifyOnSuccess: state.notifyOnSuccess,
                  defaultCategoryId: state.defaultCategoryId,
                  categories: expenseCategories,
                  isDark: isDark,
                  onToggleEnabled: (val) {
                    ref.read(autoBookkeepingNotifierProvider.notifier).toggleEnabled(val);
                  },
                  onToggleNotifyOnSuccess: (val) {
                    ref.read(autoBookkeepingNotifierProvider.notifier).toggleNotifyOnSuccess(val);
                  },
                  onSelectDefaultCategory: (id) {
                    ref.read(autoBookkeepingNotifierProvider.notifier).setDefaultCategoryId(id);
                  },
                ),
              ),
              // 3. 模擬測試區
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: NotificationSimulatorCard(
                  isDark: isDark,
                  onSimulatePreset: _simulatePreset,
                  onOpenCustomDialog: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => CustomSimulateDialog(
                        onSimulate: (title, body) {
                          _simulatePreset(
                            packageName: 'com.test.simulator',
                            title: title,
                            body: body,
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              // 4. 支援機構與規則清單
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '支援機構與規則 (${state.rules.length})',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AddCustomRuleDialog(
                                onRuleAdded: (rule) {
                                  ref.read(autoBookkeepingNotifierProvider.notifier).saveRule(rule);
                                  ref.read(inAppNotificationServiceProvider).showSuccess('已新增「${rule.name}」規則');
                                },
                              ),
                            );
                          },
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('自訂規則'),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded, size: 20),
                          onSelected: (val) {
                            if (val == 'reset') {
                              ref.read(autoBookkeepingNotifierProvider.notifier).resetRules();
                              ref.read(inAppNotificationServiceProvider).showSuccess('已恢復預設規則清單');
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(
                              value: 'reset',
                              child: Text('恢復預設規則'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: state.rules.map((rule) {
                    return NotificationRuleTile(
                      rule: rule,
                      isDark: isDark,
                      onToggle: (val) {
                        ref.read(autoBookkeepingNotifierProvider.notifier).toggleRule(rule.id, val);
                      },
                      onDelete: rule.isSystemPreset
                          ? null
                          : () {
                              ref.read(autoBookkeepingNotifierProvider.notifier).deleteRule(rule.id);
                            },
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
