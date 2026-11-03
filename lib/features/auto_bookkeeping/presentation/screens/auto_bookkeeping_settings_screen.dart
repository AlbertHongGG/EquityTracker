import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:equity_tracker/core/theme/app_colors.dart';
import 'package:equity_tracker/core/widgets/immersive_scaffold.dart';
import 'package:equity_tracker/core/widgets/premium_config_header.dart';
import 'package:equity_tracker/core/widgets/app_switch.dart';
import 'package:equity_tracker/core/widgets/scale_button.dart';
import 'package:equity_tracker/core/notifications/providers/notification_providers.dart';
import 'package:equity_tracker/features/auto_bookkeeping/domain/models/notification_rule.dart';
import 'package:equity_tracker/features/auto_bookkeeping/domain/models/parsed_notification.dart';
import 'package:equity_tracker/features/auto_bookkeeping/presentation/providers/auto_bookkeeping_notifier.dart';
import 'package:equity_tracker/features/category/providers/category_notifier.dart';
import 'package:equity_tracker/core/enums/transaction_type.dart';

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
          final categories = (categoriesAsync.value ?? [])
              .where((c) => c.type == TransactionType.expense && c.isEnabled)
              .toList();

          final defaultCatName = categories
              .firstWhere(
                (c) => c.id == state.defaultCategoryId,
                orElse: () => categories.firstWhere(
                  (c) => c.name == '信用卡',
                  orElse: () => categories.firstWhere(
                    (c) => c.name == '其他',
                    orElse: () => categories.isNotEmpty
                        ? categories.first
                        : throw Exception(),
                  ),
                ),
              )
              .name;

          return ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              // Header
              PremiumConfigHeader(
                title: 'Auto Bookkeeping',
                subtitle: 'NOTIFICATION PARSING & RULES',
                trailing: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),

              // 1. 權限狀態卡片
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: _buildPermissionCard(
                  context,
                  state.isPermissionGranted,
                  isDark,
                ),
              ),

              // 2. 主設定卡片 (全域開關、成功通知、預設分類)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: _buildMainConfigCard(
                  context,
                  state,
                  defaultCatName,
                  categories,
                  isDark,
                ),
              ),

              // 3. 🧪 模擬測試區 (Simulator)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: _buildSimulatorCard(context, isDark),
              ),

              // 4. 支援之銀行與支付機構清單
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
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
                          onPressed: () => _showAddRuleDialog(context),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('自訂規則'),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded, size: 20),
                          onSelected: (val) {
                            if (val == 'reset') {
                              ref
                                  .read(
                                    autoBookkeepingNotifierProvider.notifier,
                                  )
                                  .resetRules();
                              ref
                                  .read(inAppNotificationServiceProvider)
                                  .showSuccess('已恢復預設規則清單');
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
                  children: state.rules
                      .map((rule) => _buildRuleItem(context, rule, isDark))
                      .toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPermissionCard(
    BuildContext context,
    bool isGranted,
    bool isDark,
  ) {
    if (isGranted) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '通知存取權：已授權',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Android 原生管線已就緒，即使 App 關閉亦能秒級記帳',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '尚未授權「通知存取權」',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.orange,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Android 系統需要您手動開啟權限，才能在收到刷卡通知時自動記帳。',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  ref
                      .read(autoBookkeepingNotifierProvider.notifier)
                      .openPermissionSettings();
                },
                icon: const Icon(Icons.settings_outlined, size: 18),
                label: const Text(
                  '前往系統設定開啟權限',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildMainConfigCard(
    BuildContext context,
    AutoBookkeepingState state,
    String defaultCatName,
    List<dynamic> categories,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        children: [
          // 總開關
          ListTile(
            title: const Text(
              '啟用自動記帳',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text('收到相符通知時，於本地原生秒級新增消費紀錄'),
            trailing: AppSwitch(
              value: state.isEnabled,
              onChanged: (val) {
                ref
                    .read(autoBookkeepingNotifierProvider.notifier)
                    .toggleEnabled(val);
              },
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          // 成功通知
          ListTile(
            title: const Text(
              '記帳成功推播通知',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text('自動記帳後發出推播，點擊可直接打開並修改分類'),
            trailing: AppSwitch(
              value: state.notifyOnSuccess,
              onChanged: (val) {
                ref
                    .read(autoBookkeepingNotifierProvider.notifier)
                    .toggleNotifyOnSuccess(val);
              },
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          // 預設分類選擇
          ListTile(
            title: const Text(
              '預設支出分類',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text('未指定分類之刷卡一律歸類至「$defaultCatName」'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  defaultCatName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded, color: Colors.grey),
              ],
            ),
            onTap: () => _showCategoryPicker(context, categories),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulatorCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  Colors.indigo.shade900.withValues(alpha: 0.4),
                  Colors.blueGrey.shade900.withValues(alpha: 0.3),
                ]
              : [Colors.indigo.shade50, Colors.blue.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.indigo.withValues(alpha: isDark ? 0.3 : 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.science_rounded,
                color: Colors.indigoAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                '🧪 模擬刷卡通知測試',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.indigoAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '原生直通測試',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.indigoAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            '點擊下方按鈕將直接觸發 Android 原生入帳管線與系統推播：',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ScaleButton(
                onTap: () {
                  _simulatePreset(
                    packageName: 'com.esunbank',
                    title: '玉山銀行',
                    body: '信用卡消費160元通知',
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.indigo.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.credit_card_rounded,
                        size: 16,
                        color: Colors.green,
                      ),
                      SizedBox(width: 6),
                      Text(
                        '玉山銀行 160元',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ScaleButton(
                onTap: () {
                  _simulatePreset(
                    packageName: 'jp.naver.line.android',
                    title: 'LINE Pay',
                    body: '您已於 50嵐 付款完成 NT\$ 250 元',
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.indigo.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FaIcon(
                        FontAwesomeIcons.line,
                        size: 14,
                        color: Colors.green,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'LINE Pay 250元',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ScaleButton(
                onTap: () => _showCustomSimulateDialog(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.indigo.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit_note_rounded,
                        size: 16,
                        color: Colors.indigoAccent,
                      ),
                      SizedBox(width: 6),
                      Text(
                        '自訂通知內文...',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRuleItem(
    BuildContext context,
    NotificationRule rule,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: rule.isEnabled
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
                : Colors.grey.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.account_balance_wallet_rounded,
            color: rule.isEnabled
                ? Theme.of(context).colorScheme.primary
                : Colors.grey,
            size: 20,
          ),
        ),
        title: Text(
          rule.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: rule.isEnabled ? null : Colors.grey,
          ),
        ),
        subtitle: Text(
          '入帳標題：${rule.defaultTransactionTitle}',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!rule.isSystemPreset)
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                  size: 20,
                ),
                onPressed: () {
                  ref
                      .read(autoBookkeepingNotifierProvider.notifier)
                      .deleteRule(rule.id);
                },
              ),
            AppSwitch(
              value: rule.isEnabled,
              onChanged: (val) {
                ref
                    .read(autoBookkeepingNotifierProvider.notifier)
                    .toggleRule(rule.id, val);
              },
            ),
          ],
        ),
      ),
    );
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

  void _showCategoryPicker(BuildContext context, List<dynamic> categories) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '選擇預設支出分類',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (ctx, index) {
                    final cat = categories[index];
                    return ListTile(
                      title: Text(cat.name),
                      onTap: () {
                        ref
                            .read(autoBookkeepingNotifierProvider.notifier)
                            .setDefaultCategoryId(cat.id);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddRuleDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final titleKwCtrl = TextEditingController();
    final txTitleCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('新增自訂記帳規則'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: '機構名稱',
                    hintText: '例如：銀行、悠遊付',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleKwCtrl,
                  decoration: const InputDecoration(
                    labelText: '通知標題關鍵字',
                    hintText: '例如：O-Bank (以逗號分隔)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: txTitleCtrl,
                  decoration: const InputDecoration(
                    labelText: '自動記帳標題',
                    hintText: '例如：王道銀行刷卡',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                final kwStr = titleKwCtrl.text.trim();
                final txTitle = txTitleCtrl.text.trim();

                if (name.isEmpty || kwStr.isEmpty || txTitle.isEmpty) {
                  return;
                }

                final keywords = kwStr
                    .split(RegExp(r'[,，]'))
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList();

                final newRule = NotificationRule(
                  id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                  packageNames: [],
                  titleKeywords: keywords,
                  bodyKeywords: const ['消費', '刷卡', '付款', '支付', 'NT\$', '元'],
                  negativeKeywords: const ['驗證碼', 'OTP', '帳單', '失敗', '退款'],
                  defaultTransactionTitle: txTitle,
                  isSystemPreset: false,
                );

                ref
                    .read(autoBookkeepingNotifierProvider.notifier)
                    .saveRule(newRule);
                Navigator.pop(ctx);
                ref
                    .read(inAppNotificationServiceProvider)
                    .showSuccess('已新增「$name」規則');
              },
              child: const Text('新增'),
            ),
          ],
        );
      },
    );
  }

  void _showCustomSimulateDialog(BuildContext context) {
    final titleCtrl = TextEditingController(text: '玉山銀行');
    final bodyCtrl = TextEditingController(text: '信用卡消費160元通知');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('自訂通知模擬測試'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: '通知標題 (Title)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bodyCtrl,
                decoration: const InputDecoration(labelText: '通知內文 (Body)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                final title = titleCtrl.text.trim();
                final body = bodyCtrl.text.trim();
                if (title.isNotEmpty && body.isNotEmpty) {
                  _simulatePreset(
                    packageName: 'com.test.simulator',
                    title: title,
                    body: body,
                  );
                  Navigator.pop(ctx);
                }
              },
              child: const Text('發送模擬通知'),
            ),
          ],
        );
      },
    );
  }
}
