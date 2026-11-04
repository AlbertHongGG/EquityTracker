import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'package:equity_tracker/core/logging/domain/api_log_category.dart';

/// LensWise 經典膠囊分頁欄元件 (LensWisePillTabBar)
///
/// 1:1 絕對復刻 LensWise_Android LensWisePillTabBar.kt 規範：
/// 1. 幾何約束：單個 Tab 寬度鎖定為 (containerWidth - 8dp) / 3，在螢幕上永遠剛好呈現 3 個項目，邊界 0 像素溢出。
/// 2. 單一動態引擎：單一 AnimationController (260ms, Cubic(0.2, 0.0, 0.0, 1.0)) 同步驅動膠囊位移與視窗滾動，
///    杜絕雙軌競態漂移與拉伸變形。
/// 3. 手勢純淨化：移除所有水波紋與點擊灰色背景閃跳 (NoSplash)。
/// 4. 色彩連續插值：文字與圖示顏色隨白底膠囊實際 X 座標進行物理漸變 (Color.lerp)，杜絕第 0 幀突兀跳色。
class LensWisePillTabBar extends StatefulWidget {
  final List<ApiLogTabConfig> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const LensWisePillTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  State<LensWisePillTabBar> createState() => _LensWisePillTabBarState();
}

class _LensWisePillTabBarState extends State<LensWisePillTabBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _curveAnimation;
  late final ScrollController _scrollController;

  double _fromOffset = 0.0;
  double _toOffset = 0.0;
  double _fromScroll = 0.0;
  double _toScroll = 0.0;

  double _currentTabWidth = 0.0;
  double _currentViewportWidth = 0.0;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _curveAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Cubic(0.2, 0.0, 0.0, 1.0),
    );

    _animController.addListener(() {
      if (_scrollController.hasClients && _fromScroll != _toScroll) {
        final t = _curveAnimation.value;
        final newScroll = lerpDouble(_fromScroll, _toScroll, t) ?? _toScroll;
        _scrollController.jumpTo(
          newScroll.clamp(0.0, _scrollController.position.maxScrollExtent),
        );
      }
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant LensWisePillTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _triggerTransition(oldWidget.selectedIndex, widget.selectedIndex);
    }
  }

  void _triggerTransition(int fromIndex, int toIndex) {
    if (_currentTabWidth <= 0 || widget.tabs.isEmpty) return;

    final safeToIndex = toIndex.clamp(0, widget.tabs.length - 1);
    final currentOffset = _isInitialized
        ? (lerpDouble(_fromOffset, _toOffset, _curveAnimation.value) ?? _toOffset)
        : (safeToIndex * _currentTabWidth);

    _fromOffset = currentOffset;
    _toOffset = safeToIndex * _currentTabWidth;

    if (_scrollController.hasClients) {
      _fromScroll = _scrollController.offset;
      final maxScroll = _scrollController.position.maxScrollExtent;
      _toScroll = _calculateTargetScroll(
        safeToIndex,
        _currentTabWidth,
        _currentViewportWidth,
        maxScroll,
      );
    } else {
      _fromScroll = 0.0;
      _toScroll = 0.0;
    }

    _animController.forward(from: 0.0);
  }

  double _calculateTargetScroll(
    int index,
    double tabWidth,
    double viewportWidth,
    double maxScroll,
  ) {
    final target = (index * tabWidth) - (viewportWidth - tabWidth) / 2.0;
    return target.clamp(0.0, maxScroll);
  }

  @override
  void dispose() {
    _animController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        // constraints.maxWidth 是外部傳入寬度 (螢幕寬度)
        // 外層 Margin 為左右各 16dp (共 32dp)
        // 內層 Padding 為左右各 4dp (共 8dp)
        // 故內部可視區域 (Viewport) 為 constraints.maxWidth - 40.0
        final viewportWidth = (constraints.maxWidth - 40.0).clamp(1.0, double.infinity);
        final tabWidth = viewportWidth / 3.0; // 絕對保證 3 席次在視窗內完整可見，無溢出裁切
        final totalWidth = tabWidth * widget.tabs.length;
        const tabHeight = 38.0;

        _currentTabWidth = tabWidth;
        _currentViewportWidth = viewportWidth;

        final safeIndex = widget.tabs.isEmpty
            ? 0
            : widget.selectedIndex.clamp(0, widget.tabs.length - 1);

        if (!_isInitialized && widget.tabs.isNotEmpty) {
          _isInitialized = true;
          _fromOffset = safeIndex * tabWidth;
          _toOffset = safeIndex * tabWidth;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _scrollController.hasClients) {
              final maxScroll = _scrollController.position.maxScrollExtent;
              final initialScroll = _calculateTargetScroll(
                safeIndex,
                tabWidth,
                viewportWidth,
                maxScroll,
              );
              _scrollController.jumpTo(initialScroll);
            }
          });
        }

        final currentPillOffset = lerpDouble(
              _fromOffset,
              _toOffset,
              _curveAnimation.value,
            ) ??
            _toOffset;

        return Container(
          height: tabHeight + 8.0, // 46dp
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          padding: const EdgeInsets.all(4.0),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
          ),
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              width: totalWidth,
              height: tabHeight,
              child: Stack(
                children: [
                  // 1. 懸浮白底滑動指示器 (Sliding Pill Indicator)
                  if (widget.tabs.isNotEmpty)
                    Positioned(
                      left: currentPillOffset,
                      top: 0,
                      width: tabWidth,
                      height: tabHeight,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.15)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: isDark
                              ? []
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                        ),
                      ),
                    ),

                  // 2. Tab 選項列表 (無水波紋干擾，文字顏色與膠囊位置進行物理連續插值)
                  Row(
                    children: List.generate(widget.tabs.length, (index) {
                      final tab = widget.tabs[index];

                      // 依據膠囊當前實體 X 座標與 Tab 中心的距離，計算選中重合率 (0.0 ~ 1.0)
                      final tabOffset = index * tabWidth;
                      final distance = (currentPillOffset - tabOffset).abs();
                      final proximity = (1.0 - (distance / tabWidth)).clamp(0.0, 1.0);

                      // 1:1 對標 LensWise_Android 之 Slate 石板色階
                      final Color unselectedColor = isDark
                          ? Colors.white54
                          : const Color(0xFF64748B); // Slate 500
                      final Color selectedColor = isDark
                          ? Colors.white
                          : const Color(0xFF1E293B); // Slate 800

                      final textColor = Color.lerp(
                        unselectedColor,
                        selectedColor,
                        proximity,
                      )!;

                      return SizedBox(
                        width: tabWidth,
                        height: tabHeight,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (index != widget.selectedIndex) {
                              widget.onTabSelected(index);
                            }
                          },
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  tab.tabIcon,
                                  size: 16,
                                  color: textColor,
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    tab.tabName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 13,
                                      fontWeight: proximity > 0.5
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
