import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../services/task_provider.dart';
import '../task_screens/TaskChatTab.dart';
import '../task_screens/TaskDescriptionTab.dart';
import '../task_screens/TaskPeriodTab.dart';
import '../task_screens/TaskTeamTab.dart';

class TaskDetailsScreen extends StatelessWidget {
  final Task task;

  const TaskDetailsScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final updatedTask = taskProvider.getTask(task.id) ?? task;
        return DefaultTabController(
          length: 4,
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.white,
              title: Text('Задача ${updatedTask.taskName}'),
              bottom: const TabBar(
                isScrollable: false,
                tabAlignment: TabAlignment.fill,
                tabs: [
                  Tab(text: 'Описание'),
                  Tab(text: 'Чат'),
                  Tab(text: 'Срочность'),
                  Tab(text: 'Команда'),
                ],
              ),
            ),
            body: taskProvider.error != null
                ? Center(child: Text('Ошибка: ${taskProvider.error}'))
                : TabBarView(
              children: [
                TaskDescriptionTab(task: updatedTask),
                ChatTab(taskId: updatedTask.id,),
                TaskPeriodTab(task: updatedTask),
                TaskTeamTab(task: updatedTask),
              ],
            ),
          ),
        );
      },
    );
  }
}