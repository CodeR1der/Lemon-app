import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:task_tracker/models/priority.dart';
import 'package:task_tracker/models/task_status.dart';

import '../models/task.dart';
import '../models/task_role.dart';
import '../services/task_operations.dart';
import 'choose_task_deadline_screen.dart';

class QueueScreen extends StatefulWidget {
  final Task task;

  const QueueScreen({super.key, required this.task});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  late Future<List<Task>> _queuedTasks;
  final TaskService _taskService = TaskService();
  int? _selectedPosition;

  @override
  void initState() {
    super.initState();
    _loadQueuedTasks();
  }

  void _loadQueuedTasks() {
    setState(() {
      _queuedTasks = _taskService.getTasksByStatus(
        position: RoleHelper.determineUserRoleInTask(task: widget.task, currentUserId: widget.task.team.teamMembers.first.userId).toString(),
        status: TaskStatus.queue,
        employeeId: widget.task.team.teamMembers.first.userId,
      );
    });
  }

  String formatDeadline(DateTime? dateTime) {
    final dateFormat = DateFormat('dd.MM.yyyy');
    final timeFormat = DateFormat('HH:mm');

    return '${dateFormat.format(dateTime!)}, до ${timeFormat.format(dateTime)}';
  }

  Future<void> _addToQueue(int selectedPosition) async {
    try {
      // Получаем список задач из Future
      final tasks = await _queuedTasks ?? [];

      // Обновляем позиции существующих задач
      for (var task in tasks) {
        if (int.parse(task.queuePosition!)  >= selectedPosition) {
          task.queuePosition = (int.parse(task.queuePosition!)+1).toString();
          await _taskService.updateTask(task); // Обновляем задачу в Supabase
        }
      }

      // Устанавливаем позицию и статус для новой задачи
      widget.task.queuePosition = selectedPosition.toString();
      widget.task.status = TaskStatus.queue;
      await _taskService.updateTask(widget.task); // Сохраняем новую задачу

      // Перезагружаем список задач
      _loadQueuedTasks();
    } catch (e) {
      // Обработка ошибок
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при добавлении в очередь: $e')),
      );
    }
  }
  void _showPositionSelectionDialog(int tasksCount) {
    final maxPosition = tasksCount + 1;
    const itemHeight = 48.0;
    const headerHeight = 80.0;

    final contentHeight = headerHeight +
        ( maxPosition * itemHeight);


    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: contentHeight,
        minHeight: 100,
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: maxPosition,
                  itemBuilder: (context, index) {
                    final position = index + 1;
                    return RadioListTile<int>(
                      title: Text('$position'),
                      value: position,
                      groupValue: _selectedPosition,
                      onChanged: (value) {
                        if (value != null) {
                          _addToQueue(value);
                          Navigator.pop(context);
                          widget.task.changeStatus(TaskStatus.queue);
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Очередь задач'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Task>>(
        future: _queuedTasks,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }

          final tasks = snapshot.data ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Карточка текущей задачи
                _buildTaskCard(
                  task: widget.task,
                  count: tasks.length
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Divider(),
                ),

                // Список задач в очереди
                if (tasks.isEmpty)
                  const Center(child: Text('Нет задач в очереди'))
                else
                  ...tasks.asMap().entries.map((entry) {
                    final queueTask = entry.value;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: _buildQueueCard(
                        queueNumber: queueTask.queuePosition,
                        title: queueTask.taskName,
                        deadline: queueTask.endDate,
                        priority:  queueTask.priority,
                        project: queueTask.project!.name,
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTaskCard({
    required Task task,
    required int count,
  }) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Статус', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEBEDF0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  StatusHelper.getStatusIcon(task.status),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  StatusHelper.displayName(task.status),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Название задачи',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            task.taskName,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          Text(
            'Проект',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            task.project!.name,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),

          if(task.deadline != null) ...[
            Text(
              'Сделать до',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              formatDeadline(task.deadline),
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 16),

            ElevatedButton(
            onPressed: () {
              _showPositionSelectionDialog(count);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: 8),
                Text(
                  'Выставить в очередь',
                  style: TextStyle(
                    color: Colors.white, // Белый текст
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),]
          else ...[
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TaskCompletionPage(task: task),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 8),
                  Text(
                    'Выставить дату завершения задачи',
                    style: TextStyle(
                      color: Colors.white, // Белый текст
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ]

        ]),
      ),
    );
  }

  Widget _buildQueueCard({
    required String? queueNumber,
    required String title,
    required DateTime deadline,
    Priority? priority,
    String? project,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Очередность задачи',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Text(
                queueNumber!,
                style: const TextStyle(
                  fontSize: 14.0,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              'Название задачи',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 16),
            ),
            if (project != null) ...[
              const SizedBox(height: 8),
              Text(
                'Проект: $project',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
            if (deadline != null) ...[
              const SizedBox(height: 8),
              Text(
                formatDeadline(widget.task.deadline),
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
            if (priority != null) ...[
              const SizedBox(height: 8),
              Text(
                'Приоритет: $priority',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Логика выставления в очередь
                },
                child: const Text('Изменить очередность'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
