class NotificationRule {
  final String id;
  final String name; // e.g. "玉山銀行"
  final List<String> packageNames; // e.g. ["com.esunbank.ewallet", "com.esunbank.android"]
  final List<String> titleKeywords; // e.g. ["玉山", "ESUN"]
  final List<String> bodyKeywords; // e.g. ["消費", "刷卡", "授權"]
  final List<String> negativeKeywords; // e.g. ["失敗", "驗證碼", "帳單"]
  final String defaultTransactionTitle; // e.g. "玉山銀行刷卡"
  final String? defaultCategoryId; // null = use global default
  final bool isEnabled;
  final bool isSystemPreset;

  const NotificationRule({
    required this.id,
    required this.name,
    required this.packageNames,
    required this.titleKeywords,
    this.bodyKeywords = const [],
    this.negativeKeywords = const [],
    required this.defaultTransactionTitle,
    this.defaultCategoryId,
    this.isEnabled = true,
    this.isSystemPreset = true,
  });

  NotificationRule copyWith({
    String? id,
    String? name,
    List<String>? packageNames,
    List<String>? titleKeywords,
    List<String>? bodyKeywords,
    List<String>? negativeKeywords,
    String? defaultTransactionTitle,
    String? defaultCategoryId,
    bool? isEnabled,
    bool? isSystemPreset,
  }) {
    return NotificationRule(
      id: id ?? this.id,
      name: name ?? this.name,
      packageNames: packageNames ?? this.packageNames,
      titleKeywords: titleKeywords ?? this.titleKeywords,
      bodyKeywords: bodyKeywords ?? this.bodyKeywords,
      negativeKeywords: negativeKeywords ?? this.negativeKeywords,
      defaultTransactionTitle: defaultTransactionTitle ?? this.defaultTransactionTitle,
      defaultCategoryId: defaultCategoryId ?? this.defaultCategoryId,
      isEnabled: isEnabled ?? this.isEnabled,
      isSystemPreset: isSystemPreset ?? this.isSystemPreset,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'packageNames': packageNames,
      'titleKeywords': titleKeywords,
      'bodyKeywords': bodyKeywords,
      'negativeKeywords': negativeKeywords,
      'defaultTransactionTitle': defaultTransactionTitle,
      'defaultCategoryId': defaultCategoryId,
      'isEnabled': isEnabled,
      'isSystemPreset': isSystemPreset,
    };
  }

  factory NotificationRule.fromMap(Map<String, dynamic> map) {
    return NotificationRule(
      id: map['id'] as String,
      name: map['name'] as String,
      packageNames: List<String>.from(map['packageNames'] ?? []),
      titleKeywords: List<String>.from(map['titleKeywords'] ?? []),
      bodyKeywords: List<String>.from(map['bodyKeywords'] ?? []),
      negativeKeywords: List<String>.from(map['negativeKeywords'] ?? []),
      defaultTransactionTitle: map['defaultTransactionTitle'] as String,
      defaultCategoryId: map['defaultCategoryId'] as String?,
      isEnabled: map['isEnabled'] == 1 || map['isEnabled'] == true,
      isSystemPreset: map['isSystemPreset'] == 1 || map['isSystemPreset'] == true,
    );
  }
}
