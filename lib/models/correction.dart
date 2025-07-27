import 'package:task_tracker/models/task_status.dart';

class Correction {
  late String? id;
  late DateTime date;
  late String taskId;
  late TaskStatus status;
  late String? description;
  List<String>? attachments;
  String? audioMessage;
  List<String>? videoMessage;
  late bool isDone;

  Correction({
    this.id,
    required this.date,
    required this.taskId,
    required this.status,
    this.description,
    this.attachments,
    this.audioMessage,
    this.videoMessage,
    this.isDone = false,
  });


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'task_id': taskId,
      'description': description,
      'is_done': isDone,
      'attachments': attachments,
      'audio_message': audioMessage,
      'video_message': videoMessage,
      'status': status.toString().substring(11)
    };
  }

  factory Correction.fromJson(Map<String, dynamic> json) {
    return Correction(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String).toLocal(),
      taskId: json['task_id'] as String,
      description: json['description'] as String,
      attachments: List<String>.from(json['attachments'] ?? []),
      audioMessage: json['audio_message'],
      videoMessage: List<String>.from(json['video_message'] ?? []),
      status: StatusHelper.toTaskStatus(json['status']),
      isDone: json['is_done'] as bool? ?? false,
    );
  }
}