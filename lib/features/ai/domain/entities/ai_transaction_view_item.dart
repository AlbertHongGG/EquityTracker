class AITransactionViewItem {
  final int? id;
  final String title;
  final String? note;
  final int amount;
  final String categoryId;
  final String? categoryName;
  final DateTime date;

  const AITransactionViewItem({
    this.id,
    required this.title,
    this.note,
    required this.amount,
    required this.categoryId,
    this.categoryName,
    required this.date,
  });

  @override
  String toString() =>
      'AITransactionViewItem(id: $id, title: $title, amount: $amount, categoryId: $categoryId)';
}
