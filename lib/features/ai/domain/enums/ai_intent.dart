enum AIIntent {
  /// 新增支出或收入記帳
  addTransaction('add_transaction'),

  /// 矯正發票類別 (將發票項目的類別批次修正為真實類別)
  reclassifyReceipts('reclassify_receipts'),

  /// 目前尚未支援的意圖或通用閒聊
  unsupported('unsupported');

  /// 與 LLM 結構化輸出協定完全對齊之唯一識別碼 (Contract SSOT)
  final String wireName;

  const AIIntent(this.wireName);

  /// 嚴格依據協定契約反序列化，若非約定之標識則拒絕猜測並安全歸類為 unsupported
  static AIIntent fromString(String? raw) {
    if (raw == null) return AIIntent.unsupported;
    final normalized = raw.trim().toLowerCase();
    for (final intent in AIIntent.values) {
      if (intent.wireName == normalized) {
        return intent;
      }
    }
    return AIIntent.unsupported;
  }
}
