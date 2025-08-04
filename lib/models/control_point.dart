class ControlPoint {
  String? id;
  String taskId;
  String description;
  DateTime date;
  bool isCompleted;
  DateTime? createdAt;
  DateTime? completedAt;

  ControlPoint({
    this.id,
    required this.taskId,
    required this.description,
    required this.date,
    this.isCompleted = false,
    this.createdAt,
    this.completedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'description': description,
      'date': date.toIso8601String(),
      'is_completed': isCompleted,
      'created_at': createdAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  factory ControlPoint.fromJson(Map<String, dynamic> json) {
    return ControlPoint(
      id: json['id'] as String?,
      taskId: json['task_id'] as String,
      description: json['description'] as String,
      date: DateTime.parse(json['date'] as String),
      isCompleted: json['is_completed'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }
}
