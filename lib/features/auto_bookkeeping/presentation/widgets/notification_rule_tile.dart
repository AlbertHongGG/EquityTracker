import 'package:flutter/material.dart';
import 'package:equity_tracker/core/theme/app_colors.dart';
import 'package:equity_tracker/core/widgets/app_switch.dart';
import 'package:equity_tracker/features/auto_bookkeeping/domain/models/notification_rule.dart';

class NotificationRuleTile extends StatelessWidget {
  final NotificationRule rule;
  final bool isDark;
  final ValueChanged<bool> onToggle;
  final VoidCallback? onDelete;

  const NotificationRuleTile({
    super.key,
    required this.rule,
    required this.isDark,
    required this.onToggle,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
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
            if (!rule.isSystemPreset && onDelete != null)
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                  size: 20,
                ),
                onPressed: onDelete,
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
