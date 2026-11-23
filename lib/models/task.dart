class Task {
  final String id;
  final String title;
  final String note;
  final DateTime? dueDate;
  final bool isDone;

  const Task({
    required this.id,
    required this.title,
    this.note = '',
    this.dueDate,
    this.isDone = false,
  });

  Task copyWith({
    String? title,
    String? note,
    DateTime? dueDate,
    bool clearDueDate = false,
    bool? isDone,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      note: note ?? this.note,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      isDone: isDone ?? this.isDone,
    );
  }

  bool get isOverdue {
    if (dueDate == null || isDone) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return dueDate!.isBefore(today);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'note': note,
        'dueDate': dueDate?.toIso8601String(),
        'isDone': isDone,
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'] as String,
        title: json['title'] as String,
        note: (json['note'] as String?) ?? '',
        dueDate: json['dueDate'] == null
            ? null
            : DateTime.parse(json['dueDate'] as String),
        isDone: (json['isDone'] as bool?) ?? false,
      );
}
