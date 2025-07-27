import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_tracker/screens/task_details_screen.dart';

import '../models/task.dart';
import '../models/task_role.dart';
import '../models/task_status.dart';
import '../services/task_provider.dart';
import '../widgets/common/app_common.dart';

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
      child: AppCommonWidgets.card(
        margin: AppSpacing.marginBottom16,
        padding: AppSpacing.paddingAll16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AppCommonWidgets.labeledField(
              label: 'Статус',
              child: AppCommonWidgets.statusChip(
                icon: StatusHelper.getStatusIcon(task.status),
                text: StatusHelper.displayName(task.status),
              ),
            ),
            if (position == RoleHelper.convertToString(TaskRole.communicator) &&
                status == TaskStatus.queue) ...[
              AppCommonWidgets.labeledField(
                label: 'Очередность задачи',
                child: AppCommonWidgets.counterChip(
                  count: task.queuePosition.toString(),
                ),
              ),
            ],
            AppCommonWidgets.labeledField(
              label: 'Название задачи',
              child: Text(
                task.taskName,
                style: AppTextStyles.bodyMedium,
              ),
            ),
            AppCommonWidgets.labeledField(
              label: 'Проект',
              child: Text(
                task.project?.name ?? 'Не указан',
                style: AppTextStyles.bodyMedium,
              ),
            ),
          ],
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
              return AppCommonWidgets.loadingIndicator();
            }
            if (taskProvider.error != null) {
              return AppCommonWidgets.errorWidget(
                  'Ошибка: ${taskProvider.error}');
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
              return AppCommonWidgets.emptyState('Нет задач с таким статусом');
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
