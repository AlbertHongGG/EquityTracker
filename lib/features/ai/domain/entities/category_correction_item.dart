class CategoryCorrectionItem {
  final int transactionId;
  final String title;
  final String? note;
  final int amount;
  final String oldCategoryId;
  final String oldCategoryName;
  final String newCategoryId;
  final String newCategoryName;
  final String? reason;

  const CategoryCorrectionItem({
    required this.transactionId,
    required this.title,
    this.note,
    required this.amount,
    required this.oldCategoryId,
    required this.oldCategoryName,
    required this.newCategoryId,
    required this.newCategoryName,
    this.reason,
  });

  @override
  String toString() =>
      'CategoryCorrectionItem(id: $transactionId, $title: $oldCategoryName -> $newCategoryName)';
}
