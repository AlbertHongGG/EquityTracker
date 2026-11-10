class AITransactionSummary {
  final int id;
  final String title;
  final String? note;
  final int amount;
  final String categoryId;
  final DateTime date;

  const AITransactionSummary({
    required this.id,
    required this.title,
    this.note,
    required this.amount,
    required this.categoryId,
    required this.date,
  });

  @override
  String toString() =>
      'AITransactionSummary(id: $id, title: $title, note: $note, amount: $amount, categoryId: $categoryId)';
}
