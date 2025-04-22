import 'package:flutter/material.dart';
import 'package:task_tracker/screens/creater_tasks_tab.dart';
import '../models/task.dart';
import '../models/employee.dart';

class TasksScreen extends StatefulWidget {
  final Employee user;
  const TasksScreen({required this.user, Key? key}) : super(key: key);

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> with SingleTickerProviderStateMixin {
  late List<Task> executorTasks;
  late List<Task> producerTasks;
  late List<Task> observerTasks;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Количество вкладок зависит от роли пользователя
    int tabCount = widget.user.role == "Коммуникатор" ? 4 : 3;
    _tabController = TabController(length: tabCount, vsync: this);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,

        bottom: TabBar(
          controller: _tabController,
          tabs: [
            if (widget.user.role == "Коммуникатор") Tab(text: 'Я коммуникатор'),
            Tab(text: 'Я исполнитель'),
            Tab(text: 'Я постановщик'),
            Tab(text: 'Я наблюдатель'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          if (widget.user.role == "Коммуникатор")
            const Text("Задачи коммуникатора"),
          const Text("Задачи исполнителя"),
          CreaterTasksTab(employeeId: widget.user.user_id),
          const Text("Задачи наблюдателя"),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}