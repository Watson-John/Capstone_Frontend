class GratitudeEntry {
  final int? id;
  final String body;
  final String? prompt;
  final String dateTime;
  final String? tags;

  const GratitudeEntry({
    this.id,
    required this.body,
    this.prompt,
    required this.dateTime,
    this.tags,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'body': body,
      'prompt': prompt,
      'dateTime': dateTime,
      'tags': tags,
    };
  }

  factory GratitudeEntry.fromMap(Map<String, dynamic> map) {
    return GratitudeEntry(
      id: map['id'] as int?,
      body: map['body'] as String,
      prompt: map['prompt'] as String?,
      dateTime: map['dateTime'] as String,
      tags: map['tags'] as String?,
    );
  }

  GratitudeEntry copyWith({
    int? id,
    String? body,
    String? prompt,
    String? dateTime,
    String? tags,
  }) {
    return GratitudeEntry(
      id: id ?? this.id,
      body: body ?? this.body,
      prompt: prompt ?? this.prompt,
      dateTime: dateTime ?? this.dateTime,
      tags: tags ?? this.tags,
    );
  }
}
