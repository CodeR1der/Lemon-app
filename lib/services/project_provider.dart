import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/employee.dart';
import '../models/project.dart';
import '../models/project_description.dart';
import '../services/project_operations.dart';

class ProjectProvider with ChangeNotifier {
  final ProjectService _projectService = ProjectService();
  List<Project> _projects = [];
  bool _isLoading = false;
  String? _error;

  List<Project> get projects => _projects;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadProjects() async {
    try {
      _isLoading = true;
      notifyListeners();

      final projects = await _projectService.getAllProjects();
      _projects = projects;
      _error = null;
    } catch (e) {
      _error = e.toString();
      Get.snackbar('Ошибка', 'Не удалось загрузить проекты: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addProject({
    required String? logo,
    required String name,
    required String description,
    required String goals,
    required String projectLink,
    Map<String, dynamic>? socialNetworks,
    required String companyId,
    List<Employee>? team,
  }) async {
    try {

      _isLoading = true;
      notifyListeners();

      // Создаем ProjectDescription
      final projectDescription = ProjectDescription(
        projectDescriptionId: '', // Supabase сгенерирует ID
        description: description,
        goals: goals,
        projectLink: projectLink,
        companyId: companyId,
      );

      // Создаем Project с пустым team (можно расширить позже)
      final project = Project(
        projectId: '', // Supabase сгенерирует ID
        name: name,
        avatarUrl: logo,
        projectDescription: projectDescription,
        team: team!.isNotEmpty ? team : [],
        companyId: companyId
      );

      await _projectService.addProject(project);

      await loadProjects(); // Обновляем список после добавления
      _error = null;
    } catch (e) {
      _error = e.toString();
      Get.snackbar('Ошибка', 'Не удалось добавить проект: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}