import 'package:flutter/material.dart';

/// 質感空白狀態元件 (PremiumEmptyState)
///
/// 1:1 復刻 LensWise_Android PremiumEmptyState 規範：
/// - 置中 96dp 圓形淺色光暈底容器
/// - 內置 44dp 主題色圖示
/// - 18sp Bold Outfit 標題
/// - 13sp 簡短精確說明（零廢話口水文案）
class PremiumEmptyState extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const PremiumEmptyState({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.primaryColor;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primary.withValues(alpha: isDark ? 0.12 : 0.08),
                border: Border.all(
                  color: primary.withValues(alpha: isDark ? 0.22 : 0.14),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 44,
                  color: primary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                height: 1.4,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
