class Todo {
  final int? id;
  final String task;
  final String? details;
  final DateTime startDate;
  final DateTime dueDate;
  final String status;
  final String? imagePath;

  // Extended fields
  final String priority; // kept for DB compatibility; default 'Medium'
  final bool isAllDay;
  final bool isRecurring;
  final String? recurrenceType; // 'daily', 'weekly', 'monthly'
  final String? recurrenceDays; // comma-separated days for weekly: 'Mon,Wed,Fri'
  final int? reminderMinutes; // minutes before task start; null = no reminder
  final String? category; // stores a kCategoryStyles key for the color label

  Todo({
    this.id,
    required this.task,
    this.details,
    required this.startDate,
    required this.dueDate,
    required this.status,
    this.imagePath,
    this.priority = 'Medium',
    this.isAllDay = false,
    this.isRecurring = false,
    this.recurrenceType,
    this.recurrenceDays,
    this.reminderMinutes,
    this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task': task,
      'details': details,
      'startDate': startDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'status': status,
      'imagePath': imagePath,
      'priority': priority,
      'isAllDay': isAllDay ? 1 : 0,
      'isRecurring': isRecurring ? 1 : 0,
      'recurrenceType': recurrenceType,
      'recurrenceDays': recurrenceDays,
      'reminderMinutes': reminderMinutes,
      'category': category,
    };
  }

  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'],
      task: map['task'],
      details: map['details'],
      startDate: DateTime.parse(map['startDate']),
      dueDate: DateTime.parse(map['dueDate']),
      status: map['status'],
      imagePath: map['imagePath'],
      priority: map['priority'] as String? ?? 'Medium',
      isAllDay: (map['isAllDay'] as int? ?? 0) == 1,
      isRecurring: (map['isRecurring'] as int? ?? 0) == 1,
      recurrenceType: map['recurrenceType'] as String?,
      recurrenceDays: map['recurrenceDays'] as String?,
      reminderMinutes: map['reminderMinutes'] as int?,
      category: map['category'] as String?,
    );
  }

  bool isActiveOn(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(dueDate.year, dueDate.month, dueDate.day);

    if (d.isBefore(start) || d.isAfter(end)) return false;
    if (!isRecurring) return true;
    if (recurrenceType == 'daily') return true;

    if (recurrenceType == 'weekly') {
      if (recurrenceDays == null || recurrenceDays!.isEmpty) return true;
      const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final dayLabel = dayNames[d.weekday - 1];
      return recurrenceDays!.split(',').contains(dayLabel);
    }

    if (recurrenceType == 'monthly') {
      return d.day == start.day;
    }

    return true;
  }

  Todo copyWith({
    int? id,
    String? task,
    String? details,
    DateTime? startDate,
    DateTime? dueDate,
    String? status,
    String? imagePath,
    String? priority,
    bool? isAllDay,
    bool? isRecurring,
    String? recurrenceType,
    String? recurrenceDays,
    int? reminderMinutes,
    String? category,
  }) {
    return Todo(
      id: id ?? this.id,
      task: task ?? this.task,
      details: details ?? this.details,
      startDate: startDate ?? this.startDate,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      imagePath: imagePath ?? this.imagePath,
      priority: priority ?? this.priority,
      isAllDay: isAllDay ?? this.isAllDay,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      recurrenceDays: recurrenceDays ?? this.recurrenceDays,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      category: category ?? this.category,
    );
  }
}
