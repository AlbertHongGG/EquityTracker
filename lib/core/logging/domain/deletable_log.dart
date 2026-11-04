import 'dart:io';

/// 通用可刪除日誌契約 (DeletableLog Interface)
///
/// 讓 UI 元件 (如 GenericLogViewerScaffold、DragDropTrashContainer)
/// 能以多型方式統一操作單筆 Log 刪除與拖曳物理回饋。
abstract interface class DeletableLog {
  /// 唯一識別碼 (通常為檔名或檔名前綴)
  String get id;

  /// 對應的實體日誌檔案
  File get file;

  /// 日誌建立時間戳記
  DateTime get timestamp;
}
