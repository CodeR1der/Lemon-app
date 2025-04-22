import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/employee.dart';
import '../models/project.dart';
import '../models/task_status.dart';
import 'projectSelectionScreen.dart';
import '../models/task.dart';
import '../models/priority.dart';

class TaskTitleScreen extends StatefulWidget {
  final Employee? employee;
  TaskTitleScreen({Key? key, this.employee}) : super(key: key);

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Повторяющаяся обязательство',
                  style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                ),
                Switch(
                  value: isRecurring,
                  onChanged: (value) {
                    setState(() {
                      isRecurring = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
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
                  borderSide: BorderSide(color: Colors.grey),
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
                  borderSide: BorderSide(color: Colors.grey),
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
                        project_id: 'default',
                        name: 'Тестовый проект',
                        observers: [],
                      ),
                      team: [],
                      startDate: DateTime.now(),
                      endDate: DateTime.now(),
                      priority: Priority.low,
                      attachments: [],
                      status: TaskStatus.newTask,
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
