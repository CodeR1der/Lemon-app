import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '/models/project.dart';
import '/services/user_service.dart';
import '../../services/project_provider.dart';
import '../../widgets/common/app_buttons.dart';
import 'add_project_screen.dart';
import 'project_details_screen.dart';

class ProjectScreen extends StatelessWidget {
  const ProjectScreen({super.key});

  void _openProjectDetails(BuildContext context, Project project) {
    Get.to(() => ProjectDetailsScreen(project: project));
  }

  void _openAddProjectScreen(BuildContext context) {//
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddProjectScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userService = UserService.to;

    return Consumer<ProjectProvider>(
      builder: (context, provider, child) {
        final isDirector = userService.currentUser?.role == 'Директор';
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            top: true,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.projects.isEmpty
                  ? const Center(
                child: Text(
                  'Нет проектов',
                  style:
                  TextStyle(fontSize: 18, color: Colors.grey),
                ),
              )
                  : GridView.builder(
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.5,
                ),
                itemCount: provider.projects.length,
                itemBuilder: (context, index) {
                  final project = provider.projects[index];
                  return GestureDetector(
                    onTap: () =>
                        _openProjectDetails(context, project),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: CircleAvatar(
                              radius: 20,
                              backgroundImage: project.avatarUrl !=
                                  null
                                  ? NetworkImage(project.avatarUrl!)
                                  : null,
                              child: project.avatarUrl == null
                                  ? const Icon(Icons.business,
                                  size: 20, color: Colors.grey)
                                  : null,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0),
                            child: Text(
                              project.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.left,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          bottomSheet: isDirector
              ?
          Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(
                  vertical: 24, horizontal: 16),
              width: double.infinity,
              child: AppButtons.primaryButton(text: 'Добавить проект',
                  icon: Iconsax.box_add,
                  onPressed: () => _openAddProjectScreen(context))
          )
              : null,
        );
      },
    );
  }
}
