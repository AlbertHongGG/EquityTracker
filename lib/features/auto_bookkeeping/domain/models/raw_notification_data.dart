class RawNotificationData {
  final String packageName;
  final String title;
  final String body;
  final DateTime timestamp;

  const RawNotificationData({
    required this.packageName,
    required this.title,
    required this.body,
    required this.timestamp,
  });

  factory RawNotificationData.fromMap(Map<String, dynamic> map) {
    return RawNotificationData(
      packageName: map['packageName'] as String? ?? '',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'packageName': packageName,
      'title': title,
      'body': body,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}
