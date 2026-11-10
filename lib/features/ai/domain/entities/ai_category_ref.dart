class AICategoryRef {
  final String id;
  final String name;
  final bool isExpense;

  const AICategoryRef({
    required this.id,
    required this.name,
    this.isExpense = true,
  });

  @override
  String toString() => 'AICategoryRef(id: $id, name: $name, isExpense: $isExpense)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AICategoryRef &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          isExpense == other.isExpense;

  @override
  int get hashCode => Object.hash(id, name, isExpense);
}
