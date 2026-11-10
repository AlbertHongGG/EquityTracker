import 'package:equity_tracker/features/ai/domain/entities/ai_category_ref.dart';
import 'package:equity_tracker/features/ai/domain/entities/ai_transaction_draft.dart';
import 'package:equity_tracker/features/ai/domain/entities/ai_transaction_summary.dart';
import 'package:equity_tracker/features/ai/domain/entities/ai_transaction_view_item.dart';

/// AI 模組與外部記帳/分類系統互動的抽象手腳契約 (Port)
///
/// 遵循依賴反轉原則 (DIP)，AI 模組僅透過此介面存取與修改資料，
/// 絕不直接依賴任何具體 Repository、Notifier 或 SQLite 實作。
abstract interface class ILedgerGateway {
  /// 取得目前系統啟用的分類清單
  Future<List<AICategoryRef>> getActiveCategories({bool? isExpense});

  /// 依名稱搜尋分類 (例如尋找「發票」或「其他」)
  Future<AICategoryRef?> findCategoryByName(String name, {bool? isExpense});

  /// 撈取指定分類 ID 底下的所有交易摘要
  Future<List<AITransactionSummary>> getTransactionsByCategoryId(String categoryId);

  /// 批次建立新交易並儲存，回傳可供 UI 渲染展示的 ViewItem
  Future<List<AITransactionViewItem>> createTransactions(List<AITransactionDraft> drafts);

  /// 批次更新特定交易的 categoryId (具原子性，並自動觸發同步機制)
  Future<void> batchUpdateCategories(Map<int, String> txIdToNewCategoryId);
}
