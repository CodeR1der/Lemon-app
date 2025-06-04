class ChatMessage {
  final String id;
  final String taskId;
  final String userId;
  final String? message;
  final List<String> fileUrl;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.taskId,
    required this.userId,
    this.message,
    required this.fileUrl,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      userId: json['user_id'] as String,
      message: json['message'] as String?,
      fileUrl: List<String>.from(json['file_url'] ?? []),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'user_id': userId,
      'message': message,
      'file_url': fileUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}