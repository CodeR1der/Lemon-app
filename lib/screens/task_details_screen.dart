import 'package:flutter/material.dart';

import '../models/task.dart';
import '../task_screens/TaskChatTab.dart';
import '../task_screens/TaskDescriptionTab.dart';
import '../task_screens/TaskPeriodTab.dart';
import '../task_screens/TaskTeamTab.dart';

class TaskDetailsScreen extends StatefulWidget {
  final Task task;

  const TaskDetailsScreen({super.key, required this.task});

  @override
  _TaskDetailsScreenState createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text('Задача ${widget.task.taskName}'),
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
        body: TabBarView(
          children: [
            TaskDescriptionTab(task: widget.task),
            ChatTab(), // Переименовал ChatTab в TaskChatTab для единообразия
            TaskPeriodTab(task: widget.task),
            TaskTeamTab(task: widget.task),
          ],
        ),
      ),
    );
  }
}
