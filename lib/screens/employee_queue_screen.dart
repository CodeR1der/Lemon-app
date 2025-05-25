import 'package:flutter/material.dart';
import 'package:task_tracker/screens/tasks_list_screen.dart';

import '../models/task_role.dart';
import '../models/task_status.dart';

class QueueScreen extends StatelessWidget {
  final String position;
  final String userId;

  const QueueScreen({
    Key? key,
    required this.position,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('В очереди на выполнение'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Возврат на предыдущую страницу
          },
        ),
      ),
      body:
      Column(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Секция "В очереди на выполнение"
                  Row(
                    children: [
                      const Text(
                        'Не выставлена задача',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '1', // Количество задач, можно сделать динамическим
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TaskListByStatusScreen(
                    position: TaskRole.executor.toString().substring(11),
                    userId: userId,
                    status: TaskStatus.inOrder,
                  ),

                  // Разделитель
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Divider(),
                  ),

                  // Секция "Очередность задач"
                  Row(
                    children: [
                      const Text(
                        'В очереди на выполнение',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '2', // Количество задач, можно сделать динамическим
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TaskListByStatusScreen(
                    position: TaskRole.executor.toString().substring(11),
                    userId: userId,
                    status: TaskStatus.queue,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
