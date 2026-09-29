class Todo {
  const Todo({required this.id, required this.title, required this.completed});

  factory Todo.fromJson(Map<String, dynamic> json) => Todo(
    id: json['id']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    completed: json['completed'] == true || json['completed'] == 'true',
  );

  final String id;
  final String title;
  final bool completed;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'completed': completed,
  };

  Todo copyWith({String? id, String? title, bool? completed}) => Todo(
    id: id ?? this.id,
    title: title ?? this.title,
    completed: completed ?? this.completed,
  );
}
