import 'package:task_tracker/models/task_status.dart';

class TaskCategory {
  final String title;
  late int count;
  final TaskStatus status;

  TaskCategory({
    required this.title,
    required this.count,
    required this.status,
  });
}