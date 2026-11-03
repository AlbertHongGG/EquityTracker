import 'package:flutter/material.dart';
import 'package:equity_tracker/core/widgets/app_switch.dart';
import 'package:equity_tracker/features/auto_bookkeeping/domain/models/notification_rule.dart';

/// 記帳規則列表項目 (RuleSettingsTile)
/// - 右側純粹保留開關 (AppSwitch)，無任何垃圾桶按鈕
/// - 支援長按 (onLongPress) 觸發滑動刪除抽屜
/// - 支援點擊 (onTap) 編輯規則
class RuleSettingsTile extends StatelessWidget {
  final NotificationRule rule;
  final ValueChanged<bool> onToggle;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const RuleSettingsTile({
    super.key,
    required this.rule,
    required this.onToggle,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final baseColor = rule.isEnabled
        ? theme.colorScheme.primary
        : (isDark ? Colors.white38 : Colors.grey.shade400);

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Icon Bubble
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: baseColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.credit_card_rounded,
                color: baseColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    rule.name,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: rule.isEnabled
                          ? (isDark ? Colors.white : const Color(0xFF1A1D2B))
                          : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '入帳標題：${rule.defaultTransactionTitle}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            // Trailing Switch (無垃圾桶按鈕，簡約俐落)
            AppSwitch(
              value: rule.isEnabled,
              onChanged: onToggle,
            ),
          ],
        ),
      ),
    );
  }
}
