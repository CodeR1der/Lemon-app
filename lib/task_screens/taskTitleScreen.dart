import 'package:flutter/material.dart';
import 'package:task_tracker/models/task_team.dart';
import 'package:task_tracker/services/user_service.dart';
import 'package:uuid/uuid.dart';

import '../models/employee.dart';
import '../models/priority.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../models/task_status.dart';
import 'projectSelectionScreen.dart';

class TaskTitleScreen extends StatefulWidget {
  static const routeName = '/createTaskStart';

  final Employee? employee;

  const TaskTitleScreen({super.key, this.employee});

  @override
  _TaskTitleScreenState createState() => _TaskTitleScreenState();
}

class _TaskTitleScreenState extends State<TaskTitleScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool isRecurring = false; // Переменная для состояния переключателя

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Постановка задачи'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Название задачи',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Название',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Описание задачи',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                hintText: 'Описание',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
              ),
              maxLines: 3, // Для многослойного текстового поля
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_nameController.text.isNotEmpty &&
                      _descriptionController.text.isNotEmpty) {
                    final task = Task(
                      id: const Uuid().v4(),
                      taskName: _nameController.text,
                      description: _descriptionController.text,
                      project: Project(
                        projectId: 'default',
                        name: 'Тестовый проект',
                        team: [],
                        companyId: UserService.to.currentUser!.companyId,
                      ),
                      team: TaskTeam.empty(),
                      startDate: DateTime.now(),
                      endDate: DateTime.now(),
                      priority: Priority.low,
                      attachments: [],
                      status: TaskStatus.newTask,
                      companyId: UserService.to.currentUser!.companyId
                    );

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProjectSelectionScreen(task),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Дальше'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
