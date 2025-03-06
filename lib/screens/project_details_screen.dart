import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:task_tracker/models/project_description.dart';
import 'package:task_tracker/services/project_operations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/project.dart';

class ProjectDetailsScreen extends StatefulWidget {
  final Project project;

  ProjectDetailsScreen({Key? key, required this.project}) : super(key: key);

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<Project_Description?> _projectDescription;


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _projectDescription= ProjectService().getProjectDescription(widget.project.project_id);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(widget.project.name),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Color(0xFF6750A4),
          indicatorColor: Color(0xFF6750A4),
          labelPadding: EdgeInsets.zero,
          tabs: const [
            Tab(text: 'Задачи'),
            Tab(text: 'Команда проекта'),
            Tab(text: 'Описание'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Замените на соответствующие виджеты для каждой вкладки
          Center(child: Text('Содержимое вкладки Задачи')),
          Center(child: Text('Содержимое вкладки Команда проекта')),
          // Вкладка "Описание"
          FutureBuilder<Project_Description?>(
            future: _projectDescription,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Ошибка загрузки данных'));
              } else if (!snapshot.hasData || snapshot.data == null) {
                return Center(child: Text('Данные не найдены'));
              } else {
                final projectDescription = snapshot.data!;
                return SingleChildScrollView(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Описание проекта",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        projectDescription.description,
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 16),

                      Text(
                        "Цели проекта",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        projectDescription.goals,
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 16),

                      Text(
                        "Ссылка на проект",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      InkWell(
                        onTap: () {
                          // Открыть ссылку в браузере
                        },
                        child: Row(
                          children: [
                            Icon(Iconsax.chrome_copy, size: 12),
                            SizedBox(width: 12),
                            InkWell(
                              onTap:() async{
                                _launchUrl(projectDescription.projectLink);
                              },
                              child: Text(
                                projectDescription.projectLink,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            )

                          ]

                        ),
                      ),
                      SizedBox(height: 16),

                      Text(
                        "Социальные сети",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSocialNetworkLink("Facebook", projectDescription.socialNetworks["facebook"]),
                          _buildSocialNetworkLink("Twitter", projectDescription.socialNetworks["twitter"]),
                          _buildSocialNetworkLink("Instagram", projectDescription.socialNetworks["instagram"]),
                          _buildSocialNetworkLink("LinkedIn", projectDescription.socialNetworks["linkedin"]),
                        ],
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
  Widget _buildSocialNetworkLink(String networkName, String? link) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: InkWell(
        onTap: () {
          if (link != null) {
            // Открыть ссылку в браузере
          }
        },
        child: Text(
          "$networkName: ${link ?? 'Не указано'}",
          style: TextStyle(
            fontSize: 16,
            color: link != null ? Colors.blue : Colors.grey,
            decoration: link != null ? TextDecoration.underline : TextDecoration.none,
          ),
        ),
      ),
    );
  }
  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }
}