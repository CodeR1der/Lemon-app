import 'package:flutter/material.dart';
import 'package:task_tracker/screens/tasks_list_screen.dart';

import '../models/task_category.dart';
import '../models/task_status.dart';
import '../services/task_operations.dart';

class PositionTasksTab extends StatelessWidget {
  final String position;
  final String employeeId;
  final List<TaskCategory> categories;
  final TaskService _taskOperations = TaskService();

  PositionTasksTab(
      {Key? key,
      required this.position,
      required this.employeeId,
      required this.categories})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView.separated(
        padding: const EdgeInsets.all(1.0),
        itemCount: categories.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final category = categories[index];
          return _buildCategoryItem(context, category);
        },
      ),
    );
  }

  Widget _buildCategoryItem(BuildContext context, TaskCategory category) {
    // Получаем иконку для статуса
    final icon = StatusHelper.getStatusIcon(category.status);

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      leading: Icon(icon, color: Colors.blue),
      // Простая иконка без кружка
      title: Text(
        category.title,
        style: const TextStyle(fontSize: 16.0),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Text(
          category.count.toString(),
          style: const TextStyle(
            fontSize: 14.0,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      onTap: () async {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );

        try {
          Navigator.of(context).pop();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskListByStatusScreen(
                position: position,
                userId: employeeId,
                status: category.status,
              ),
            ),
          );
        } catch (e) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка загрузки задач: ${e.toString()}')),
          );
        }
      },
    );
  }
}
