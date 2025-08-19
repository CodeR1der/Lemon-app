import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_tracker/services/user_service.dart';

import '../../models/task.dart';
import '../../models/task_role.dart';
import '../../services/task_provider.dart';
import '../../task_screens/task_chat_tab.dart';
import '../../task_screens/task_description_tab.dart';
import '../../task_screens/task_logs_tab.dart';
import '../../task_screens/task_period_tab.dart';
import '../../task_screens/task_team_tab.dart';

class TaskDetailsScreen extends StatelessWidget {
  final Task task;

  const TaskDetailsScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final isMember = RoleHelper.determineUserRoleInTask(
            currentUserId: UserService.to.currentUser!.userId, task: task) !=
        TaskRole.none;

    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final updatedTask = taskProvider.getTask(task.id) ?? task;
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
