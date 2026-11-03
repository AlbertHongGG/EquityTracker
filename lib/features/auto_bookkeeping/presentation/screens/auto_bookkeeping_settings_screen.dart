import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/core/widgets/immersive_scaffold.dart';
import 'package:equity_tracker/core/widgets/premium_config_header.dart';
import 'package:equity_tracker/core/widgets/app_switch.dart';
import 'package:equity_tracker/core/notifications/providers/notification_providers.dart';
import 'package:equity_tracker/core/enums/transaction_type.dart';
import 'package:equity_tracker/features/settings/widgets/common/settings_section.dart';
import 'package:equity_tracker/features/settings/widgets/common/settings_tile.dart';
import 'package:equity_tracker/features/category/providers/category_notifier.dart';
import 'package:equity_tracker/features/category/data/category_model.dart';
import 'package:equity_tracker/features/auto_bookkeeping/domain/models/notification_rule.dart';
import 'package:equity_tracker/features/auto_bookkeeping/presentation/providers/auto_bookkeeping_notifier.dart';
import 'package:equity_tracker/core/widgets/sheet/swipe_to_confirm_drawer.dart';
import 'package:equity_tracker/features/auto_bookkeeping/presentation/widgets/category_picker_sheet.dart';
import 'package:equity_tracker/features/auto_bookkeeping/presentation/widgets/rule_settings_tile.dart';
import 'package:equity_tracker/features/auto_bookkeeping/presentation/widgets/rule_edit_bottom_sheet.dart';

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

  String _resolveDefaultCategoryName(
    List<CategoryModel> categories,
    String? defaultCategoryId,
  ) {
    if (categories.isEmpty) return '信用卡';

    if (defaultCategoryId != null) {
      final matched = categories.where((c) => c.id == defaultCategoryId);
      if (matched.isNotEmpty) return matched.first.name;
    }

    final creditCard = categories.where((c) => c.name == '信用卡');
    if (creditCard.isNotEmpty) return creditCard.first.name;

    final other = categories.where((c) => c.name == '其他');
    if (other.isNotEmpty) return other.first.name;

    return categories.first.name;
  }

  void _openRuleEditor(
    BuildContext context,
    List<CategoryModel> categories, [
    NotificationRule? initialRule,
  ]) {
    RuleEditBottomSheet.show(
      context: context,
      initialRule: initialRule,
      categories: categories,
      onSave: (rule) {
        ref.read(autoBookkeepingNotifierProvider.notifier).saveRule(rule);
        ref.read(inAppNotificationServiceProvider).showSuccess(
              initialRule != null ? '已更新「${rule.name}」規則' : '已新增「${rule.name}」規則',
            );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(autoBookkeepingNotifierProvider);
    final categoriesAsync = ref.watch(categoryListProvider);
    final theme = Theme.of(context);

    return ImmersiveScaffold(
      body: stateAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('載入失敗: $e')),
        data: (state) {
          final expenseCategories = (categoriesAsync.value ?? [])
              .where((c) => c.type == TransactionType.expense && c.isEnabled)
              .toList();

          final defaultCatName = _resolveDefaultCategoryName(
            expenseCategories,
            state.defaultCategoryId,
          );

          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              // Header (無上一頁按鈕，依循 App 右滑返回規範)
              const PremiumConfigHeader(
                title: 'Auto\nBookkeeping',
                subtitle: 'NOTIFICATION RECOGNITION',
              ),

              // Section 1: 一般設定 (精簡副標題，預設支出分類無贅言副標)
              SettingsSection(
                title: 'GENERAL',
                children: [
                  SettingsTile(
                    icon: Icons.bolt_rounded,
                    iconColor: Colors.amber.shade700,
                    title: '自動記帳',
                    subtitle: '偵測推播自動記帳',
                    trailing: AppSwitch(
                      value: state.isEnabled,
                      onChanged: (val) async {
                        if (val && !state.isPermissionGranted) {
                          await ref
                              .read(autoBookkeepingNotifierProvider.notifier)
                              .openPermissionSettings();
                          ref
                              .read(inAppNotificationServiceProvider)
                              .showWarning('請在系統設定中開啟通知存取權限以啟用自動記帳');
                        } else {
                          ref
                              .read(autoBookkeepingNotifierProvider.notifier)
                              .toggleEnabled(val);
                        }
                      },
                    ),
                  ),
                  SettingsTile(
                    icon: Icons.notifications_none_rounded,
                    title: '記帳成功通知',
                    subtitle: '入帳發送推播',
                    trailing: AppSwitch(
                      value: state.notifyOnSuccess,
                      onChanged: (val) {
                        ref
                            .read(autoBookkeepingNotifierProvider.notifier)
                            .toggleNotifyOnSuccess(val);
                      },
                    ),
                  ),
                  SettingsTile(
                    icon: Icons.credit_card_rounded,
                    iconColor: Colors.orange,
                    title: '預設支出分類',
                    subtitle: null, // 移除兩行冗贅副標，畫面極致清爽
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          defaultCatName,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ],
                    ),
                    onTap: () {
                      CategoryPickerSheet.show(
                        context: context,
                        categories: expenseCategories,
                        selectedCategoryId: state.defaultCategoryId,
                        title: '預設支出分類',
                        onCategorySelected: (catId) {
                          ref
                              .read(autoBookkeepingNotifierProvider.notifier)
                              .setDefaultCategoryId(catId);
                        },
                      );
                    },
                  ),
                ],
              ),

              // Section 2: 支援機構與規則清單 (無三點按鈕，僅保留「+ 自訂規則」)
              SettingsSection(
                title: 'RULES & INSTITUTIONS',
                trailing: GestureDetector(
                  onTap: () => _openRuleEditor(context, expenseCategories),
                  child: Text(
                    '+ 自訂規則',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                children: state.rules.map((rule) {
                  return RuleSettingsTile(
                    rule: rule,
                    onTap: () => _openRuleEditor(context, expenseCategories, rule),
                    onLongPress: () {
                      SwipeToConfirmDrawer.show(
                        context: context,
                        title: 'CLEAR ${rule.name} RULE',
                        onConfirm: () {
                          ref
                              .read(autoBookkeepingNotifierProvider.notifier)
                              .deleteRule(rule.id);
                        },
                      );
                    },
                    onToggle: (val) {
                      ref
                          .read(autoBookkeepingNotifierProvider.notifier)
                          .toggleRule(rule.id, val);
                    },
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}
