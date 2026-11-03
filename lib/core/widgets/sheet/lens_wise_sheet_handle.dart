import 'package:flutter/material.dart';

/// LensWise 標準抽屜把手 (LensWiseSheetHandle)
/// 1:1 精確復刻 LensWise_Android 的 LensWiseSheetHandle 規格：
/// - 容器高度：32dp 置中
/// - 膠囊尺寸：寬 48dp × 高 5dp
/// - 圓角：2.5dp
/// - 顏色：暗色模式 White 30%，亮色模式 Black 22%
class LensWiseSheetHandle extends StatelessWidget {
  final bool? isDark;

  const LensWiseSheetHandle({
    super.key,
    this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveDark = isDark ?? (Theme.of(context).brightness == Brightness.dark);
    return SizedBox(
      height: 32,
      child: Center(
        child: Container(
          width: 48,
          height: 5,
          decoration: BoxDecoration(
            color: effectiveDark
                ? Colors.white.withOpacity(0.30)
                : Colors.black.withOpacity(0.22),
            borderRadius: BorderRadius.circular(2.5),
          ),
        ),
      ),
    );
  }
}
