// tasks_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/employee.dart';
import '../services/task_categories.dart';
import '../services/task_provider.dart';
import 'position_tasks_tab.dart';

class TasksScreen extends StatefulWidget {
  final Employee user;

  const TasksScreen({required this.user, super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  @override
  Widget build(BuildContext context) {
    final user = widget.user;

    return DefaultTabController(
      length: user.role == "Коммуникатор" ? 4 : 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              if (user.role == "Коммуникатор") const Tab(text: 'Я коммуникатор'),
              const Tab(text: 'Я исполнитель'),
              const Tab(text: 'Я постановщик'),
              const Tab(text: 'Я наблюдатель'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            if (user.role == "Коммуникатор")
              _buildTab("Коммуникатор", user.userId),
            _buildTab("Исполнитель", user.userId),
            _buildTab("Постановщик", user.userId),
            _buildTab("Наблюдатель", user.userId),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String position, String employeeId) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {

        return PositionTasksTab(
          position: position,
          employeeId: employeeId,
        );
      },
    );
  }
}