import 'package:flutter/material.dart';
import 'package:equity_tracker/core/widgets/sheet/lens_wise_sheet_handle.dart';

/// 通用權限請求下拉式抽屜 (PermissionRequestSheet)
///
/// 遵循 LensWise 設計規範：
/// 1. Handle Bar：高度 32dp 置中，48 × 5dp 膠囊，半徑 2.5dp (LensWiseSheetHandle)
/// 2. Header：左右對稱 (48dp Spacer + 13sp 字距 2.0 灰色大寫粗體置中標題 + 48dp Spacer)
/// 3. 主 Icon 設計：72 × 72dp 圓形柔光容器，搭配 34dp 主題圖示
/// 4. 簡潔文字排版：居中 20sp 粗體主標題與 14sp 灰色副標題
/// 5. 主行動按鈕：底部滿版圓角按鈕（「設定權限」），點擊時自動關閉抽屜並觸發回呼
/// 6. 點擊遮罩或向下拖曳即可關閉抽屜
class PermissionRequestSheet extends StatelessWidget {
  final String headerTitle;
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onConfirm;

  const PermissionRequestSheet({
    super.key,
    required this.headerTitle,
    required this.icon,
    this.iconColor,
    required this.title,
    required this.subtitle,
    this.buttonText = '設定權限',
    required this.onConfirm,
  });

  static Future<void> show({
    required BuildContext context,
    required String headerTitle,
    required IconData icon,
    Color? iconColor,
    required String title,
    required String subtitle,
    String buttonText = '設定權限',
    required VoidCallback onConfirm,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => PermissionRequestSheet(
        headerTitle: headerTitle,
        icon: icon,
        iconColor: iconColor,
        title: title,
        subtitle: subtitle,
        buttonText: buttonText,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final sheetBackgroundColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final primaryColor = iconColor ?? theme.colorScheme.primary;
    final textPrimaryColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final textSecondaryColor = isDark
        ? Colors.white.withOpacity(0.54)
        : Colors.black.withOpacity(0.54);

    return Container(
      decoration: BoxDecoration(
        color: sheetBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. LensWise 頂部把手 (32dp 置中)
              LensWiseSheetHandle(isDark: isDark),

              // 2. LensWise Header 標題列 (13sp 粗體大寫、字距 2.0sp 灰色標題)
              Row(
                children: [
                  const SizedBox(width: 48), // 左側 Spacer 對稱
                  Expanded(
                    child: Text(
                      headerTitle.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                        color: textSecondaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // 右側 Spacer 對稱
                ],
              ),

              const SizedBox(height: 28),

              // 3. 主 Icon 設計 (72 × 72dp 柔光圓形容器)
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 36,
                    color: primaryColor,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 4. 簡潔重點主標題
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textPrimaryColor,
                ),
              ),

              const SizedBox(height: 10),

              // 5. 簡潔副標題
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14,
                    height: 1.45,
                    color: textSecondaryColor,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // 6. 主行動按鈕（設定權限）
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onConfirm();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    buttonText,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
