import 'package:flutter/material.dart';
import 'package:task_tracker/screens/tasks_list_screen.dart';

import '../models/task_category.dart';
import '../models/task_role.dart';
import '../models/task_status.dart';
import 'employee_queue_screen.dart';

class PositionTasksTab extends StatelessWidget {
  final String? position;
  final String? employeeId;
  final String? projectId;
  final List<TaskCategory> categories;

  const PositionTasksTab({
    Key? key,
    this.position,
    this.employeeId,
    this.projectId,
    required this.categories,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView.separated(
        padding: const EdgeInsets.all(1.0),
        itemCount: categories.length,
        separatorBuilder: (context, index) => const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0), // Добавляем отступы по бокам
          child: Divider(),
        ),
        itemBuilder: (context, index) {
          final category = categories[index];
          return _buildCategoryItem(context, category);
        },
      ),
    );
  }

  Widget _buildCategoryItem(BuildContext context, TaskCategory category) {
    final icon = StatusHelper.getStatusIcon(category.status);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      leading: Icon(icon, color: Colors.blue),
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
      onTap: () => _handleCategoryTap(context, category),
    );
  }

  void _handleCategoryTap(BuildContext context, TaskCategory category) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      Navigator.of(context).pop();

      if (projectId != null) {
        // Навигация для проекта
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskListByStatusScreen(
              projectId: projectId!,
              status: category.status,
            ),
          ),
        );
      } else if (position != null && employeeId != null) {
        if((position == RoleHelper.convertToString(TaskRole.executor) || position == RoleHelper.convertToString(TaskRole.creator)) && category.status == TaskStatus.queue){
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QueueScreen(
                position: position!,
                userId: employeeId!,
              ),
            ),
          );
        }
        else{// Навигация для сотрудника
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskListByStatusScreen(
                position: position!,
                userId: employeeId!,
                status: category.status,
              ),
            ),
          );
        }
      }

    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки задач: ${e.toString()}')),
      );
    }
  }
}