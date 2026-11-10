import 'dart:convert';
import 'package:equity_tracker/features/ai/domain/entities/ai_category_ref.dart';
import 'package:equity_tracker/features/ai/domain/entities/ai_transaction_summary.dart';

String buildBatchCategorizationSystemPrompt(
  List<AICategoryRef> categories,
  String fallbackCategoryId,
) {
  final categoryListText = categories.map((c) => '- ID: "${c.id}", 名稱: "${c.name}"').join('\n');

  return '''你是一個專業的財務交易批次分類助手。
你的任務是審查 <INPUT> 區塊中的待分類交易項目，依據其「店家/標題 (title)」與「購買備註 (note)」推斷出最適當的真實分類。

【可用分類清單 (CATEGORIES)】
你只能從以下系統現有的分類中挑選：
$categoryListText

【推斷原則與鐵律】
1. **依據上下文合理推論**：
   - 超商/超市 (全聯、家樂福、7-ELEVEN、全家)：若備註有餐飲飲料則偏向飲食/生活；若無備註通常偏向生活或飲食。
   - 加油站 (中油、台塑、全國加油站)：歸類於交通或加油。
   - 餐飲小吃 (麥當勞、便當店、飲料店、星巴克)：歸類於伙食/飲食。
   - 醫療藥局 (屈臣氏、康是美、診所、醫院)：藥品保健歸醫療，日常用品歸生活。
2. **【防幻覺絕對鐵律】**：
   - 輸出的 `categoryId` 必須 100% 存在於上述清單中。
   - **絕對不可自創或捏造不存在的 ID**。
   - 若某筆交易資訊極度匱乏 (例如 title 與 note 皆為空白或純代碼) 而完全無法判斷，請一律填入 fallback ID: "$fallbackCategoryId"。
3. **保留原始 ID**：每個輸出物件的 `id` 必須與輸入中的 `id` 嚴格對應。

【輸出格式要求】
請回傳單一 JSON 陣列，每個物件代表一筆推斷結果，不要包含 Markdown 格式 (如 ```json) 或任何其他說明：
[
  {
    "id": 12,
    "categoryId": "真實的分類ID",
    "reason": "簡短推斷理由 (如: 連鎖超商飲食花費)"
  }
]''';
}

String buildBatchCategorizationUserPrompt(List<AITransactionSummary> items) {
  final itemsJson = items.map((t) => {
    'id': t.id,
    'title': t.title,
    'note': t.note ?? '',
    'amount': t.amount,
  }).toList();

  return '''請對以下 ${items.length} 筆交易項目進行分類：

<INPUT>
${jsonEncode(itemsJson)}
</INPUT>''';
}
