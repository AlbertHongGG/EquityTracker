import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:equity_tracker/core/logging/domain/deletable_log.dart';
import 'package:equity_tracker/core/widgets/immersive_scaffold.dart';
import 'package:equity_tracker/core/widgets/premium_config_header.dart';
import 'package:equity_tracker/core/logging/presentation/widgets/glassmorphic_trash_control.dart';

/// 通用日誌檢視器骨架 (GenericLogViewerScaffold)
///
/// 1:1 復刻 LensWise_Android GenericLogViewerScaffold 規範：
/// - 泛型約束 <T extends DeletableLog>
/// - 支援無 Header 頂天立地模式 (title 為 null 時完全不渲染標題與 ThinkingOrb)
/// - 空白狀態垂直黃金重心校正 (避免空狀態被壓到螢幕底部貼著垃圾桶)
/// - 長按卡片拖曳至底部毛玻璃垃圾桶單筆刪除
class GenericLogViewerScaffold<T extends DeletableLog> extends StatefulWidget {
  final String? title;
  final String? subtitle;
  final List<T> items;
  final bool isLoading;
  final Widget? headerSlot;
  final Widget emptyState;
  final Widget Function(BuildContext context, T item, bool isDragging) itemBuilder;
  final Future<void> Function(T item) onDeleteItem;
  final VoidCallback onClearAll;

  const GenericLogViewerScaffold({
    super.key,
    this.title,
    this.subtitle,
    required this.items,
    this.isLoading = false,
    this.headerSlot,
    required this.emptyState,
    required this.itemBuilder,
    required this.onDeleteItem,
    required this.onClearAll,
  });

  @override
  State<GenericLogViewerScaffold<T>> createState() => _GenericLogViewerScaffoldState<T>();
}

class _GenericLogViewerScaffoldState<T extends DeletableLog>
    extends State<GenericLogViewerScaffold<T>> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return ImmersiveScaffold(
      body: Stack(
        children: [
          CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              // 1. 可選頂部標題 Header (若 title 為 null 則完全不顯示)
              if (widget.title != null)
                SliverToBoxAdapter(
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: PremiumConfigHeader(
                        title: widget.title!,
                        subtitle: widget.subtitle ?? '',
                      ),
                    ),
                  ),
                )
              else
                // 若無 Header，保留頂部狀態列安全距離
                const SliverToBoxAdapter(
                  child: SafeArea(
                    bottom: false,
                    child: SizedBox(height: 6.0),
                  ),
                ),

              // 2. 自訂插槽 (例如 LensWisePillTabBar)
              if (widget.headerSlot != null)
                SliverToBoxAdapter(
                  child: widget.headerSlot!,
                ),

              // 3. 列表內容 / 載入中 / 空白狀態 (重心校正)
              if (widget.isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (widget.items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Align(
                    alignment: widget.title != null
                        ? const Alignment(0, -0.25)
                        : const Alignment(0, -0.1),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 32.0),
                      child: widget.emptyState,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 120.0, top: 4.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = widget.items[index];

                        return LongPressDraggable<T>(
                          data: item,
                          delay: const Duration(milliseconds: 200),
                          feedback: Transform.rotate(
                            angle: -0.026, // 微幅傾斜 -1.5 度
                            child: SizedBox(
                              width: screenWidth - 32,
                              child: Material(
                                color: Colors.transparent,
                                child: widget.itemBuilder(context, item, true),
                              ),
                            ),
                          ),
                          childWhenDragging: Opacity(
                            opacity: 0.3,
                            child: widget.itemBuilder(context, item, false),
                          ),
                          child: widget.itemBuilder(context, item, false),
                        );
                      },
                      childCount: widget.items.length,
                    ),
                  ),
                ),
            ],
          ),

          // 4. 底部懸浮毛玻璃垃圾桶感應區
          Positioned(
            bottom: 28,
            left: 0,
            right: 0,
            child: Center(
              child: DragTarget<T>(
                onWillAcceptWithDetails: (details) {
                  HapticFeedback.selectionClick();
                  return true;
                },
                onAcceptWithDetails: (details) async {
                  HapticFeedback.mediumImpact();
                  await widget.onDeleteItem(details.data);
                },
                builder: (context, candidateData, rejectedData) {
                  final isHovering = candidateData.isNotEmpty;
                  return GlassmorphicTrashControl(
                    isHovering: isHovering,
                    onTap: widget.onClearAll,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
