import 'package:flutter/material.dart';
import 'package:equity_tracker/features/category/data/category_model.dart';
import 'package:equity_tracker/features/auto_bookkeeping/domain/models/notification_rule.dart';
import 'package:equity_tracker/features/auto_bookkeeping/data/default_notification_rules.dart';
import 'package:equity_tracker/features/auto_bookkeeping/presentation/widgets/category_picker_sheet.dart';

class RuleEditBottomSheet extends StatefulWidget {
  final NotificationRule? initialRule;
  final List<CategoryModel> categories;
  final ValueChanged<NotificationRule> onSave;

  const RuleEditBottomSheet({
    super.key,
    this.initialRule,
    required this.categories,
    required this.onSave,
  });

  static Future<void> show({
    required BuildContext context,
    NotificationRule? initialRule,
    required List<CategoryModel> categories,
    required ValueChanged<NotificationRule> onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => RuleEditBottomSheet(
        initialRule: initialRule,
        categories: categories,
        onSave: onSave,
      ),
    );
  }

  @override
  State<RuleEditBottomSheet> createState() => _RuleEditBottomSheetState();
}

class _RuleEditBottomSheetState extends State<RuleEditBottomSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _txTitleCtrl;
  late final TextEditingController _titleKwCtrl;
  late final TextEditingController _bodyKwCtrl;
  late final TextEditingController _negativeKwCtrl;
  late final TextEditingController _pkgCtrl;
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    final rule = widget.initialRule;

    _nameCtrl = TextEditingController(text: rule?.name ?? '');
    _txTitleCtrl = TextEditingController(text: rule?.defaultTransactionTitle ?? '');
    _titleKwCtrl = TextEditingController(text: rule?.titleKeywords.join(', ') ?? '');
    _bodyKwCtrl = TextEditingController(
      text: rule != null
          ? rule.bodyKeywords.join(', ')
          : commonExpenseKeywords.join(', '),
    );
    _negativeKwCtrl = TextEditingController(
      text: rule != null
          ? rule.negativeKeywords.join(', ')
          : commonNegativeKeywords.join(', '),
    );
    _pkgCtrl = TextEditingController(text: rule?.packageNames.join(', ') ?? '');
    _selectedCategoryId = rule?.defaultCategoryId;

    // 當機構名稱改變且入帳標題為空時，自動輔助填寫
    _nameCtrl.addListener(() {
      if (rule == null && _txTitleCtrl.text.isEmpty && _nameCtrl.text.isNotEmpty) {
        _txTitleCtrl.text = '${_nameCtrl.text}刷卡';
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _txTitleCtrl.dispose();
    _titleKwCtrl.dispose();
    _bodyKwCtrl.dispose();
    _negativeKwCtrl.dispose();
    _pkgCtrl.dispose();
    super.dispose();
  }

  List<String> _splitKeywords(String text) {
    return text
        .split(RegExp(r'[,，]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    final txTitle = _txTitleCtrl.text.trim();
    final titleKw = _splitKeywords(_titleKwCtrl.text);

    if (name.isEmpty || txTitle.isEmpty || titleKw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('請填寫機構名稱、入帳標題與至少一個標題關鍵字'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final bodyKw = _splitKeywords(_bodyKwCtrl.text);
    final negativeKw = _splitKeywords(_negativeKwCtrl.text);
    final pkgNames = _splitKeywords(_pkgCtrl.text);

    final rule = NotificationRule(
      id: widget.initialRule?.id ?? 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      packageNames: pkgNames,
      titleKeywords: titleKw,
      bodyKeywords: bodyKw.isNotEmpty ? bodyKw : commonExpenseKeywords,
      negativeKeywords: negativeKw.isNotEmpty ? negativeKw : commonNegativeKeywords,
      defaultTransactionTitle: txTitle,
      defaultCategoryId: _selectedCategoryId,
      isEnabled: widget.initialRule?.isEnabled ?? true,
      isSystemPreset: widget.initialRule?.isSystemPreset ?? false,
    );

    widget.onSave(rule);
    Navigator.pop(context);
  }

  String _getCategoryDisplayName() {
    if (_selectedCategoryId == null) return '跟隨全域預設';
    final found = widget.categories.where((c) => c.id == _selectedCategoryId);
    return found.isNotEmpty ? found.first.name : '跟隨全域預設';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEditing = widget.initialRule != null;

    final borderColor = isDark ? Colors.white24 : const Color(0xFFE2E8F0);
    final focusedBorderColor = theme.colorScheme.primary;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              // Handle Bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              // Header Row (對齊圖四：標題置中，右上角深色圓形打勾按鈕，無取消按鈕)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const SizedBox(width: 40), // 對齊平衡
                    Expanded(
                      child: Text(
                        isEditing ? '編輯記帳規則' : '新增記帳規則',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF1A1D2B),
                        ),
                      ),
                    ),
                    // 右上角圓形確認按鈕（圖四配色與樣式）
                    GestureDetector(
                      onTap: _submit,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFF2D3748),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Form Fields (圖四 Outlined 浮動標籤樣式)
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _nameCtrl,
                        label: '機構名稱',
                        hint: '例如：王道銀行、悠遊付',
                        borderColor: borderColor,
                        focusedBorderColor: focusedBorderColor,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _txTitleCtrl,
                        label: '入帳標題',
                        hint: '例如：王道銀行刷卡',
                        borderColor: borderColor,
                        focusedBorderColor: focusedBorderColor,
                      ),
                      const SizedBox(height: 16),
                      // 指定分類選擇框
                      _buildCategorySelectorField(
                        label: '指定支出分類',
                        value: _getCategoryDisplayName(),
                        borderColor: borderColor,
                        onTap: () {
                          CategoryPickerSheet.show(
                            context: context,
                            categories: widget.categories,
                            selectedCategoryId: _selectedCategoryId,
                            showDefaultOption: true,
                            title: '指定此規則之支出分類',
                            onCategorySelected: (catId) {
                              setState(() {
                                _selectedCategoryId = catId;
                              });
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _titleKwCtrl,
                        label: '通知標題關鍵字',
                        hint: '例如：O-Bank, 王道 (逗號分隔)',
                        borderColor: borderColor,
                        focusedBorderColor: focusedBorderColor,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _bodyKwCtrl,
                        label: '消費識別關鍵字',
                        hint: '例如：消費, 刷卡, 付款, NT\$, 元',
                        borderColor: borderColor,
                        focusedBorderColor: focusedBorderColor,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _negativeKwCtrl,
                        label: '排除關鍵字',
                        hint: '例如：驗證碼, OTP, 帳單, 失敗',
                        borderColor: borderColor,
                        focusedBorderColor: focusedBorderColor,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _pkgCtrl,
                        label: 'App 套件名稱 (選填)',
                        hint: '例如：com.obank.mobile (留空純依標題比對)',
                        borderColor: borderColor,
                        focusedBorderColor: focusedBorderColor,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required Color borderColor,
    required Color focusedBorderColor,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.normal),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: focusedBorderColor, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildCategorySelectorField({
    required String label,
    required String value,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: borderColor),
          ),
          suffixIcon: const Icon(Icons.arrow_drop_down_rounded, size: 28),
        ),
        child: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
    );
  }
}
