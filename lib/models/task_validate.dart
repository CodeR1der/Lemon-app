

class TaskValidate {
  late String? id;
  late DateTime date;
  late String taskId;
  late String? link;
  late String? description;
  List<String>? attachments;
  String? audioMessage;
  List<String>? videoMessage;
  late bool isDone;

  TaskValidate({
    this.id,
    required this.date,
    required this.taskId,
    this.link,
    this.description,
    this.attachments,
    this.audioMessage,
    this.videoMessage,
    this.isDone = false,
  });


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toLocal().toIso8601String(),
      'task_id': taskId,
      'description': description,
      'is_done': isDone,
      'link': link,
      'attachments': attachments,
      'audio_message': audioMessage,
      'video_message': videoMessage,
    };
  }

  factory TaskValidate.fromJson(Map<String, dynamic> json) {
    return TaskValidate(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String).toLocal(),
      taskId: json['task_id'] as String,
      description: json['description'] as String,
      link: json['link'],
      attachments: List<String>.from(json['attachments'] ?? []),
      audioMessage: json['audio_message'],
      videoMessage: List<String>.from(json['video_message'] ?? []),
      isDone: json['is_done'] as bool? ?? false,
    );
  }
}