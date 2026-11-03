import 'package:flutter/material.dart';

class CustomSimulateDialog extends StatefulWidget {
  final void Function(String title, String body) onSimulate;

  const CustomSimulateDialog({
    super.key,
    required this.onSimulate,
  });

  @override
  State<CustomSimulateDialog> createState() => _CustomSimulateDialogState();
}

class _CustomSimulateDialogState extends State<CustomSimulateDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _bodyCtrl;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: '玉山銀行');
    _bodyCtrl = TextEditingController(text: '信用卡消費160元通知');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('自訂通知模擬測試'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: '通知標題 (Title)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bodyCtrl,
            decoration: const InputDecoration(labelText: '通知內文 (Body)'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            final title = _titleCtrl.text.trim();
            final body = _bodyCtrl.text.trim();
            if (title.isNotEmpty && body.isNotEmpty) {
              widget.onSimulate(title, body);
              Navigator.pop(context);
            }
          },
          child: const Text('發送模擬通知'),
        ),
      ],
    );
  }
}
