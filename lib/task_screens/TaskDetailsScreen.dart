import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/task_operations.dart';
import 'TaskChatTab.dart';
import 'TaskDescriptionTab.dart';
import 'TaskPeriodTab.dart';
import 'TaskTeamTab.dart';

class TaskDetailsScreen extends StatefulWidget {
  final String id;

  const TaskDetailsScreen({super.key, required this.id});

  @override
  _TaskDetailsScreenState createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  final TaskService _database = TaskService();
  late Future<Task> _task;

  @override
  void initState() {
    super.initState();
    // Подгружаем задачу при инициализации
    _task = _database.getTask(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Task>(
      future: _task, // Асинхронно загружаем задачу
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Пока задача загружается, показываем индикатор загрузки
          return Scaffold(
            appBar: AppBar(
              title: const Text('Детали задачи'),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          // Если возникла ошибка при загрузке задачи
          return Scaffold(
            appBar: AppBar(
              title: const Text('Детали задачи'),
            ),
            body: Center(child: Text('Ошибка: ${snapshot.error}')),
          );
        } else if (!snapshot.hasData) {
          // Если данных нет
          return Scaffold(
            appBar: AppBar(
              title: const Text('Детали задачи'),
            ),
            body: const Center(child: Text('Задача не найдена')),
          );
        }

        final task = snapshot.data!; // Получаем данные задачи

        return DefaultTabController(
          length: 4, // Количество вкладок
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Детали задачи'),
              bottom: const TabBar(
                isScrollable: true,
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
                TaskDescriptionTab(task: task), // Передаем задачу
                ChatTab(), // Поставьте сюда виджет чата
                TaskPeriodTab(task: task), // Поставьте сюда виджет срочности
                TaskTeamTab(task: task), // Поставьте сюда виджет команды
              ],
            ),
          ),
        );
      },
    );
  }
}
