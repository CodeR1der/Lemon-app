import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_tracker/screens/task/task_details_screen.dart';

import '../models/task.dart';
import '../models/task_status.dart';
import '../services/task_operations.dart';
import '../services/task_provider.dart';

class QueueScreen extends StatefulWidget {
  final String position;
  final String userId;

  const QueueScreen({
    super.key,
    required this.position,
    required this.userId,
  });

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  late Future<List<List<Task>>> _tasksFuture;

  @override
  void initState() {
    super.initState();
    _tasksFuture = _loadTasks();
  }

  Future<List<List<Task>>> _loadTasks() async {
    final tasksInOrder = await TaskService().getTasksByStatus(
      position: widget.position,
      status: TaskStatus.inOrder,
      employeeId: widget.userId,
    );

    final tasksQueue = await TaskService().getTasksByStatus(
      position: widget.position,
      status: TaskStatus.queue,
      employeeId: widget.userId,
    );

    return [tasksInOrder, tasksQueue];
  }

  Widget _buildTaskCard(Task task) {
    // Безопасное получение queuePosition
    final queuePosition = task.queuePosition;
    final queuePositionInt =
        queuePosition != null ? int.tryParse(queuePosition) : null;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskDetailsScreen(task: task),
          ),
        );
      },
      child: Card(
        color: Colors.white,
        elevation: 1,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Статус задачи
              Text(
                'Статус',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const CircleAvatar(radius: 16, backgroundColor: Colors.blue),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBEDF0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(StatusHelper.getStatusIcon(task.status), size: 16),
                        const SizedBox(width: 6),
                        Text(StatusHelper.displayName(task.status),
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Очередность задачи (только для задач в очереди)
              if (task.status == TaskStatus.queue && queuePosition != null) ...[
                Text(
                  'Очередность задачи',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBEDF0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    queuePosition,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.black,
                        ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Название задачи
              Text(
                'Название задачи',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                task.taskName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black,
                    ),
              ),
              const SizedBox(height: 16),

              // Проект
              Text(
                'Проект',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                task.project?.name ?? 'Не указан',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black,
                    ),
              ),

              if (queuePositionInt == 1) ...[
                const SizedBox(height: 16),
                Consumer<TaskProvider>(
                  builder: (context, taskProvider, child) => ElevatedButton(
                    onPressed: () {
                      TaskService()
                          .updateQueuePosTask(task..queuePosition = null);
                      taskProvider.updateTaskStatus(task, TaskStatus.atWork);
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
                          'Взять задачу в работу',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('В очереди на выполнение'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        top: false,
        child: FutureBuilder<List<List<Task>>>(
          future: _tasksFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                  child: Text('Ошибка загрузки задач: ${snapshot.error}'));
            }

            final tasksInOrder = snapshot.data![0];
            final tasksQueue = snapshot.data![1];

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  if (tasksInOrder.isNotEmpty) ...[
                    const Row(
                      children: [
                        Text('В очереди на выполнение',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...tasksInOrder.map(_buildTaskCard),
                  ],
                  if (tasksQueue.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        Text('В очереди на подтверждение',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...tasksQueue.map(_buildTaskCard),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
