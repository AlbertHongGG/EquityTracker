import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 滑動抹除確認按鈕 (SwipeToObliterateButton)
/// 1:1 復刻 LensWise / GeminiFlowApp SwipeToObliterateButton.kt 規格：
/// - 軌道高度 68dp、滑塊 56dp、內距 6dp
/// - 拖曳進度 > 80% 時文字由「SLIDE TO WIPE」切換為「RELEASE TO CLEAR」
/// - 拖曳進度 > 85% 武裝門檻時，滑塊底色由純白翻轉為鮮紅、圖標切換為純白垃圾桶 (DeleteForever)、文字轉白並激發觸覺反饋
/// - 放手若已達武裝門檻觸發確認，未達門檻則以彈簧物理曲線 (elasticOut) 平滑回彈至起點
class SwipeToObliterateButton extends StatefulWidget {
  final String title;
  final String confirmedTitle;
  final VoidCallback onConfirmed;
  final bool isLoading;
  final Color activeColor;

  const SwipeToObliterateButton({
    super.key,
    this.title = 'SLIDE TO WIPE',
    this.confirmedTitle = 'RELEASE TO CLEAR',
    required this.onConfirmed,
    this.isLoading = false,
    this.activeColor = const Color(0xFFEF4444),
  });

  @override
  State<SwipeToObliterateButton> createState() => _SwipeToObliterateButtonState();
}

class _SwipeToObliterateButtonState extends State<SwipeToObliterateButton>
    with SingleTickerProviderStateMixin {
  double _dragPosition = 0.0;
  bool _isConfirmed = false;
  bool _wasArmed = false;

  late AnimationController _springController;
  late Animation<double> _springAnimation;

  static const double _trackHeight = 68.0;
  static const double _thumbSize = 56.0;
  static const double _padding = 6.0;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _springAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(parent: _springController, curve: Curves.elasticOut),
    );

    _springController.addListener(() {
      setState(() {
        _dragPosition = _springAnimation.value;
      });
    });
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details, double maxWidth) {
    if (widget.isLoading || _isConfirmed) return;

    final double maxDrag = maxWidth - _thumbSize - (_padding * 2);
    if (maxDrag <= 0) return;

    setState(() {
      _dragPosition = (_dragPosition + details.delta.dx).clamp(0.0, maxDrag);
    });

    final double progress = _dragPosition / maxDrag;
    final bool isArmed = progress > 0.85;

    // 跨越 85% 武裝門檻時觸發觸覺震動
    if (isArmed && !_wasArmed) {
      HapticFeedback.lightImpact();
    }
    _wasArmed = isArmed;
  }

  void _onPanEnd(DragEndDetails details, double maxWidth) {
    if (widget.isLoading || _isConfirmed) return;

    final double maxDrag = maxWidth - _thumbSize - (_padding * 2);
    if (maxDrag <= 0) return;

    final double progress = _dragPosition / maxDrag;

    if (progress >= 0.85) {
      // 達成 85% 刪除閥值：觸發確認
      setState(() {
        _dragPosition = maxDrag;
        _isConfirmed = true;
      });
      HapticFeedback.heavyImpact();
      widget.onConfirmed();
    } else {
      // 未達門檻：彈簧回彈至起點
      _wasArmed = false;
      _springAnimation = Tween<double>(begin: _dragPosition, end: 0.0).animate(
        CurvedAnimation(parent: _springController, curve: Curves.elasticOut),
      );
      _springController.forward(from: 0.0);
    }
  }

  @override
  void didUpdateWidget(covariant SwipeToObliterateButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLoading && !widget.isLoading) {
      setState(() {
        _isConfirmed = false;
        _wasArmed = false;
        _dragPosition = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final trackColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);
    final defaultTextColor = isDark
        ? Colors.white.withOpacity(0.50)
        : Colors.black.withOpacity(0.40);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxDrag = (constraints.maxWidth - _thumbSize - (_padding * 2)).clamp(0.0, double.infinity);
        final double progress = maxDrag > 0 ? (_dragPosition / maxDrag).clamp(0.0, 1.0) : 0.0;

        final bool isReleaseText = progress > 0.80;
        final bool isArmed = progress > 0.85;

        return SizedBox(
          height: _trackHeight,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // 1. 按鈕本體外軌道（具備高擬真層次陰影與精緻外邊框）
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: constraints.maxWidth,
                height: _trackHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_trackHeight / 2),
                  color: trackColor,
                  border: Border.all(
                    color: isArmed
                        ? widget.activeColor.withOpacity(0.35)
                        : (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06)),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isArmed
                          ? widget.activeColor.withOpacity(0.45)
                          : Colors.black.withOpacity(isDark ? 0.30 : 0.08),
                      blurRadius: isArmed ? 16 : 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
              ),

              // 2. 鮮紅背景揭示條 (拖曳時實心背景平滑緊隨滑塊右緣延伸，絕無殘色粉紅外溢)
              if (_dragPosition > 0.0)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: _thumbSize + (_padding * 2) + _dragPosition,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(_trackHeight / 2),
                      color: widget.activeColor.withOpacity(0.35 + (progress * 0.65)),
                    ),
                  ),
                ),

              // 3. 置中提示文字：小於 80% 為 SLIDE TO WIPE，大於 80% 動態切換為 RELEASE TO CLEAR
              Center(
                child: Text(
                  (isReleaseText ? widget.confirmedTitle : widget.title).toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: isArmed ? Colors.white.withOpacity(0.90) : defaultTextColor,
                  ),
                ),
              ),

              // 4. 滑塊本體 (Thumb) - 具有獨立立體陰影與翻轉狀態
              Positioned(
                left: _padding + _dragPosition,
                child: GestureDetector(
                  onPanUpdate: (details) => _onPanUpdate(details, constraints.maxWidth),
                  onPanEnd: (details) => _onPanEnd(details, constraints.maxWidth),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: _thumbSize,
                    height: _thumbSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isArmed ? widget.activeColor : Colors.white,
                      border: Border.all(
                        color: isArmed
                            ? Colors.white.withOpacity(0.45)
                            : (isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.06)),
                        width: isArmed ? 1.5 : 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.35 : 0.15),
                          blurRadius: isArmed ? 12 : 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: widget.isLoading
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isArmed ? Colors.white : widget.activeColor,
                                ),
                              ),
                            )
                          : isArmed
                              ? const Icon(
                                  Icons.delete_forever_rounded,
                                  color: Colors.white,
                                  size: 26,
                                )
                              : Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: widget.activeColor,
                                  size: 18,
                                ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
