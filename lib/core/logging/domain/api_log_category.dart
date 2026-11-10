import 'package:flutter/material.dart';

/// API 與 AI 互動日誌分類枚舉 (ApiLogCategory)
///
/// 遵循開放封閉原則 (OCP)，定義所有可能發起外部請求或 AI 處理之業務模組。
enum ApiLogCategory {
  aiExtraction(
    key: 'ai_extraction',
    displayName: 'AI 記帳解析',
    icon: Icons.auto_awesome_rounded,
  ),
  aiStoreLookup(
    key: 'ai_store_lookup',
    displayName: 'AI 店家查詢',
    icon: Icons.storefront_rounded,
  ),
  aiValidation(
    key: 'ai_validation',
    displayName: 'AI 驗證修正',
    icon: Icons.rule_rounded,
  ),
  aiIntentRouter(
    key: 'ai_intent_router',
    displayName: 'AI 意圖路由',
    icon: Icons.alt_route_rounded,
  ),
  aiCategoryCorrection(
    key: 'ai_category_correction',
    displayName: 'AI 類別矯正',
    icon: Icons.auto_fix_high_rounded,
  ),
  googleMap(
    key: 'google_map',
    displayName: '地圖搜尋',
    icon: Icons.map_outlined,
  ),
  notionSync(
    key: 'notion_sync',
    displayName: 'Notion 同步',
    icon: Icons.sync_alt_rounded,
  ),
  githubUpdater(
    key: 'github_updater',
    displayName: '系統更新',
    icon: Icons.system_update_alt_rounded,
  );

  final String key;
  final String displayName;
  final IconData icon;

  const ApiLogCategory({
    required this.key,
    required this.displayName,
    required this.icon,
  });

  static ApiLogCategory? fromKey(String? key) {
    if (key == null) return null;
    final normalized = key.toLowerCase().trim();
    for (final category in ApiLogCategory.values) {
      if (category.key == normalized) return category;
    }
    return null;
  }
}

/// 決定論分頁配置模型 (ApiLogTabConfig)
///
/// 1:1 復刻 LensWise_Android DefaultAiLogConfigs 規範：
/// 固定定義所有分頁，不因檔案不存在而跳動或消失，提供獨立空白狀態與圖標。
class ApiLogTabConfig {
  final String id;
  final String tabName;
  final IconData tabIcon;
  final ApiLogCategory? category;
  final String emptyStateTitle;
  final String emptyStateDescription;
  final IconData emptyStateIcon;

  const ApiLogTabConfig({
    required this.id,
    required this.tabName,
    required this.tabIcon,
    required this.category,
    required this.emptyStateTitle,
    required this.emptyStateDescription,
    required this.emptyStateIcon,
  });

  static List<ApiLogTabConfig> get defaultTabs => const [
    ApiLogTabConfig(
      id: 'tab_all',
      tabName: '全部',
      tabIcon: Icons.all_inclusive_rounded,
      category: null,
      emptyStateTitle: '尚無任何日誌',
      emptyStateDescription: '尚未產生任何互動紀錄',
      emptyStateIcon: Icons.history_rounded,
    ),
    ApiLogTabConfig(
      id: 'tab_extraction',
      tabName: '記帳解析',
      tabIcon: Icons.auto_awesome_rounded,
      category: ApiLogCategory.aiExtraction,
      emptyStateTitle: '尚無解析日誌',
      emptyStateDescription: '尚未產生記帳解析紀錄',
      emptyStateIcon: Icons.auto_awesome_outlined,
    ),
    ApiLogTabConfig(
      id: 'tab_store_lookup',
      tabName: '店家查詢',
      tabIcon: Icons.storefront_rounded,
      category: ApiLogCategory.aiStoreLookup,
      emptyStateTitle: '尚無店家日誌',
      emptyStateDescription: '尚未產生店家推論紀錄',
      emptyStateIcon: Icons.store_outlined,
    ),
    ApiLogTabConfig(
      id: 'tab_validation',
      tabName: '驗證修正',
      tabIcon: Icons.rule_rounded,
      category: ApiLogCategory.aiValidation,
      emptyStateTitle: '尚無驗證日誌',
      emptyStateDescription: '尚未產生驗證修正紀錄',
      emptyStateIcon: Icons.fact_check_outlined,
    ),
    ApiLogTabConfig(
      id: 'tab_google_map',
      tabName: '地圖搜尋',
      tabIcon: Icons.map_outlined,
      category: ApiLogCategory.googleMap,
      emptyStateTitle: '尚無地圖日誌',
      emptyStateDescription: '尚未產生店家搜尋紀錄',
      emptyStateIcon: Icons.map_rounded,
    ),
    ApiLogTabConfig(
      id: 'tab_notion_sync',
      tabName: 'Notion 同步',
      tabIcon: Icons.sync_alt_rounded,
      category: ApiLogCategory.notionSync,
      emptyStateTitle: '尚無同步日誌',
      emptyStateDescription: '尚未產生資料庫同步紀錄',
      emptyStateIcon: Icons.sync_problem_rounded,
    ),
    ApiLogTabConfig(
      id: 'tab_github_updater',
      tabName: '系統更新',
      tabIcon: Icons.system_update_alt_rounded,
      category: ApiLogCategory.githubUpdater,
      emptyStateTitle: '尚無更新日誌',
      emptyStateDescription: '尚未產生版本檢查紀錄',
      emptyStateIcon: Icons.update_rounded,
    ),
  ];
}
