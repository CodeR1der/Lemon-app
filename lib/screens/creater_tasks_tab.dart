import 'package:flutter/material.dart';
import '../models/task_status.dart';
import '../services/task_operations.dart';
import 'category_tasks_list_screen.dart';

class CreaterTasksTab extends StatelessWidget {
  final String employeeId;
  final TaskService _taskOperations = TaskService();

  CreaterTasksTab({Key? key, required this.employeeId}) : super(key: key);

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
          final categories = [
            TaskCategory(title: 'Новые задачи', count: taskCounts[TaskStatus.newTask.displayName] ?? 0, status: TaskStatus.newTask),
            TaskCategory(title: 'Доработать задачу', count: taskCounts[TaskStatus.revision.displayName] ?? 0, status: TaskStatus.revision),
            TaskCategory(title: 'Проверить завершённые задачи', count: taskCounts[TaskStatus.completedUnderReview.displayName] ?? 0, status: TaskStatus.completedUnderReview),
            TaskCategory(title: 'Не прочитано / не понято', count: taskCounts[TaskStatus.notRead.displayName] ?? 0, status: TaskStatus.notRead),
            TaskCategory(title: 'В очереди на выполнение', count: taskCounts[TaskStatus.inOrder.displayName] ?? 0, status: TaskStatus.inOrder),
            TaskCategory(title: 'Сейчас в работе', count: taskCounts[TaskStatus.atWork.displayName] ?? 0, status: TaskStatus.atWork),
            TaskCategory(title: 'Просроченные задачи', count: taskCounts[TaskStatus.overdue.displayName] ?? 0, status: TaskStatus.overdue),
            TaskCategory(title: 'Запросы на дополнительное время', count: taskCounts[TaskStatus.extraTime.displayName] ?? 0, status: TaskStatus.extraTime),
          ];

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
      itemCount: _staticCategories.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final category = _staticCategories[index];
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

  final List<TaskCategory> _staticCategories = [
    TaskCategory(title: 'Новые задачи', count: 0, status: TaskStatus.newTask),
    TaskCategory(title: 'Доработать задачу', count: 0, status: TaskStatus.revision),
    TaskCategory(title: 'Проверить завершённые задачи', count: 0, status: TaskStatus.completedUnderReview),
    TaskCategory(title: 'Не прочитано / не понято', count: 0, status: TaskStatus.notRead),
    TaskCategory(title: 'В очереди на выполнение', count: 0, status: TaskStatus.inOrder),
    TaskCategory(title: 'Сейчас в работе', count: 0, status: TaskStatus.atWork),
    TaskCategory(title: 'Просроченные задачи', count: 0, status: TaskStatus.overdue),
    TaskCategory(title: 'Запросы на дополнительное время', count: 0, status: TaskStatus.extraTime),
  ];
}

class TaskCategory {
  final String title;
  final int count;
  final TaskStatus status;

  TaskCategory({
    required this.title,
    required this.count,
    required this.status,
  });
}