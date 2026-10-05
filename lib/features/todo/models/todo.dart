class Todo {
  const Todo({
    required this.id,
    required this.title,
    required this.completed,
    required this.details,
    this.createdAt,
    this.dueDate,
    this.priority = '',
  });

  factory Todo.fromJson(Map<String, dynamic> json) => Todo(
    id: json['id']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    completed: json['completed'] == true || json['completed'] == 'true',
    details: json['details']?.toString() ?? '',
    createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    dueDate: DateTime.tryParse(json['due_date']?.toString() ?? ''),
    priority: json['priority']?.toString() ?? '',
  );

  final String id;
  final String title;
  final bool completed;
  final String details;
  final DateTime? createdAt;
  final DateTime? dueDate;
  final String priority;

  factory Todo.fromDb(Map<String, Object?> row) =>
      Todo.fromJson({...row, 'completed': row['completed'] == 1});

  Map<String, Object?> toDb() => {
    ...toJson(),
    'id': int.parse(id),
    'completed': completed ? 1 : 0,
  };

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'completed': completed,
    'details': details,
    'created_at': createdAt?.toIso8601String(),
    'due_date': dueDate?.toIso8601String(),
    'priority': priority,
  };

  Todo copyWith({
    String? id,
    String? title,
    bool? completed,
    String? details,
    DateTime? createdAt,
    DateTime? dueDate,
    bool clearDueDate = false,
    String? priority,
  }) => Todo(
    id: id ?? this.id,
    title: title ?? this.title,
    completed: completed ?? this.completed,
    details: details ?? this.details,
    createdAt: createdAt ?? this.createdAt,
    dueDate: clearDueDate ? null : dueDate ?? this.dueDate,
    priority: priority ?? this.priority,
  );
}
