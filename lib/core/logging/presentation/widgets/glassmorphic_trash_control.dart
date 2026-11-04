import 'dart:ui';
import 'package:flutter/material.dart';

/// 底部懸浮毛玻璃垃圾桶控制項 (GlassmorphicTrashControl)
///
/// 1:1 復刻 LensWise_Android GlassmorphicTrashControl 規範：
/// - 平時：56dp 圓形、磨砂玻璃模糊 (sigma = 10)、細緻微光邊框、Icons.delete_outline
/// - 懸浮感應中 (isHovering)：彈簧放大至 64dp、鮮紅漸層 (#EF4444 -> #DC2626)、紅光暈陰影、Icons.delete_forever
/// - 點擊觸發 onTap (通常開啟 SwipeToConfirmDrawer)
class GlassmorphicTrashControl extends StatelessWidget {
  final bool isHovering;
  final VoidCallback onTap;

  const GlassmorphicTrashControl({
    super.key,
    required this.isHovering,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final double size = isHovering ? 64 : 56;
    final Color normalBg = isDark
        ? Colors.black.withValues(alpha: 0.6)
        : Colors.white.withValues(alpha: 0.8);
    final Color normalBorder = isDark ? Colors.white12 : Colors.black12;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isHovering
              ? const LinearGradient(
                  colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isHovering ? null : normalBg,
          border: Border.all(
            color: isHovering ? const Color(0xFFEF4444) : normalBorder,
            width: isHovering ? 2.0 : 1.0,
          ),
          boxShadow: [
            if (isHovering)
              BoxShadow(
                color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                blurRadius: 24,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: Icon(
                  isHovering ? Icons.delete_forever_rounded : Icons.delete_outline_rounded,
                  key: ValueKey(isHovering),
                  color: isHovering
                      ? Colors.white
                      : (isDark ? Colors.white70 : Colors.black87),
                  size: isHovering ? 30 : 24,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
