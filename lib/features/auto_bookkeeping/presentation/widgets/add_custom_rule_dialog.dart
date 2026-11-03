import 'package:flutter/material.dart';
import 'package:equity_tracker/features/auto_bookkeeping/domain/models/notification_rule.dart';
import 'package:equity_tracker/features/auto_bookkeeping/data/default_notification_rules.dart';

class AddCustomRuleDialog extends StatefulWidget {
  final ValueChanged<NotificationRule> onRuleAdded;

  const AddCustomRuleDialog({
    super.key,
    required this.onRuleAdded,
  });

  @override
  State<AddCustomRuleDialog> createState() => _AddCustomRuleDialogState();
}

class _AddCustomRuleDialogState extends State<AddCustomRuleDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _titleKwCtrl;
  late final TextEditingController _txTitleCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _titleKwCtrl = TextEditingController();
    _txTitleCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _titleKwCtrl.dispose();
    _txTitleCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    final kwStr = _titleKwCtrl.text.trim();
    final txTitle = _txTitleCtrl.text.trim();

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
      packageNames: const [],
      titleKeywords: keywords,
      bodyKeywords: commonExpenseKeywords,
      negativeKeywords: commonNegativeKeywords,
      defaultTransactionTitle: txTitle,
      isSystemPreset: false,
    );

    widget.onRuleAdded(newRule);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('新增自訂記帳規則'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: '機構名稱',
                hintText: '例如：王道銀行、悠遊付',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleKwCtrl,
              decoration: const InputDecoration(
                labelText: '通知標題關鍵字',
                hintText: '例如：O-Bank (以逗號分隔)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _txTitleCtrl,
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
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('新增'),
        ),
      ],
    );
  }
}
