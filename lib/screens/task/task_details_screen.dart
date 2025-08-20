import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:task_tracker/services/user_service.dart';

import '../../models/task.dart';
import '../../models/task_role.dart';
import '../../services/task_provider.dart';
import '../../task_screens/task_chat_tab.dart';
import '../../task_screens/task_description_tab.dart';
import '../../task_screens/task_logs_tab.dart';
import '../../task_screens/task_period_tab.dart';
import '../../task_screens/task_team_tab.dart';

class TaskDetailsScreen extends StatefulWidget {
  final Task task;

  const TaskDetailsScreen({super.key, required this.task});

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  RealtimeChannel? _realtimeChannel;
  Task? _currentTask;

  @override
  void initState() {
    super.initState();
    _currentTask = widget.task;
    _setupRealtimeSubscription();
  }

  void _setupRealtimeSubscription() {
    final client = Supabase.instance.client;

    print(
        'TaskDetailsScreen: Настраиваем Realtime подписку для задачи: ${widget.task.id}');

    _realtimeChannel = client
        .channel('task_details_${widget.task.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'task',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: widget.task.id,
          ),
          callback: (payload) {
            print(
                'TaskDetailsScreen: Получено изменение задачи: ${payload.eventType}');
            _handleTaskChange(payload);
          },
        )
        .subscribe();
  }

  void _handleTaskChange(PostgresChangePayload payload) {
    final eventType = payload.eventType.name;
    final newRecord = payload.newRecord;

    print('TaskDetailsScreen: Обработка изменения: $eventType');

    if (eventType == 'UPDATE' && newRecord != null) {
      try {
        final updatedTask = Task.fromJson(newRecord);
        setState(() {
          _currentTask = updatedTask;
        });
        print('TaskDetailsScreen: Задача обновлена: ${updatedTask.id}');
      } catch (e) {
        print('TaskDetailsScreen: Ошибка при обновлении задачи: $e');
      }
    } else if (eventType == 'DELETE') {
      // Если задача удалена, возвращаемся назад
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentTask = _currentTask ?? widget.task;
    final isMember = RoleHelper.determineUserRoleInTask(
            currentUserId: UserService.to.currentUser!.userId,
            task: currentTask) !=
        TaskRole.none;

    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final updatedTask = taskProvider.getTask(currentTask.id) ?? currentTask;
        return DefaultTabController(
          length: isMember ? 5 : 4,
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.white,
              title: Text('${updatedTask.taskName}'),
              bottom: TabBar(
                isScrollable: false,
                tabAlignment: TabAlignment.fill,
                tabs: [
                  const Tab(text: 'Описание'),
                  if (isMember) const Tab(text: 'Чат'),
                  const Tab(text: 'Срочность'),
                  const Tab(text: 'Команда'),
                  const Tab(text: 'Логи'),
                ],
              ),
            ),
            body: SafeArea(
              top: false,
              child: taskProvider.error != null
                  ? Center(child: Text('Ошибка: ${taskProvider.error}'))
                  : TabBarView(
                      children: [
                        TaskDescriptionTab(task: updatedTask),
                        if (isMember)
                          ChatTab(
                            taskId: updatedTask.id,
                          ),
                        TaskPeriodTab(task: updatedTask),
                        TaskTeamTab(task: updatedTask),
                        TaskLogsTab(task: updatedTask),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}
