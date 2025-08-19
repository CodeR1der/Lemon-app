import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_tracker/screens/task/task_details_screen.dart';

import '../../models/task.dart';
import '../../models/task_role.dart';
import '../../models/task_status.dart';
import '../../services/task_provider.dart';
import '../../widgets/common/app_common_widgets.dart';
import '../../widgets/common/app_spacing.dart';
import '../../widgets/common/app_text_styles.dart';

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
    super.key,
  });

  @override
  State<TaskListByStatusScreen> createState() => _TaskListByStatusScreenState();
}

class _TaskListByStatusScreenState extends State<TaskListByStatusScreen> {
  List<Task> _tasks = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      print(
          'TaskListScreen: Загружаем задачи для статуса: ${widget.status}, позиции: ${widget.position}');

      if (widget.status == TaskStatus.controlPoint &&
          widget.position ==
              RoleHelper.convertToString(TaskRole.communicator)) {
        print(
            'TaskListScreen: Используем асинхронный метод для контрольных точек коммуникатора');
        // Для контрольных точек коммуникатора используем асинхронный метод
        _tasks = await taskProvider.getTasksByStatusWithControlPoints(
          widget.status,
          projectId: widget.projectId,
          userId: widget.userId,
          position: widget.position,
        );
      } else if (widget.status == TaskStatus.atWork &&
          widget.position ==
              RoleHelper.convertToString(TaskRole.communicator)) {
        print(
            'TaskListScreen: Используем асинхронный метод для задач "В работе" коммуникатора');
        // Для задач "В работе" коммуникатора используем асинхронный метод (исключая контрольные точки)
        _tasks = await taskProvider.getTasksByStatusWithControlPoints(
          widget.status,
          projectId: widget.projectId,
          userId: widget.userId,
          position: widget.position,
        );
      } else if (widget.status == TaskStatus.controlPoint &&
          (widget.position == RoleHelper.convertToString(TaskRole.executor) ||
              widget.position ==
                  RoleHelper.convertToString(TaskRole.creator))) {
        print('TaskListScreen: Объединяем задачи для исполнителя/постановщика');
        // Для исполнителя и постановщика объединяем задачи "В работе" и "Контрольная точка"
        final atWorkTasks = taskProvider.getTasksByStatus(
          TaskStatus.atWork,
          projectId: widget.projectId,
          userId: widget.userId,
          position: widget.position,
        );
        final controlPointTasks = taskProvider.getTasksByStatus(
          widget.status,
          projectId: widget.projectId,
          userId: widget.userId,
          position: widget.position,
        );
        _tasks = [...atWorkTasks, ...controlPointTasks];
      } else {
        print('TaskListScreen: Используем обычный метод');
        // Для остальных случаев используем обычный метод
        _tasks = taskProvider.getTasksByStatus(
          widget.status,
          projectId: widget.projectId,
          userId: widget.userId,
          position: widget.position,
        );
      }

      print(
          'TaskListScreen: Найдено задач: ${_tasks.length} для статуса: ${widget.status}, position: ${widget.position}, userId: ${widget.userId}');
    } catch (e) {
      print('TaskListScreen: Ошибка при загрузке задач: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildTaskCard(BuildContext context, Task task) {
    // Определяем отображаемый статус для коммуникатора
    TaskStatus displayStatus = task.status;
    if (widget.position == RoleHelper.convertToString(TaskRole.communicator) &&
        task.status == TaskStatus.atWork &&
        widget.status == TaskStatus.controlPoint) {
      // Для коммуникатора в списке контрольных точек отображаем как "Контрольная точка"
      displayStatus = TaskStatus.controlPoint;
      print(
          'TaskListScreen: Отображаем задачу ${task.id} как "Контрольная точка"');
    } else {
      print(
          'TaskListScreen: Отображаем задачу ${task.id} со статусом: ${task.status}');
    }

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
                icon: StatusHelper.getStatusIcon(displayStatus),
                text: StatusHelper.displayName(displayStatus),
              ),
            ),
            if (widget.position ==
                    RoleHelper.convertToString(TaskRole.communicator) &&
                widget.status == TaskStatus.queue) ...[
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
        title: Text(StatusHelper.displayName(widget.status)),
      ),
      body: SafeArea(
        top: false,
        child: Consumer<TaskProvider>(
          builder: (context, taskProvider, child) {
            if (_isLoading) {
              return AppCommonWidgets.loadingIndicator();
            }
            if (taskProvider.error != null) {
              return AppCommonWidgets.errorWidget(
                  'Ошибка: ${taskProvider.error}');
            }

            if (_tasks.isEmpty) {
              return AppCommonWidgets.emptyState('Нет задач с таким статусом');
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: _tasks
                    .map((task) => _buildTaskCard(context, task))
                    .toList(),
              ),
            );
          },
        ),
      ),
    );
  }
}
