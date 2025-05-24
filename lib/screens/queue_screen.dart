import 'package:flutter/material.dart';
import 'package:task_tracker/models/priority.dart';
import 'package:task_tracker/models/task_status.dart';
import 'package:task_tracker/services/user_service.dart';

import '../models/task.dart';
import '../services/task_operations.dart';

class QueueScreen extends StatefulWidget {
  final Task task;

  const QueueScreen({super.key, required this.task});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  late Future<List<Task>> _queuedTasks;
  final TaskService _taskService = TaskService();

  @override
  void initState() {
    super.initState();
    _loadQueuedTasks();
  }

  void _loadQueuedTasks() {
    setState(() {
      _queuedTasks = _taskService.getTasksByStatus(
        position: UserService.to.currentUser!.role,
        status: TaskStatus.queue,
        employeeId: UserService.to.currentUser!.userId,
      );
    });
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
                  status: widget.task.status,
                  title: widget.task.taskName,
                  project: widget.task.project?.name ?? 'Без проекта',
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
    required TaskStatus status,
    required String title,
    required String project,
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
                  StatusHelper.getStatusIcon(status),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  StatusHelper.displayName(status),
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
            title,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          Text(
            'Проект',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            project,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {

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
          ),
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
                'Сделать до: $deadline',
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
