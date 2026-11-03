import 'package:flutter/material.dart';
import 'package:equity_tracker/core/widgets/swipe_to_obliterate_button.dart';

/// 沉浸式下拉刪除抽屜容器 (SwipeToConfirmDrawer)
/// 1:1 復刻 LensWise / GeminiFlowApp SwipeToConfirmDrawer.kt 規範：
/// - 採用 24dp 頂部圓角
/// - 頂部 40 × 4dp 指示條 (圓角 2dp)
/// - 置中 13sp 粗體大寫、字距 2.0sp 灰色標題
/// - 內嵌具備「雙段文字反饋」與「垃圾桶圖標轉場」的 SwipeToObliterateButton
class SwipeToConfirmDrawer extends StatelessWidget {
  final String title;
  final String sliderTitle;
  final String confirmedTitle;
  final Color activeColor;
  final VoidCallback onConfirm;

  const SwipeToConfirmDrawer({
    super.key,
    required this.title,
    this.sliderTitle = 'SLIDE TO WIPE',
    this.confirmedTitle = 'RELEASE TO CLEAR',
    this.activeColor = const Color(0xFFEF4444),
    required this.onConfirm,
  });

  static Future<void> show({
    required BuildContext context,
    required String title,
    String sliderTitle = 'SLIDE TO WIPE',
    String confirmedTitle = 'RELEASE TO CLEAR',
    Color activeColor = const Color(0xFFEF4444),
    required VoidCallback onConfirm,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SwipeToConfirmDrawer(
        title: title,
        sliderTitle: sliderTitle,
        confirmedTitle: confirmedTitle,
        activeColor: activeColor,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sheetBackgroundColor = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7);
    final handleColor = isDark
        ? Colors.white.withOpacity(0.24)
        : Colors.black.withOpacity(0.12);
    final titleColor = isDark
        ? Colors.white.withOpacity(0.54)
        : Colors.black.withOpacity(0.54);

    return Container(
      decoration: BoxDecoration(
        color: sheetBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. 頂部 Handle 指示條 (40 × 4dp，圓角 2dp)
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: handleColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const SizedBox(height: 24),

              // 2. 置中 13sp 粗體大寫、字距 2.0sp 灰色標題
              Text(
                title.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                  color: titleColor,
                ),
              ),

              const SizedBox(height: 32),

              // 3. 雙段文字與垃圾桶圖標轉場的滑動按鈕
              SwipeToObliterateButton(
                title: sliderTitle,
                confirmedTitle: confirmedTitle,
                activeColor: activeColor,
                onConfirmed: () {
                  Navigator.of(context).pop();
                  onConfirm();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
