class AITransactionDraft {
  final String? item;
  final int? price;
  final String? store;
  final String? locationClue;
  final int? qty;
  final String? categoryId;
  final String? date;

  const AITransactionDraft({
    this.item,
    this.price,
    this.store,
    this.locationClue,
    this.qty,
    this.categoryId,
    this.date,
  });

  factory AITransactionDraft.fromMap(Map<String, dynamic> map) {
    return AITransactionDraft(
      item: map['item'] as String?,
      price: (map['price'] as num?)?.toInt(),
      store: map['store'] as String?,
      locationClue: map['locationClue'] as String?,
      qty: (map['qty'] as num?)?.toInt(),
      categoryId: map['categoryId'] as String?,
      date: map['date'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'item': item,
      'price': price,
      'store': store,
      'locationClue': locationClue,
      'qty': qty,
      'categoryId': categoryId,
      'date': date,
    };
  }

  AITransactionDraft copyWith({
    String? item,
    int? price,
    String? store,
    String? locationClue,
    int? qty,
    String? categoryId,
    String? date,
  }) {
    return AITransactionDraft(
      item: item ?? this.item,
      price: price ?? this.price,
      store: store ?? this.store,
      locationClue: locationClue ?? this.locationClue,
      qty: qty ?? this.qty,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
    );
  }

  @override
  String toString() =>
      'AITransactionDraft(item: $item, price: $price, store: $store, date: $date, categoryId: $categoryId)';
}
