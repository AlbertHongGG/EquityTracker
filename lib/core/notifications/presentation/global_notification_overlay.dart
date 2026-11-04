import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/core/notifications/controllers/notification_controller.dart';
import 'package:equity_tracker/core/widgets/premium_toast_widget.dart';

/// 全域單一通知覆蓋層元件 (Global Single-Slot Notification Overlay)
///
/// 1:1 復刻 LensWise_Android GlobalNotificationOverlay 核心保證：
/// 1. 唯一通知呈現：畫面同時至多僅顯示一則通知，徹底廢除舊有多層向下疊加瀑布。
/// 2. 即時平滑覆蓋：當新通知觸發時，透過 AnimatedSwitcher 原地平滑置換內容，零高度跳動。
/// 3. 支援手動關閉與定時自動淡出退場。
class GlobalNotificationOverlay extends ConsumerWidget {
  final Widget? child;

  const GlobalNotificationOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentNotification = ref.watch(notificationControllerProvider);

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          if (child != null) child!,

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 16.0, right: 16.0),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  reverseDuration: const Duration(milliseconds: 220),
                  switchInCurve: const Cubic(0.25, 1.0, 0.5, 1.0),
                  switchOutCurve: const Cubic(0.25, 1.0, 0.5, 1.0),
                  layoutBuilder: (currentChild, previousChildren) {
                    return Stack(
                      alignment: Alignment.topCenter,
                      children: <Widget>[
                        ...previousChildren,
                        if (currentChild != null) currentChild,
                      ],
                    );
                  },
                  transitionBuilder: (widgetChild, animation) {
                    final slideAnimation = Tween<Offset>(
                      begin: const Offset(0.0, -0.4),
                      end: Offset.zero,
                    ).animate(animation);

                    return SlideTransition(
                      position: slideAnimation,
                      child: FadeTransition(
                        opacity: animation,
                        child: widgetChild,
                      ),
                    );
                  },
                  child: currentNotification != null
                      ? KeyedSubtree(
                          key: ValueKey(currentNotification.id),
                          child: PremiumToastWidget(
                            notification: currentNotification,
                            animation: const AlwaysStoppedAnimation(1.0),
                            onDismiss: () {
                              ref.read(notificationControllerProvider.notifier).dismiss();
                            },
                          ),
                        )
                      : const SizedBox.shrink(key: ValueKey('empty_notification')),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
