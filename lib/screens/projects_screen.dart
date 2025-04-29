import 'package:flutter/material.dart';
import 'package:task_tracker/screens/project_details_screen.dart';

import '/models/project.dart';
import '/services/project_operations.dart';

class ProjectScreen extends StatefulWidget {
  @override
  _ProjectScreenState createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> {
  final ProjectService _projectService = ProjectService();
  List<Project> _projects = [];

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    final projects = await _projectService.getAllProjects();
    setState(() {
      _projects = projects;
    });
  }

  void _openProjectDetails(Project project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProjectDetailsScreen(project: project),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _projects.isEmpty
            ? Center(child: CircularProgressIndicator())
            : GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.5, // Пропорции плитки
                ),
                itemCount: _projects.length,
                itemBuilder: (context, index) {
                  final project = _projects[index];
                  return GestureDetector(
                    onTap: () => _openProjectDetails(project),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        // Прижимаем элементы к левой стороне
                        children: [
                          // Картинка (аватар)
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            // Отступы вокруг аватара
                            child: CircleAvatar(
                              radius: 20, // Размер аватара
                              backgroundImage: project.avatarUrl != null
                                  ? NetworkImage(_projectService
                                      .getAvatarUrl(project.avatarUrl))
                                  : null,
                              child: project.avatarUrl == null
                                  ? Icon(Icons.business,
                                      size: 20, color: Colors.grey)
                                  : null,
                            ),
                          ),
                          // Название проекта
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            // Отступы вокруг текста
                            child: Text(
                              project.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.left,
                              // Выравнивание текста по левой стороне
                              overflow: TextOverflow
                                  .ellipsis, // Обрезание текста, если он слишком длинный
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
