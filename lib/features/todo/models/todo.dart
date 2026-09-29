class Todo {
  const Todo({
    required this.id,
    required this.title,
    required this.completed,
    required this.details,
  });

  factory Todo.fromJson(Map<String, dynamic> json) => Todo(
    id: json['id']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    completed: json['completed'] == true || json['completed'] == 'true',
    details: json['details']?.toString() ?? '',
  );

  final String id;
  final String title;
  final bool completed;
  final String details;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'completed': completed,
    'details': details,
  };

  Todo copyWith({
    String? id,
    String? title,
    bool? completed,
    String? details,
  }) => Todo(
    id: id ?? this.id,
    title: title ?? this.title,
    completed: completed ?? this.completed,
    details: details ?? this.details,
  );
}
