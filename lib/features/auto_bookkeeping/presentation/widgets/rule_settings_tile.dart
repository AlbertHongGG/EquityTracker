import 'package:flutter/material.dart';
import 'package:equity_tracker/core/widgets/app_switch.dart';
import 'package:equity_tracker/features/auto_bookkeeping/domain/models/notification_rule.dart';

class RuleSettingsTile extends StatelessWidget {
  final NotificationRule rule;
  final ValueChanged<bool> onToggle;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const RuleSettingsTile({
    super.key,
    required this.rule,
    required this.onToggle,
    this.onDelete,
    this.onTap,
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Icon Bubble (對齊 SettingsTile 風格)
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: baseColor.withValues(alpha: 0.12),
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
            // Trailing Actions
            if (!rule.isSystemPreset && onDelete != null)
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                  size: 20,
                ),
                onPressed: onDelete,
                visualDensity: VisualDensity.compact,
              ),
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
