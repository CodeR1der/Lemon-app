import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:task_tracker/models/task_status.dart';

import '../models/task.dart';
import '../models/task_role.dart';
import '../services/task_operations.dart';
import '../services/task_provider.dart';
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
  late Task _currentTask; // Локальная копия задачи для обновления

  @override
  void initState() {
    super.initState();
    _currentTask = widget.task; // Инициализируем текущую задачу
    _loadQueuedTasks();

    // Если у задачи есть дедлайн, показываем уведомление
    if (_currentTask.deadline != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Дедлайн установлен. Теперь можно добавить задачу в очередь')),
        );
      });
    }
  }

  void _loadQueuedTasks() {
    setState(() {
      // Используем TaskProvider для получения задач
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      final tasks = taskProvider.getTasksByStatus(
        TaskStatus.queue,
        position: RoleHelper.convertToString(RoleHelper.determineUserRoleInTask(
            task: _currentTask,
            currentUserId: _currentTask.team.teamMembers.first.userId)),
        userId: _currentTask.team.teamMembers.first.userId,
      );
      _queuedTasks = Future.value(tasks);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Перезагружаем задачи при изменении зависимостей (например, при обновлении TaskProvider)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadQueuedTasks();
    });
  }

  String formatDeadline(DateTime? dateTime) {
    if (dateTime == null) return 'Не указана';
    final dateFormat = DateFormat('dd.MM.yyyy');
    final timeFormat = DateFormat('HH:mm');
    return '${dateFormat.format(dateTime)}, до ${timeFormat.format(dateTime)}';
  }

  Future<void> _addToQueue(int selectedPosition) async {
    try {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      final tasks = await _queuedTasks ?? [];

      // Обновляем позиции существующих задач
      for (var task in tasks) {
        if (int.parse(task.queuePosition!) >= selectedPosition) {
          final updatedTask = task.copyWith(
            queuePosition: (int.parse(task.queuePosition!) + 1).toString(),
          );
          await taskProvider.updateTask(updatedTask);
        }
      }

      // Обновляем текущую задачу
      final updatedCurrentTask = _currentTask.copyWith(
        queuePosition: selectedPosition.toString(),
        status: TaskStatus.queue,
      );

      await taskProvider.updateTask(updatedCurrentTask);
      setState(() {
        _currentTask = updatedCurrentTask;
      });

      // Перезагружаем список задач
      _loadQueuedTasks();

      // Показываем уведомление об успехе
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Задача добавлена в очередь')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при добавлении в очередь: $e')),
      );
    }
  }

  void _showPositionSelectionDialog(int tasksCount) {
    final maxPosition = tasksCount + 1;
    const itemHeight = 48.0;
    const headerHeight = 80.0;

    final contentHeight = headerHeight + (maxPosition * itemHeight);

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
                    return Consumer<TaskProvider>(
                      builder: (context, taskProvider, child) =>
                          RadioListTile<int>(
                        title: Text('$position'),
                        value: position,
                        groupValue: _selectedPosition,
                        onChanged: (value) async {
                          if (value != null) {
                            await _addToQueue(value);
                            Navigator.pop(context);
                          }
                        },
                      ),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Возвращаемся к предыдущему экрану с обновленной задачей
            if (widget.task.deadline == null && _currentTask.deadline != null) {
              // Если дедлайн был установлен на этом экране, возвращаем обновленную задачу
              Navigator.pop(context, _currentTask);
            } else {
              // Иначе просто возвращаемся назад
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        top: false,
        child: FutureBuilder<List<Task>>(
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
                  if (_currentTask.status == TaskStatus.inOrder) ...[
                    _buildTaskCard(task: _currentTask, count: tasks.length),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Divider(),
                    ),
                  ],
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
                          deadline: queueTask.deadline,
                          priority: queueTask.priorityToString(),
                          project: queueTask.project!.name,
                        ),
                      );
                    }),
                ],
              ),
            );
          },
        ),
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
          if (task.deadline != null) ...[
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
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            ElevatedButton(
              onPressed: () async {
                final deadline = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        TaskCompletionPage(task: _currentTask),
                  ),
                );
                if (deadline != null) {
                  final taskProvider =
                      Provider.of<TaskProvider>(context, listen: false);
                  final updatedTask = _currentTask.copyWith(deadline: deadline);
                  await taskProvider.updateTask(updatedTask);
                  setState(() {
                    _currentTask = updatedTask;
                  });

                  // Показываем уведомление об успехе
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Дедлайн установлен. Теперь можно добавить задачу в очередь')),
                  );
                }
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
                      color: Colors.white,
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
    required DateTime? deadline,
    String? priority,
    String? project,
  }) {
    return Card(
      color: Colors.white,
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
                queueNumber ?? 'Не указана',
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
            if (deadline != null) ...[
              Text(
                'Сделать до',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Iconsax.calendar),
                  const SizedBox(width: 4),
                  Text(
                    formatDeadline(deadline),
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ],
            if (project != null) ...[
              const SizedBox(height: 8),
              Text(
                'Проект:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                project,
                style: const TextStyle(fontSize: 16),
              ),
            ],
            if (priority != null) ...[
              const SizedBox(height: 8),
              Text(
                'Приоритет:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Iconsax.flash_1, color: Colors.yellow),
                  const SizedBox(width: 4),
                  Text(
                    priority,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.orange, width: 1),
                backgroundColor: Colors.white,
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
                    'Изменить очередность',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
