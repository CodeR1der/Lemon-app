import 'package:flutter/material.dart';
import '../models/task_category.dart';
import '../models/task_status.dart';
import '../services/task_operations.dart';
import 'category_tasks_list_screen.dart';

class PositionTasksTab extends StatelessWidget {
  final String employeeId;
  final List<TaskCategory> categories;
  final TaskService _taskOperations = TaskService();

  PositionTasksTab({Key? key, required this.employeeId, required this.categories}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<Map<String, int>>(
        future: _taskOperations.getCountOfTasksByStatus('Постановщик', employeeId),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done || snapshot.hasError) {
            return _buildStaticContent();
          }

          final taskCounts = snapshot.data ?? {};

          return ListView.separated(
            padding: const EdgeInsets.all(1.0),
            itemCount: categories.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final category = categories[index];
              return _buildCategoryItem(context, category);
            },
          );
        },
      ),
    );
  }

  Widget _buildStaticContent() {
    return ListView.separated(
      padding: const EdgeInsets.all(1.0),
      itemCount: categories.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryItem(context, category);
      },
    );
  }

  Widget _buildCategoryItem(BuildContext context, TaskCategory category) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      title: Text(
        category.title,
        style: const TextStyle(fontSize: 18.0),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: Colors.black12,
              width: 1.0,
            )
        ),
        child: Text(
          category.count.toString(),
          style: const TextStyle(
            fontSize: 16.0,
            color: Colors.black,
          ),
        ),
      ),
      onTap: () async {
        // Показываем индикатор загрузки
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );

        try {
          // Получаем задачи для выбранной категории
          final tasks = await _taskOperations.getTasksByStatus(
              position: 'Постановщик',
              status: category.status,
              employeeId: employeeId
          );

          // Закрываем индикатор загрузки
          Navigator.of(context).pop();

          // Переходим на экран списка задач
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CategoryTasksListScreen(
                categoryTitle: category.title,
                tasks: tasks,
              ),
            ),
          );
        } catch (e) {
          // Закрываем индикатор загрузки и показываем ошибку
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка загрузки задач: ${e.toString()}')),
          );
        }
      },
    );
  }
}