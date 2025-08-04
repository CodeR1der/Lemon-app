import 'package:flutter/material.dart';
import 'package:task_tracker/models/task_team.dart';
import 'package:task_tracker/services/user_service.dart';
import 'package:task_tracker/widgets/common/app_common.dart';
import 'package:uuid/uuid.dart';

import '../models/employee.dart';
import '../models/priority.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../models/task_status.dart';
import 'added_files_screen.dart';
import 'project_selection_screen.dart';

class TaskTitleScreen extends StatefulWidget {
  static const routeName = '/createTaskStart';

  final Employee? employee;
  final Project? project;

  const TaskTitleScreen({super.key, this.employee, this.project});

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

  void _navigateToNextScreen(Task task) {
    // Логика навигации в зависимости от контекста
    if (widget.project != null) {
      // Если проект уже выбран, пропускаем экран выбора проекта
      task.project = widget.project!;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddedFilesScreen(task),
        ),
      );
    } else {
      // Если проект не выбран, идем на экран выбора проекта
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProjectSelectionScreen(
            task,
            preSelectedEmployee: widget.employee,
          ),
        ),
      );
    }
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
            // повторяющееся обязательство
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //   children: [
            //     Text(
            //       'Повторяющаяся обязательство',
            //       style: TextStyle(fontSize: 16, color: Colors.grey[800]),
            //     ),
            //     Switch(
            //       value: isRecurring,
            //       onChanged: (value) {
            //         setState(() {
            //           isRecurring = value;
            //         });
            //       },
            //     ),
            //   ],
            // ),
            const SizedBox(height: 16),
            Text(
              'Название задачи',
              style: AppTextStyles.titleSmall,
            ),
            const SizedBox(height: 8),
            AppCommonWidgets.inputField(controller: _nameController, hintText: 'Название'),
            const SizedBox(height: 16),
            Text(
              'Описание задачи',
              style: AppTextStyles.titleSmall,
            ),
            const SizedBox(height: 8),
            AppCommonWidgets.inputField(controller: _descriptionController, hintText: 'Описание'),
            const Spacer(),
            AppButtons.primaryButton(text: 'Дальше', onPressed: (){
              if (_nameController.text.isNotEmpty &&
                  _descriptionController.text.isNotEmpty) {
                final task = Task(
                    id: const Uuid().v4(),
                    taskName: _nameController.text,
                    description: _descriptionController.text,
                    project: widget.project ??
                        Project(
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
                    companyId: UserService.to.currentUser!.companyId);

                _navigateToNextScreen(task);
              }
            } )
          ],
        ),
      ),
    );
  }
}
