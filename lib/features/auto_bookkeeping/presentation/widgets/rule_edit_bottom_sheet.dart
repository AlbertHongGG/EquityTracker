import 'package:flutter/material.dart';
import 'package:equity_tracker/core/theme/app_colors.dart';
import 'package:equity_tracker/core/widgets/sheet/lens_wise_sheet_handle.dart';
import 'package:equity_tracker/features/category/data/category_model.dart';
import 'package:equity_tracker/features/auto_bookkeeping/domain/models/notification_rule.dart';
import 'package:equity_tracker/features/auto_bookkeeping/data/default_notification_rules.dart';
import 'package:equity_tracker/features/auto_bookkeeping/presentation/widgets/category_picker_sheet.dart';

/// 記帳規則新增/編輯底部抽屜 (RuleEditBottomSheet)
/// 1:1 復刻 LensWise 設計規範：
/// 1. Handle Bar：高度 32dp 置中，48 × 5dp 膠囊，半徑 2.5dp
/// 2. Header：左右對稱 (48dp Spacer + 13sp 字距 2.0 灰色大寫粗體置中標題 + 48dp 點擊區內置 32dp 深藍灰打勾確認圓鈕)
/// 3. 輸入框：圓角 12dp，細緻邊框，Label 樣式與色彩 100% 絕對統一
/// 4. 間距：水平 24dp、欄距 14dp、底部 32dp
/// 5. Placeholder：精簡重點，無括號雜訊，無截斷
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
      if (widget.initialRule == null && _txTitleCtrl.text.isEmpty && _nameCtrl.text.isNotEmpty) {
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

    final containerColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final secondaryTextColor = isDark
        ? Colors.white.withOpacity(0.54)
        : Colors.black.withOpacity(0.54);
    final unfocusedBorderColor = isDark
        ? Colors.white.withOpacity(0.15)
        : Colors.black.withOpacity(0.12);
    final focusedBorderColor = AppColors.primary;
    final checkButtonBgColor = isDark ? const Color(0xFF475569) : const Color(0xFF334155);

    // 統一的 Label 樣式：確保所有欄位（TextFormField 與 InputDecorator）標籤顏色完全一致
    final unifiedLabelColor = isDark ? Colors.white.withOpacity(0.70) : const Color(0xFF475569);
    final labelStyle = TextStyle(
      fontFamily: 'Outfit',
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: unifiedLabelColor,
    );
    final floatingLabelStyle = TextStyle(
      fontFamily: 'Outfit',
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: focusedBorderColor,
    );

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
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
              // 1. LensWise 頂部把手 (32dp 置中)
              LensWiseSheetHandle(isDark: isDark),

              // 2. LensWise Header 導航列 (1:1 左右平衡 + 13sp 字距 2.0 粗體置中標題 + 右側圓形確認鈕)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    const SizedBox(width: 48), // 左側 Spacer 嚴格平衡
                    Expanded(
                      child: Text(
                        (isEditing ? '編輯記帳規則' : '新增記帳規則').toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                          color: secondaryTextColor,
                        ),
                      ),
                    ),
                    // 右側確認按鈕 (直徑 32dp 深藍灰實心圓 + 白色 Checkmark)
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: Center(
                        child: GestureDetector(
                          onTap: _submit,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: checkButtonBgColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 3. 輸入欄位列表 (LensWise 規格：12dp 圓角、14dp 間隔、精簡無括號 Placeholder)
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24).copyWith(bottom: 32),
                  child: Column(
                    children: [
                      _buildLensWiseTextField(
                        controller: _nameCtrl,
                        label: '機構名稱',
                        hint: '例如：玉山銀行、LINE Pay',
                        textColor: textColor,
                        labelStyle: labelStyle,
                        floatingLabelStyle: floatingLabelStyle,
                        unfocusedBorderColor: unfocusedBorderColor,
                        focusedBorderColor: focusedBorderColor,
                        secondaryTextColor: secondaryTextColor,
                      ),
                      const SizedBox(height: 14),
                      _buildLensWiseTextField(
                        controller: _txTitleCtrl,
                        label: '入帳標題',
                        hint: '例如：玉山銀行刷卡',
                        textColor: textColor,
                        labelStyle: labelStyle,
                        floatingLabelStyle: floatingLabelStyle,
                        unfocusedBorderColor: unfocusedBorderColor,
                        focusedBorderColor: focusedBorderColor,
                        secondaryTextColor: secondaryTextColor,
                      ),
                      const SizedBox(height: 14),
                      // 指定支出分類選取器 (Label 樣式完全對齊)
                      _buildLensWiseCategorySelectorField(
                        label: '指定支出分類',
                        value: _getCategoryDisplayName(),
                        textColor: textColor,
                        labelStyle: labelStyle,
                        unfocusedBorderColor: unfocusedBorderColor,
                        secondaryTextColor: secondaryTextColor,
                        onTap: () {
                          CategoryPickerSheet.show(
                            context: context,
                            categories: widget.categories,
                            selectedCategoryId: _selectedCategoryId,
                            showDefaultOption: true,
                            title: '指定支出分類',
                            onCategorySelected: (catId) {
                              setState(() {
                                _selectedCategoryId = catId;
                              });
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      _buildLensWiseTextField(
                        controller: _titleKwCtrl,
                        label: '通知標題關鍵字',
                        hint: '例如：玉山, LINE 錢包',
                        textColor: textColor,
                        labelStyle: labelStyle,
                        floatingLabelStyle: floatingLabelStyle,
                        unfocusedBorderColor: unfocusedBorderColor,
                        focusedBorderColor: focusedBorderColor,
                        secondaryTextColor: secondaryTextColor,
                      ),
                      const SizedBox(height: 14),
                      _buildLensWiseTextField(
                        controller: _bodyKwCtrl,
                        label: '消費識別關鍵字',
                        hint: '例如：消費, 刷卡',
                        textColor: textColor,
                        labelStyle: labelStyle,
                        floatingLabelStyle: floatingLabelStyle,
                        unfocusedBorderColor: unfocusedBorderColor,
                        focusedBorderColor: focusedBorderColor,
                        secondaryTextColor: secondaryTextColor,
                      ),
                      const SizedBox(height: 14),
                      _buildLensWiseTextField(
                        controller: _negativeKwCtrl,
                        label: '排除關鍵字',
                        hint: '例如：驗證碼, 帳單',
                        textColor: textColor,
                        labelStyle: labelStyle,
                        floatingLabelStyle: floatingLabelStyle,
                        unfocusedBorderColor: unfocusedBorderColor,
                        focusedBorderColor: focusedBorderColor,
                        secondaryTextColor: secondaryTextColor,
                      ),
                      const SizedBox(height: 14),
                      _buildLensWiseTextField(
                        controller: _pkgCtrl,
                        label: 'App 套件名稱',
                        hint: '例如：com.esunbank',
                        textColor: textColor,
                        labelStyle: labelStyle,
                        floatingLabelStyle: floatingLabelStyle,
                        unfocusedBorderColor: unfocusedBorderColor,
                        focusedBorderColor: focusedBorderColor,
                        secondaryTextColor: secondaryTextColor,
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

  Widget _buildLensWiseTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required Color textColor,
    required TextStyle labelStyle,
    required TextStyle floatingLabelStyle,
    required Color unfocusedBorderColor,
    required Color focusedBorderColor,
    required Color secondaryTextColor,
  }) {
    return TextFormField(
      controller: controller,
      style: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: labelStyle,
        floatingLabelStyle: floatingLabelStyle,
        hintText: hint,
        hintStyle: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: secondaryTextColor.withOpacity(0.45),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: unfocusedBorderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: unfocusedBorderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: focusedBorderColor, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildLensWiseCategorySelectorField({
    required String label,
    required String value,
    required Color textColor,
    required TextStyle labelStyle,
    required Color unfocusedBorderColor,
    required Color secondaryTextColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: labelStyle,
          floatingLabelStyle: labelStyle,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: unfocusedBorderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: unfocusedBorderColor),
          ),
          suffixIcon: Icon(
            Icons.arrow_drop_down_rounded,
            size: 26,
            color: secondaryTextColor,
          ),
        ),
        child: Text(
          value,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
