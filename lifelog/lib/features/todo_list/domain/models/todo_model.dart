class Todo {
  final int? id;
  final String task;
  final DateTime startDate;
  final DateTime dueDate;
  final String status;
  final String? imagePath;

  Todo({
    this.id,
    required this.task,
    required this.startDate,
    required this.dueDate,
    required this.status,
    this.imagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task': task,
      'startDate': startDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'status': status,
      'imagePath': imagePath,
    };
  }

  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'],
      task: map['task'],
      startDate: DateTime.parse(map['startDate']),
      dueDate: DateTime.parse(map['dueDate']),
      status: map['status'],
      imagePath: map['imagePath'],
    );
  }

  Todo copyWith({
    int? id,
    String? task,
    DateTime? startDate,
    DateTime? dueDate,
    String? status,
    String? imagePath,
  }) {
    return Todo(
      id: id ?? this.id,
      task: task ?? this.task,
      startDate: startDate ?? this.startDate,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}
