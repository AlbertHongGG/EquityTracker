import 'package:equity_tracker/features/ai/domain/entities/ai_transaction_view_item.dart';
import 'package:equity_tracker/features/ai/domain/entities/category_correction_item.dart';

enum ChatMessageType { user, ai, system, error }

/// 結構化訊息附件 (Sealed class)
sealed class ChatAttachmentPayload {
  const ChatAttachmentPayload();
}

/// 新增交易成功附件 (可點擊檢視/編輯交易)
final class CreatedTransactionsAttachment extends ChatAttachmentPayload {
  final List<AITransactionViewItem> items;
  const CreatedTransactionsAttachment(this.items);
}

/// 發票類別矯正結果附件 (展示每筆前後對比)
final class CategoryCorrectionAttachment extends ChatAttachmentPayload {
  final List<CategoryCorrectionItem> items;
  const CategoryCorrectionAttachment(this.items);
}

class ChatMessage {
  final String id;
  final String text;
  final ChatMessageType type;
  final ChatAttachmentPayload? payload;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.text,
    required this.type,
    this.payload,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
