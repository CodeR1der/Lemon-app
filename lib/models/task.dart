import 'package:task_tracker/models/task_status.dart';
import 'package:task_tracker/models/task_team.dart';
import 'package:task_tracker/services/task_operations.dart';

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
  DateTime? deadline;
  List<String> attachments;
  String? audioMessage;
  List<String>? videoMessage;
  String? queuePosition;
  Priority priority;
  TaskStatus status;

  Task({required this.id,
    required this.taskName,
    required this.description,
    required this.project,
    required this.team,
    required this.startDate,
    required this.endDate,
    required this.attachments,
    this.queuePosition,
    this.deadline,
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
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task_name': taskName,
      'description': description,
      'project_id': project!.projectId,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'priority': priority.displayName,
      'queue_position': queuePosition,
      'attachments': attachments,
      'deadline': deadline?.toIso8601String(),
      'audio_message': audioMessage,
      'video_message': videoMessage,
      'status': status.toString().substring(11)
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
      queuePosition: json['queue_position']?.toString() ,
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      videoMessage: List<String>.from(json['video_message'] ?? []),
      status: StatusHelper.toTaskStatus(json['status']),
    );
  }

  Future<void> changeStatus(TaskStatus newStatus) async {
    status = await TaskService().changeStatus(newStatus, id);
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

  Task copyWith({
    String? id,
    String? taskName,
    String? description,
    Project? project,
    TaskTeam? team,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? deadline,
    List<String>? attachments,
    String? audioMessage,
    List<String>? videoMessage,
    String? queuePosition,
    Priority? priority,
    TaskStatus? status,
  }) {
    return Task(
      id: id ?? this.id,
      taskName: taskName ?? this.taskName,
      description: description ?? this.description,
      project: project ?? this.project,
      team: team ?? this.team,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      deadline: deadline ?? this.deadline,
      attachments: attachments ?? List.from(this.attachments),
      audioMessage: audioMessage ?? this.audioMessage,
      videoMessage: videoMessage ?? (this.videoMessage != null ? List.from(this.videoMessage!) : null),
      queuePosition: queuePosition ?? this.queuePosition,
      priority: priority ?? this.priority,
      status: status ?? this.status,
    );
  }
}
