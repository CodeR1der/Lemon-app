import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_tracker/screens/task_details_screen.dart';

import '../models/task.dart';
import '../models/task_role.dart';
import '../models/task_status.dart';
import '../services/task_provider.dart';

class TaskListByStatusScreen extends StatelessWidget {
  final String? position;
  final String? userId;
  final String? projectId;
  final TaskStatus status;

  const TaskListByStatusScreen({
    this.position,
    this.userId,
    this.projectId,
    required this.status,
    super.key,
  });

  Widget _buildTaskCard(BuildContext context, Task task) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskDetailsScreen(task: task),
          ),
        );
      },
      child: Card(
        color: Colors.white,
        elevation: 1,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Статус',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  //const CircleAvatar(radius: 16, backgroundColor: Colors.blue),
                  //const SizedBox(width: 8),
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
                        Icon(StatusHelper.getStatusIcon(task.status), size: 16),
                        const SizedBox(width: 6),
                        Text(StatusHelper.displayName(task.status),
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (position ==
                      RoleHelper.convertToString(TaskRole.communicator) &&
                  status == TaskStatus.queue) ...[
                Text(
                  'Очередность задачи',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBEDF0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    task.queuePosition.toString(),
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.black),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'Название задачи',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Text(
                task.taskName,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.black),
              ),
              const SizedBox(height: 16),
              Text(
                'Проект',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Text(
                task.project?.name ?? 'Не указан',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.black),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(StatusHelper.displayName(status)),
      ),
      body: SafeArea(
        top: false,
        child: Consumer<TaskProvider>(
          builder: (context, taskProvider, child) {
            var tasks = [];

            if (taskProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (taskProvider.error != null) {
              return Center(child: Text('Ошибка: ${taskProvider.error}'));
            }
            if (status == TaskStatus.controlPoint &&
                (position == TaskRole.executor ||
                    position == TaskRole.creator)) {
              tasks = taskProvider.getTasksByStatus(
                TaskStatus.atWork,
                projectId: projectId,
                userId: userId,
                position: position,
              );
              tasks += taskProvider.getTasksByStatus(
                status,
                projectId: projectId,
                userId: userId,
                position: position,
              );
            } else {
              tasks = taskProvider.getTasksByStatus(
                status,
                projectId: projectId,
                userId: userId,
                position: position,
              );
            }
            print(
                'Найдено задач: ${tasks.length} для статуса: $status, position: $position, userId: $userId');
            if (tasks.isEmpty) {
              return const Center(child: Text('Нет задач с таким статусом'));
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children:
                    tasks.map((task) => _buildTaskCard(context, task)).toList(),
              ),
            );
          },
        ),
      ),
    );
  }
}
