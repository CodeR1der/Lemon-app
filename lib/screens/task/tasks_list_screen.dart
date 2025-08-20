import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:task_tracker/screens/task/task_details_screen.dart';

import '../../models/task.dart';
import '../../models/task_role.dart';
import '../../models/task_status.dart';
import '../../services/task_categories.dart';
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
  bool _initialized = false;
  bool _isLoading = false;
  RealtimeChannel? _realtimeChannel;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      if (widget.projectId != null) {
        taskProvider.loadTasksAndCategories(
          taskCategories: TaskCategories(),
          projectId: widget.projectId,
        );
      } else if (widget.position != null && widget.userId != null) {
        taskProvider.loadTasksAndCategories(
          taskCategories: TaskCategories(),
          position: widget.position!,
          employeeId: widget.userId!,
        );
      }
      _initialized = true;

      // Настраиваем Realtime подписку для этого экрана
      _setupRealtimeSubscription();
    }
  }

  void _setupRealtimeSubscription() {
    // Упрощенная подписка - основное обновление идет через TaskProvider
    print('TaskListScreen: Realtime подписка настроена через TaskProvider');
  }

  // Методы обработки Realtime событий удалены - теперь используется TaskProvider

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      print(
          'TaskListScreen: Загружаем задачи для статуса: ${widget.status}, позиции: ${widget.position}');

      // Загружаем задачи через TaskProvider - они будут доступны через Consumer
      if (widget.projectId != null) {
        taskProvider.loadTasksAndCategories(
          taskCategories: TaskCategories(),
          projectId: widget.projectId,
        );
      } else if (widget.position != null && widget.userId != null) {
        taskProvider.loadTasksAndCategories(
          taskCategories: TaskCategories(),
          position: widget.position!,
          employeeId: widget.userId!,
        );
      }

      print('TaskListScreen: Задачи загружены через TaskProvider');
    } catch (e) {
      print('TaskListScreen: Ошибка при загрузке задач: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildTaskCard(BuildContext context, Task task) {
    // Определяем отображаемый статус
    TaskStatus displayStatus = task.status;

    // Для проектов всегда используем реальный статус из БД
    if (widget.projectId != null) {
      displayStatus = task.status;
      print(
          'TaskListScreen: Отображаем задачу ${task.id} в проекте со статусом: ${task.status}');
    } else if (widget.position ==
            RoleHelper.convertToString(TaskRole.communicator) &&
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
//
            final tasks = _getTasksFromProvider(taskProvider);

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

  List<Task> _getTasksFromProvider(TaskProvider taskProvider) {
    // Получаем актуальные задачи из TaskProvider
    if (widget.status == TaskStatus.controlPoint &&
        widget.position == RoleHelper.convertToString(TaskRole.communicator)) {
      // Для контрольных точек коммуникатора используем специальную логику
      return taskProvider.getTasksByStatus(
        TaskStatus.atWork,
        projectId: widget.projectId,
        userId: widget.userId,
        position: widget.position,
      );
    } else if (widget.status == TaskStatus.atWork &&
        widget.position == RoleHelper.convertToString(TaskRole.communicator)) {
      // Для задач "В работе" коммуникатора используем специальную логику
      return taskProvider.getTasksByStatus(
        TaskStatus.atWork,
        projectId: widget.projectId,
        userId: widget.userId,
        position: widget.position,
      );
    } else if (widget.status == TaskStatus.controlPoint &&
        (widget.position == RoleHelper.convertToString(TaskRole.executor) ||
            widget.position == RoleHelper.convertToString(TaskRole.creator))) {
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
      return [...atWorkTasks, ...controlPointTasks];
    } else if (widget.projectId != null) {
      // Для проектов используем реальный статус из БД
      return taskProvider.getTasksByStatus(
        widget.status,
        projectId: widget.projectId,
      );
    } else {
      // Для остальных случаев используем обычный метод
      return taskProvider.getTasksByStatus(
        widget.status,
        projectId: widget.projectId,
        userId: widget.userId,
        position: widget.position,
      );
    }
  }
}
