import 'package:flutter/material.dart';
import 'package:task_tracker/screens/position_tasks_tab.dart';
import 'package:task_tracker/services/task_categories.dart';

import '../models/employee.dart';
import '../models/task_category.dart';

class TasksScreen extends StatefulWidget {
  final Employee user;

  const TasksScreen({required this.user, Key? key}) : super(key: key);

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with SingleTickerProviderStateMixin {
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
          isScrollable: true,
          tabAlignment: TabAlignment.start,
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
            _buildFutureTab("Коммуникатор", widget.user.userId),
          _buildFutureTab("Исполнитель", widget.user.userId),
          _buildFutureTab("Постановщик", widget.user.userId),
          _buildFutureTab("Наблюдатель", widget.user.userId),
        ],
      ),
    );
  }

  Widget _buildFutureTab(String position, String employeeId) {
    return FutureBuilder<List<TaskCategory>>(
      future: TaskCategories().getCategories(position, employeeId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Ошибка: ${snapshot.error}'));
        } else if (!snapshot.hasData) {
          return const Center(child: Text('Нет данных'));
        }

        return PositionTasksTab(
          position: position,
          employeeId: employeeId,
          categories: snapshot.data!,
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
