import 'package:flutter/material.dart';
import 'package:task_tracker/services/project_operations.dart';
import 'package:task_tracker/task_screens/addedFilesScreen.dart';

import '../models/project.dart';
import '../models/task.dart';

class ProjectSelectionScreen extends StatefulWidget {
  final Task taskData;
  final ProjectService projectService;

  ProjectSelectionScreen(
    this.taskData, {
    super.key,
    ProjectService? projectService,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Выбор проекта'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<Project>>(
          future: projectsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Ошибка загрузки проектов'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('Нет доступных проектов'));
            }

            final projects = snapshot.data!;

            return Column(
              children: <Widget>[
                const Text('Выберите проект:'),
                Expanded(
                  child: ListView.builder(
                    itemCount: projects.length,
                    itemBuilder: (context, index) {
                      final project = projects[index];
                      return RadioListTile<Project>(
                        title: Text(project.name),
                        value: project,
                        groupValue: selectedProject,
                        onChanged: (Project? value) {
                          setState(() {
                            selectedProject =
                                value; // Обновляем выбранный проект
                          });
                        },
                        activeColor: Colors.blue,
                      );
                    },
                  ),
                ),
                const Spacer(), // Отодвигает кнопку вниз
                SizedBox(
                  width: double.infinity, // Кнопка растягивается на всю ширину
                  child: ElevatedButton(
                    onPressed: selectedProject == null
                        ? null
                        : () {
                            // Обработка перехода к следующему экрану
                            widget.taskData.project = selectedProject!;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AddedFilesScreen(widget.taskData),
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Продолжить'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
