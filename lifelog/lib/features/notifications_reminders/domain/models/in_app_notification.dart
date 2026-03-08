class InAppNotification {
  final int? id;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;

  InAppNotification({
    this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'title': title,
      'body': body,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead ? 1 : 0,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory InAppNotification.fromMap(Map<String, dynamic> map) {
    return InAppNotification(
      id: map['id'],
      title: map['title'],
      body: map['body'],
      timestamp: DateTime.parse(map['timestamp']),
      isRead: map['isRead'] == 1,
    );
  }
}
