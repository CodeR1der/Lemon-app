import 'package:flutter/material.dart';
import 'package:task_tracker/services/project_operations.dart';
import 'package:task_tracker/task_screens/added_files_screen.dart';
import 'package:task_tracker/widgets/common/app_common.dart';
import 'package:uuid/uuid.dart';

import '../models/employee.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../models/task_team.dart';
import '../services/user_service.dart';

class ProjectSelectionScreen extends StatefulWidget {
  final Task taskData;
  final Employee?
      preSelectedEmployee; // Добавляем предварительно выбранного сотрудника
  final ProjectService projectService;

  ProjectSelectionScreen(
    //
    this.taskData, {
    super.key,
    ProjectService? projectService,
    this.preSelectedEmployee,
  }) : projectService = projectService ?? ProjectService();

  @override
  _ProjectSelectionScreenState createState() => _ProjectSelectionScreenState();
}

class _ProjectSelectionScreenState extends State<ProjectSelectionScreen> {
  late Future<List<Project>> projectsFuture;
  Project? selectedProject;

  @override
  void initState() {
    super.initState();
    projectsFuture = widget.projectService.getAllProjects();
  }

  void _navigateToNextScreen() {
    if (selectedProject == null) return;

    // Обновляем проект в задаче
    widget.taskData.project = selectedProject!;

    // Если есть предварительно выбранный сотрудник, создаем команду и пропускаем экран выбора сотрудников
    if (widget.preSelectedEmployee != null) {
      _createTeamWithPreSelectedEmployee();
    } else {
      // Иначе идем на экран выбора сотрудников
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddedFilesScreen(widget.taskData),
        ),
      );
    }
  }

  void _createTeamWithPreSelectedEmployee() {
    final projectTeam = selectedProject!.team;
    final communicators =
        projectTeam.where((e) => e.role == 'Коммуникатор').toList();

    if (communicators.isNotEmpty) {
      final team = TaskTeam(
        teamId: const Uuid().v4(),
        taskId: widget.taskData.id,
        communicatorId: communicators.first,
        creatorId: UserService.to.currentUser!,
        observerId: null,
        teamMembers: [widget.preSelectedEmployee!],
      );

      widget.taskData.team = team;

      // Переходим к экрану добавления файлов
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddedFilesScreen(widget.taskData),
        ),
      );
    } else {
      // Если нет коммуникаторов, показываем ошибку
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('В проекте нет коммуникаторов')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Выборите проект'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<Project>>(
          future: projectsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return const Center(child: Text('Ошибка загрузки проектов'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('Нет доступных проектов'));
            }

            final projects = snapshot.data!;

            return Column(
              children: <Widget>[
                Expanded(
                  child: ListView.builder(
                    itemCount: projects.length,
                    itemBuilder: (context, index) {
                      final project = projects[index];
                      return RadioListTile<Project>(
                        title: Text(project.name, style: AppTextStyles.bodyLarge,),
                        value: project,
                        groupValue: selectedProject,
                        onChanged: (Project? value) {
                          setState(() {
                            selectedProject =
                                value; // Обновляем выбранный проект
                          });
                        },
                        radioScaleFactor: 1.2,
                        activeColor: Colors.blue,
                      );
                    },
                  ),
                ),
                const Spacer(), // Отодвигает кнопку вниз
                SizedBox(
                  width: double.infinity, // Кнопка растягивается на всю ширину
                  child:
                      AppButtons.primaryButton(text: 'Продолжить', onPressed: _navigateToNextScreen)
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
