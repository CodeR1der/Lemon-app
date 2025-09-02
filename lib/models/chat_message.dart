class ChatMessage {
  final String id;
  final String taskId;
  final String userId;
  final String? message;
  final List<String> fileUrl;
  final String? fileName; // Добавьте это поле
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.taskId,
    required this.userId,
    this.message,
    required this.fileUrl,
    this.fileName, // И это
    required this.createdAt,
  });

  // Обновите методы fromJson и toJson соответственно
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      taskId: json['task_id'],
      userId: json['user_id'],
      message: json['message'],
      fileUrl: List<String>.from(json['file_url'] ?? []),
      fileName: json['file_name'], // Добавьте
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'user_id': userId,//
      'message': message,
      'file_url': fileUrl,
      'file_name': fileName, // Добавьте
      'created_at': createdAt.toIso8601String(),
    };
  }
}