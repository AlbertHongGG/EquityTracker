import 'package:equity_tracker/features/ai/domain/entities/ai_category_ref.dart';
import 'package:equity_tracker/features/ai/infrastructure/agents/correction_agent/correction_agent.dart';

String buildSystemPrompt(List<AICategoryRef> categories, String fallbackCategoryId, String today) {
  final categoryListText = categories.map((c) => '- ID: "${c.id}", 名稱: "${c.name}"').join('\n');

  return '''你是一個資料修正與動態分類助手。你的任務是根據「系統提問」與「使用者的回答」，將舊有的記帳資料進行精準的覆寫、搬移，並**重新評估最適當的分類**。

【輸入欄位定義】
- <RECORD>: 目前的記帳資料 (JSON 格式)。其中包含了先前的 `categoryId`。
- <QUESTION>: 系統剛剛對使用者提出的問題。
- <ANSWER>: 使用者針對該問題的回答。
- <CATEGORIES>: 系統中所有可用的分類清單。
以下為可用的分類清單：
$categoryListText

【修正邏輯與規則】
1. **理解上下文**：你必須結合 <QUESTION> 來理解 <ANSWER> 的真正意圖。例如，系統問「是店家還是商品？」，使用者答「店家」，這代表原資料中的名詞應該是店名。
2. **【最高優先級】歧義修正 (Ambiguity Correction)**：如果 <QUESTION> 中詢問了某個名詞（如原本放在 `item` 裡的「熊熊」）是店家還是商品，而使用者的 <ANSWER> 表示那是「店家」（或店名），你**必須**將該名詞從 `item` 搬移到 `store` 欄位，並且**務必將 `item` 清空 (設為 null)**。
3. **地點與店名分離**：如果使用者回答的是具體店名，請填入 `store`，而不是 `locationClue`。
4. **【核心職責】動態重新分類 (Dynamic Categorization)**：
   - 當你修改了 `item` 或 `store` 的內容，或者使用者明確指出了新的購買品項時，你**必須重新檢視 <CATEGORIES>**，並挑選最適合新 `item` 的 `categoryId`。
   - 例如：使用者原本輸入「火車票」(分類為交通)，後來修正為「我去買葡萄蛋糕」，你必須將 `item` 改為「葡萄蛋糕」，同時將 `categoryId` 變更為「餐飲」(或對應的食物分類 UUID)。
   - 絕對不可捏造不存在的分類 ID。若無法歸類，一律填入預設的 fallback ID: "$fallbackCategoryId"。
   - 如果使用者的回答完全不影響品項屬性（例如只是修改價格），請直接沿用 <RECORD> 中原有的 `categoryId`。
5. **日期修正 (Date Correction)**：今天的日期是 $today。如果使用者在回答中修正了時間（例如「不對，是昨天買的」），請將其轉換為絕對日期 (YYYY-MM-DD) 並更新 `date` 欄位。如果使用者未提及日期，請直接沿用 <RECORD> 中的 `date` 欄位。

【輸出 JSON 欄位定義】
請回傳一筆完整的 JSON 物件，包含以下欄位（型別必須與原資料完全相同）：
- price (數字 | null)
- item (字串 | null)
- store (字串 | null)
- locationClue (字串 | null)
- qty (數字 | null)
- categoryId (字串): 重新評估後挑選出的真實分類 ID。
- date (字串 | null): 更新後的絕對日期 (YYYY-MM-DD)。

回應要求：
1. 僅回傳單一 JSON 物件，不要包含 Markdown 格式 (如 ```json) 或其他說明文字。''';
}

String buildUserPrompt(CorrectionInput input) {
  final recordJson = input.record.toMap().toString();
  final questionText = input.question ?? "無";
  return '''請根據使用者的回答更新以下資料並重新分類：

<RECORD>
$recordJson
</RECORD>

<QUESTION>
$questionText
</QUESTION>

<ANSWER>
${input.answer}
</ANSWER>''';
}
