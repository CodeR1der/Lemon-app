import 'dart:io';

import 'package:path/path.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '/models/project.dart';
import '../models/project_description.dart';
import '../models/task_status.dart';

class ProjectService {
  final SupabaseClient _client = Supabase.instance.client;
  final _uuid = Uuid();

  // Добавление проекта в Supabase
  Future<void> addProject(Project project) async {
    if (project.projectId.isEmpty) {
      project.projectId = _uuid.v4();
    }

    try {
      await _client.from('project').insert(project.toJson());
      print('Проект успешно добавлен');
    } on PostgrestException catch (error) {
      print('Ошибка при добавлении проекта: ${error.message}');
    }
  }

  // Получение списка всех проектов
  Future<List<Project>> getAllProjects() async {
    try {
      final response = await _client.from('project').select('''
          *,
          project_description_id: project_description_id(*),
          observers:project_observers (  
            employee:employee_id (  
              *
            )
          )
        ''');

      List<Project> projectList = (response as List<dynamic>).map((data) {
        return Project.fromJson(data as Map<String, dynamic>);
      }).toList();
      return projectList;
    } on PostgrestException catch (error) {
      print('Ошибка при получении списка проектов: ${error.message}');
      return [];
    }
  }

  // Получение данных проекта по projectId
  Future<Project> getProject(String projectId) async {
    final response = await _client
        .from('project')
        .select()
        .eq('project_id', projectId)
        .single() as Map<String, dynamic>;
    return Project.fromJson(response);
  }

  // Получение данных описания проекта по projectDescriptionId
  Future<ProjectDescription?> getProjectDescription(String projectDescriptionId) async {
    try {
      final response = await _client
          .from('project_description')
          .select()
          .eq('project_description_id', projectDescriptionId)
          .single() as Map<String, dynamic>;
      return ProjectDescription.fromJson(response);
    } on PostgrestException catch (error) {
      print('Ошибка при получении данных описания проекта: ${error.message}');
      return null;
    }
  }

  // Обновление данных проекта
  Future<void> updateProject(Project project) async {
    try {
      await _client
          .from('project')
          .update(project.toJson())
          .eq('project_id', project.projectId);
      print('Данные проекта успешно обновлены');
    } on PostgrestException catch (error) {
      print('Ошибка при обновлении данных проекта: ${error.message}');
    }
  }

  // Удаление проекта
  Future<void> deleteProject(String projectId) async {
    try {
      await _client.from('project').delete().eq('project_id', projectId);
      print('Проект успешно удален');
    } on PostgrestException catch (error) {
      print('Ошибка при удалении проекта: ${error.message}');
    }
  }

  // Загрузка аватара проекта
  Future<String?> uploadAvatar(File imageFile, String projectId) async {
    final String fileName =
        'projects/${projectId}_${basename(imageFile.path)}'; // Уникальное имя файла
    try {
      await _client.storage.from('Avatars').upload(fileName, imageFile);
      print("Аватар проекта успешно загружен");
      return fileName; // Возвращаем имя файла для сохранения в БД
    } on PostgrestException catch (error) {
      print("Ошибка загрузки аватарки проекта: ${error.message}");
    }
    return null;
  }

  // Удаление аватара проекта
  Future<void> deleteAvatar(String fileName) async {
    try {
      await _client.storage.from('Avatars').remove([fileName]);
      print('Аватар проекта успешно удален');
    } on PostgrestException catch (error) {
      print('Ошибка при удалении аватара проекта: ${error.message}');
    }
  }

  Future<Map<String, int>> getTasksByProject(String projectId) async {
    try {
      final tasksResponse = await _client
          .from('task')
          .select('''
      *,
      project:project_id(*,
        project_description_id:project_description_id(*),
        project_observers:project_observers(
          *,
          employee:employee_id(*)
        )
      ),
      task_team: id(*,
        creator_id:creator_id(*),
        communicator_id:communicator_id(*),
        team_members:team_id(*,
          employee_id:employee_id(*)
        )
      )
    ''')
          .eq('project_id', projectId);

      final statusCounts = <String, int>{};

      // Инициализируем все возможные статусы с нулевым счетчиком
      for (final status in TaskStatus.values) {
        statusCounts[StatusHelper.displayName(status)] = 0;
      }

      // Считаем задачи по статусам
      for (final task in tasksResponse) {
        if (task != null && task['status'] != null) {
          final status = task['status'] as String;
          final taskStatus = StatusHelper.toTaskStatus(status);
          final statusName = StatusHelper.displayName(taskStatus);
          statusCounts[statusName] = (statusCounts[statusName] ?? 0) + 1;
        }
      }

      return statusCounts;
    } catch (e) {
      print('Error getting tasks by project: $e');
      return {};
    }
  }
  // Получение публичного URL для аватара проекта
  String getAvatarUrl(String? fileName) {
    return _client.storage.from('Avatars').getPublicUrl(fileName!);
  }

  Future<int> getAllWorkersCount(String projectId) async {
    try {
      final teamResponce = await _client.from('task').select('''
          id,
          task_team:id(
            *,
            team_members:team_id(employee_id)
          )
          ''').eq('project_id', projectId);

      if (teamResponce == null || teamResponce.isEmpty) {
        return 0;
      }

      // Собираем все уникальные employee_id из всех команд всех задач проекта
      final Set<String> uniqueWorkerIds = {};

      for (final task in teamResponce) {
        final teamData = task['task_team'];
        if (teamData != null) {
          for (final team in teamData) {
            final teamMembers = team['team_members'];
            uniqueWorkerIds.add(team['creator_id']);
            uniqueWorkerIds.add(team['communicator_id']);
            if (teamMembers != null) {
              for (final member in teamMembers) {
                final employeeId = member['employee_id'];
                if (employeeId != null) {
                  uniqueWorkerIds.add(employeeId);
                }
              }
            }
          }
        }
      }

      return uniqueWorkerIds.length;
    } catch (e) {
      print('Error getting count of project workers: $e');
      throw Exception('Error getting count of project workers: $e');
    }
  }

  Map<String, int> _initializeEmptyStatusMap() {
    return {
      for (var status in TaskStatus.values) StatusHelper.displayName(status): 0
    };
  }
}
