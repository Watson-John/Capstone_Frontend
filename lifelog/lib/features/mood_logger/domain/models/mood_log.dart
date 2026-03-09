class MoodLog {
  final int? id;
  final String description;
  final String mood; // the tag entered by user
  final String dateTime;
  final String emoji;

  MoodLog({
    this.id,
    required this.description,
    required this.mood,
    required this.dateTime,
    required this.emoji,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'mood': mood,
      'dateTime': dateTime,
      'emoji': emoji,
    };
  }

  factory MoodLog.fromMap(Map<String, dynamic> map) {
    return MoodLog(
      id: map['id'],
      description: map['description'],
      mood: map['mood'],
      dateTime: map['dateTime'],
      emoji: map['emoji'] ?? '😎', // Default if migrating
    );
  }
}
