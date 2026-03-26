class MoodLog {
  final int? id;
  final String description;
  final String mood; // the mood level: awful, bad, okay, good, great
  final String dateTime;
  final String emoji;
  final String? energy; // "low" or "high", nullable
  final String? tags; // comma-separated tags, nullable

  MoodLog({
    this.id,
    required this.description,
    required this.mood,
    required this.dateTime,
    required this.emoji,
    this.energy,
    this.tags,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'mood': mood,
      'dateTime': dateTime,
      'emoji': emoji,
      'energy': energy,
      'tags': tags,
    };
  }

  factory MoodLog.fromMap(Map<String, dynamic> map) {
    return MoodLog(
      id: map['id'],
      description: map['description'],
      mood: map['mood'],
      dateTime: map['dateTime'],
      emoji: map['emoji'] ?? '😎',
      energy: map['energy'],
      tags: map['tags'],
    );
  }
}
