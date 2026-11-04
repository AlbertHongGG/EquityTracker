import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/core/logging/domain/api_log_category.dart';
import 'package:equity_tracker/core/logging/domain/api_log_entry.dart';
import 'package:equity_tracker/core/logging/providers/logging_providers.dart';
import 'package:equity_tracker/core/logging/presentation/widgets/generic_log_viewer_scaffold.dart';
import 'package:equity_tracker/core/logging/presentation/widgets/lenswise_pill_tab_bar.dart';
import 'package:equity_tracker/core/logging/presentation/widgets/api_log_card.dart';
import 'package:equity_tracker/core/logging/presentation/widgets/premium_empty_state.dart';
import 'package:equity_tracker/core/logging/presentation/screens/api_log_detail_screen.dart';
import 'package:equity_tracker/core/widgets/sheet/swipe_to_confirm_drawer.dart';

/// API 與 AI 日誌檢視畫面 (ApiLogViewerScreen)
///
/// 1:1 復刻 LensWise_Android AiLogViewerScreen 規範：
/// 1. 決定論固定分頁 (LensWisePillTabBar)：不會因檔案被刪除而讓 Tab 消失或跳動
/// 2. 分頁專屬空白狀態 (PremiumEmptyState)
/// 3. 長按卡片拖曳至毛玻璃垃圾桶單筆刪除
/// 4. 點擊垃圾桶喚出滑動抽屜，精準依當前分頁清除日誌 (Category-Scoped Clear)
class ApiLogViewerScreen extends ConsumerStatefulWidget {
  const ApiLogViewerScreen({super.key});

  @override
  ConsumerState<ApiLogViewerScreen> createState() => _ApiLogViewerScreenState();
}

class _ApiLogViewerScreenState extends ConsumerState<ApiLogViewerScreen> {
  int _selectedTabIndex = 0;
  final List<ApiLogTabConfig> _tabs = ApiLogTabConfig.defaultTabs;

  @override
  Widget build(BuildContext context) {
    final currentTab = _tabs[_selectedTabIndex];
    final currentCategory = currentTab.category;

    final allLogsAsync = ref.watch(apiLogManagerProvider);
    final filteredLogs = ref.watch(filteredApiLogsProvider(currentCategory));
    final isLoading = allLogsAsync.isLoading;

    return GenericLogViewerScaffold<ApiLogEntry>(
      title: null,
      subtitle: null,
      items: filteredLogs,
      isLoading: isLoading,
      headerSlot: LensWisePillTabBar(
        tabs: _tabs,
        selectedIndex: _selectedTabIndex,
        onTabSelected: (index) {
          setState(() {
            _selectedTabIndex = index;
          });
        },
      ),
      emptyState: PremiumEmptyState(
        title: currentTab.emptyStateTitle,
        description: currentTab.emptyStateDescription,
        icon: currentTab.emptyStateIcon,
      ),
      itemBuilder: (context, item, isDragging) {
        return ApiLogCard(
          entry: item,
          isDragging: isDragging,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ApiLogDetailScreen(entry: item),
              ),
            );
          },
        );
      },
      onDeleteItem: (item) async {
        await ref.read(apiLogManagerProvider.notifier).deleteLog(item);
      },
      onClearAll: () {
        final title = currentCategory == null
            ? 'CLEAR ALL API LOGS'
            : 'CLEAR ${currentTab.tabName.toUpperCase()} LOGS';

        SwipeToConfirmDrawer.show(
          context: context,
          title: title,
          sliderTitle: 'SLIDE TO WIPE',
          confirmedTitle: 'RELEASE TO CLEAR',
          onConfirm: () async {
            await ref.read(apiLogManagerProvider.notifier).clearLogsByCategory(currentCategory);
          },
        );
      },
    );
  }
}
