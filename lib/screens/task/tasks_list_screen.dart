import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:task_tracker/screens/task/task_details_screen.dart';
import 'package:task_tracker/task_screens/task_period_tab.dart';
import 'package:task_tracker/widgets/common/app_buttons.dart';
import 'package:task_tracker/widgets/common/app_colors.dart';

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
  final Map<String, bool> _expandedStates = {};

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
      _setupRealtimeSubscription();
    }
  }

  void _setupRealtimeSubscription() {
    print('TaskListScreen: Realtime подписка настроена через TaskProvider');
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      print('TaskListScreen: Загружаем задачи для статуса: ${widget.status}, позиции: ${widget.position}');

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

  void _toggleExpand(String taskId) {
    setState(() {
      _expandedStates[taskId] = !(_expandedStates[taskId] ?? false);
    });
  }

  Widget _buildTaskCard(BuildContext context, Task task) {
    final isExpanded = _expandedStates[task.id] ?? false;
    final isArchived = task.status == TaskStatus.closed || task.status == TaskStatus.completed;

    // Определяем иконку и текст статуса
    IconData statusIcon;
    String statusText;

    if (isArchived) {
      if (task.status == TaskStatus.completed) {
        statusIcon = Iconsax.tick_circle;
        statusText = 'Завершена';
      } else {
        statusIcon = Iconsax.close_circle;
        statusText = 'Закрыта';
      }
    } else {
      statusIcon = TaskCategories.getCategoryIcon(task.status);
      statusText = StatusHelper.displayName(task.status);
    }

    return GestureDetector(
      onTap: () => _toggleExpand(task.id),
      child: AppCommonWidgets.card(
        margin: AppSpacing.marginBottom16,
        padding: AppSpacing.paddingAll16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Заголовок карточки
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isArchived) ...[
                        // Для архивных задач: статус сверху
                        AppCommonWidgets.labeledField(
                          label: 'Статус',
                          child: AppCommonWidgets.statusChip(
                            icon: statusIcon,
                            text: statusText,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      // Название задачи для всех
                      AppCommonWidgets.labeledField(
                        label: 'Название задачи',
                        child: Text(
                          task.taskName,
                          style: AppTextStyles.bodyMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isExpanded ? Iconsax.arrow_circle_up_copy : Iconsax.arrow_circle_down_copy,
                  size: 32,
                  color: AppColors.primaryGrey,
                ),
              ],
            ),

            // Исполнитель для неархивных задач в неразвернутом состоянии
            if (!isExpanded && !isArchived && task.team.teamMembers.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Исполнитель', style: AppTextStyles.titleSmall),
              AppCommonWidgets.employeeTileSmall(
                  employee: task.team.teamMembers.first,
                  context: context
              ),
            ],

            // Развернутое состояние
            if (isExpanded) ...[
              const SizedBox(height: 16),

              // Статус для неархивных задач в развернутом состоянии
              if (!isArchived) ...[
                AppCommonWidgets.labeledField(
                  label: 'Сделать до',
                  child: Row(children: [
                    Icon(Iconsax.calendar,size: 18),
                    AppSpacing.width4,
                    Text(task.deadline != null ? TaskPeriodTab.formatDeadline(task.deadline) :TaskPeriodTab.formatDeadline(task.endDate), style: AppTextStyles.bodyMedium,) ,
                  ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Проект
              AppCommonWidgets.labeledField(
                label: 'Проект',
                child: Text(
                  task.project?.name ?? 'Не указан',
                  style: AppTextStyles.bodyMedium,
                ),
              ),

              // Исполнитель
              const SizedBox(height: 12),
              Text('Исполнитель', style: AppTextStyles.titleSmall),
              if (task.team.teamMembers.isNotEmpty)
                AppCommonWidgets.employeeTileSmall(
                    employee: task.team.teamMembers.first,
                    context: context
                )
              else
                Text('Не назначен', style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey)),

              // Очередность для коммуникатора
              if (widget.position == RoleHelper.convertToString(TaskRole.communicator) &&
                  widget.status == TaskStatus.queue) ...[
                const SizedBox(height: 12),
                AppCommonWidgets.labeledField(
                  label: 'Очередность задачи',
                  child: AppCommonWidgets.counterChip(
                    count: task.queuePosition.toString(),
                  ),
                ),
              ],

              // Кнопка подробнее
              const SizedBox(height: 16),
              AppButtons.secondaryButton(
                  text: 'Подробнее',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TaskDetailsScreen(task: task),
                      ),
                    );
                  }
              )
            ],
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
        title: Text(widget.status == TaskStatus.completed
            ? 'Архив задач'
            : StatusHelper.displayName(widget.status)),
      ),
      body: SafeArea(
        top: false,
        child: Consumer<TaskProvider>(
          builder: (context, taskProvider, child) {
            if (_isLoading) {
              return AppCommonWidgets.loadingIndicator();
            }
            if (taskProvider.error != null) {
              return AppCommonWidgets.errorWidget('Ошибка: ${taskProvider.error}');
            }
            final tasks = _getTasksFromProvider(taskProvider);

            if (tasks.isEmpty) {
              return AppCommonWidgets.emptyState('Нет задач с таким статусом');
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: tasks.map((task) => _buildTaskCard(context, task)).toList(),
              ),
            );
          },
        ),
      ),
    );
  }

  List<Task> _getTasksFromProvider(TaskProvider taskProvider) {
    if (widget.status == TaskStatus.completed) {
      final completedTasks = taskProvider.getTasksByStatus(
        TaskStatus.completed,
        projectId: widget.projectId,
        userId: widget.userId,
        position: widget.position,
      );
      final closedTasks = taskProvider.getTasksByStatus(
        TaskStatus.closed,
        projectId: widget.projectId,
        userId: widget.userId,
        position: widget.position,
      );
      return [...completedTasks, ...closedTasks];
    }

    if (widget.status == TaskStatus.controlPoint &&
        widget.position == RoleHelper.convertToString(TaskRole.communicator)) {
      return taskProvider.getTasksByStatus(
        TaskStatus.atWork,
        projectId: widget.projectId,
        userId: widget.userId,
        position: widget.position,
      );
    } else if (widget.status == TaskStatus.atWork &&
        widget.position == RoleHelper.convertToString(TaskRole.communicator)) {
      return taskProvider.getTasksByStatus(
        TaskStatus.atWork,
        projectId: widget.projectId,
        userId: widget.userId,
        position: widget.position,
      );
    } else if (widget.status == TaskStatus.controlPoint &&
        (widget.position == RoleHelper.convertToString(TaskRole.executor) ||
            widget.position == RoleHelper.convertToString(TaskRole.creator))) {
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
      return taskProvider.getTasksByStatus(
        widget.status,
        projectId: widget.projectId,
      );
    } else {
      return taskProvider.getTasksByStatus(
        widget.status,
        projectId: widget.projectId,
        userId: widget.userId,
        position: widget.position,
      );
    }
  }
}