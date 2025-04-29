import 'package:task_tracker/models/task_status.dart';
import 'package:task_tracker/models/task_team.dart';

import 'priority.dart';
import 'project.dart';

class Task {
  String id;
  String taskName;
  String description;
  Project? project;
  TaskTeam team;
  DateTime startDate;
  DateTime endDate;
  List<String> attachments;
  String? audioMessage;
  List<String>? videoMessage;
  Priority priority;
  TaskStatus status;

  Task(
      {required this.id,
      required this.taskName,
      required this.description,
      required this.project,
      required this.team,
      required this.startDate,
      required this.endDate,
      required this.attachments,
      this.audioMessage,
      this.videoMessage,
      this.priority = Priority.low, // Значение по умолчанию
      this.status = TaskStatus.newTask});

  // Метод для преобразования строки из базы данных в Priority
  static Priority parsePriority(String priority) {
    switch (priority) {
      case 'Низкий':
        return Priority.low;
      case 'Средний':
        return Priority.medium;
      case 'Высокий':
        return Priority.high;
      default:
        throw ArgumentError('Unknown priority: $priority');
    }
  }

  String priorityToString() {
    switch (priority) {
      case Priority.low:
        return 'Низкий';
      case Priority.medium:
        return 'Средний';
      case Priority.high:
        return 'Высокий';
      default:
        return 'Низкий';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task_name': taskName,
      'description': description,
      'project': project!.projectId,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'priority': priority.displayName,
      'attachments': attachments,
      'audio_message': audioMessage,
      'video_message': videoMessage,
      'status': status
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      taskName: json['task_name'],
      description: json['description'],
      project: Project.fromJson(json['project']),
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      team: (json['task_team'] as List)
          .map((team) => TaskTeam.fromJson(team))
          .single,
      attachments: List<String>.from(json['attachments'] ?? []),
      audioMessage: json['audio_message'],
      videoMessage: List<String>.from(json['video_message'] ?? []),
      status: StatusHelper.toTaskStatus(json['status']),
    );
  }

  // Метод для добавления прикрепленного файла
  void addAttachment(String filePath) {
    attachments.add(filePath);
  }

  void removeAttachment(String filePath) {
    attachments.remove(filePath);
  }

  // Метод для установки аудиосообщения
  void setAudioMessage(String? path) {
    audioMessage = path;
  }

  // Метод для установки видеосообщения
  void setVideoMessage(String? videoPath) {
    videoMessage ??= [];
    if (videoPath != null) {
      // Выполняйте операцию только если videoPath не null
      videoMessage!.add(videoPath);
    }
  }

  void removeVideoMessage(String filePath) {
    videoMessage!.remove(filePath);
  }
}
