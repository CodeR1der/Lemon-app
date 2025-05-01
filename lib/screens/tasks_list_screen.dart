import 'package:flutter/material.dart';
import 'package:task_tracker/screens/task_details_screen.dart';

import '../models/task.dart';
import '../models/task_status.dart';
import '../services/task_operations.dart';

class TaskListByStatusScreen extends StatefulWidget {
  final String? position;
  final String? userId;
  final String? projectId;
  final TaskStatus status;

  const TaskListByStatusScreen({
    this.position,
    this.userId,
    this.projectId,
    required this.status,
    Key? key,
  }) : super(key: key);

  @override
  State<TaskListByStatusScreen> createState() => _TaskListByStatusScreenState();
}

class _TaskListByStatusScreenState extends State<TaskListByStatusScreen> {
  final TaskService _taskService = TaskService();
  late Future<List<Task>> _tasksFuture;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  void _loadTasks() {
    if (widget.projectId != null) {
      _tasksFuture = _taskService.getProjectTasksByStatus(
        status: widget.status,
        projectId: widget.projectId!,
      );
    } else if (widget.userId != null && widget.position != null) {
      _tasksFuture = _taskService.getTasksByStatus(
        position: widget.position!,
        status: widget.status,
        employeeId: widget.userId!,
      );
    }
  }

  Widget _buildTaskCard(Task task) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskDetailsScreen(
              task: task,
            ),
          ),
        );
      },
      child: Card(
        color: Colors.white,
        elevation: 1,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Статус',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBEDF0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          StatusHelper.getStatusIcon(task.status),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(StatusHelper.displayName(task.status),
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Название задачи',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                task.taskName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                'Проект',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                task.project?.name ?? 'Не указан',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getAvatarInitials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(StatusHelper.displayName(widget.status)),
      ),
      body: FutureBuilder<List<Task>>(
        future: _tasksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Ошибка загрузки задач'));
          }

          final tasks = snapshot.data ?? [];

          if (tasks.isEmpty) {
            return const Center(child: Text('Нет задач с таким статусом'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: tasks.map((task) => _buildTaskCard(task)).toList(),
            ),
          );
        },
      ),
    );
  }
}
