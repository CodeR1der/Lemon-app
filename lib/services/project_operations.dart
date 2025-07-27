import 'dart:io';

import 'package:path/path.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:task_tracker/services/file_service.dart';

import '/models/project.dart';
import '../models/employee.dart';
import '../models/project_description.dart';
import '../models/task_status.dart';

class ProjectService {
  final SupabaseClient _client = Supabase.instance.client;
  final _uuid = Uuid();

  // Добавление проекта в Supabasew
  Future<void> addProject(Project project) async {
    if (project.projectId.isEmpty) {
      project.projectId = _uuid.v4();
    }
    if (project.projectDescription!.projectDescriptionId.isEmpty) {
      project.projectDescription!.projectDescriptionId = _uuid.v4();
    }

    try {
      final response = await _client
          .from('project_description')
          .insert(project.projectDescription!.toJson())
          .select('project_description_id');
      project.projectDescription!.projectDescriptionId =
          response.first['project_description_id'];

      final projectResponse = await _client
          .from('project')
          .insert(project.toJson())
          .select('project_id');
      project.projectId = projectResponse.first['project_id'];

      for (var emp in project.team) {
        await _client.from('project_team').insert({
          'project_id': project.projectId,
          'employee_id': emp.userId,
          'company_id': project.companyId
        });
      }

      if (project.avatarUrl != null) {
        var filename = uploadAvatar(File(project.avatarUrl!), project.projectId);
        project.avatarUrl = 'https://xusyxtgdmtpupmroemzb.supabase.co/storage/v1/object/public/Avatars/$filename';
      }

      print('Проект успешно добавлен');
    } on PostgrestException catch (error) {
      print('Ошибка при добавлении проекта: ${error.message}');
    }
  }

  Future<List<Employee>> getProjectTeam(String projectId) async {
    try {
      final response = await _client.from('project_team')
          .select('*, employee:employee_id(*)')
          .eq('project_id', projectId);

      return response.map((emp) => Employee.fromJson(emp['employee'])).toList();
    } catch (e) {
      print('Ошибка при получении команды проекта: $e');
      return [];
    }
  }

  Future<void> updateProjectTeam(String projectId, List<String> employeeIds) async {
    try {
      // 1. Получаем company_id проекта
      final projectResponse = await _client
          .from('project')
          .select('company_id')
          .eq('project_id', projectId)
          .single();

      if (projectResponse.isEmpty) {
        throw Exception('Проект с ID $projectId не найден');
      }

      final companyId = projectResponse['company_id'] as String;

      // 2. Получаем текущих сотрудников проекта
      final currentEmployeesResponse = await _client
          .from('project_team')
          .select('employee_id')
          .eq('project_id', projectId);

      final currentEmployeeIds = (currentEmployeesResponse as List<dynamic>)
          .map((e) => e['employee_id'] as String)
          .toList();

      // 3. Определяем, кого нужно удалить и кого добавить
      final employeesToRemove = currentEmployeeIds
          .where((id) => !employeeIds.contains(id))
          .toList();
      final employeesToAdd = employeeIds
          .where((id) => !currentEmployeeIds.contains(id))
          .toList();

      // 4. Удаляем сотрудников, которые больше не в проекте
      if (employeesToRemove.isNotEmpty) {
        await _client
            .from('project_team')
            .delete()
            .eq('project_id', projectId)
            .inFilter('employee_id', employeesToRemove);
      }

      // 5. Добавляем новых сотрудников в проект
      if (employeesToAdd.isNotEmpty) {
        final newEntries = employeesToAdd.map((employeeId) => {
          'project_id': projectId,
          'employee_id': employeeId,
          'company_id': companyId,
        }).toList();

        await _client.from('project_team').insert(newEntries);
      }
    } catch (e) {
      throw Exception('Ошибка обновления команды проекта: $e');
    }
  }
  // Получение списка всех проектов
  Future<List<Project>> getAllProjects() async {
    try {
      final response = await _client.from('project').select('''*,
      project_description_id:project_description_id(*),
      project_team:project_team(
        *,
        employee:employee_id(*)
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
        .single();
    return Project.fromJson(response);
  }

  // Получение данных описания проекта по projectDescriptionId
  Future<ProjectDescription?> getProjectDescription(
      String projectDescriptionId) async {
    try {
      final response = await _client
          .from('project_description')
          .select()
          .eq('project_description_id', projectDescriptionId)
          .single();
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
    final fileService = FileService();
    
    // Валидация файла
    if (!fileService.validateFile(
      imageFile,
      maxSizeInBytes: 10 * 1024 * 1024, // 10MB
      allowedExtensions: ['.jpg', '.jpeg', '.png', '.gif', '.webp'],
    )) {
      print("Файл не прошел валидацию");
      return null;
    }
    
    try {
      final fileName = await fileService.uploadFile(
        imageFile, 
        'Avatars/projects',
        prefix: 'project_$projectId'
      );
      
      if (fileName != null) {
        print("Аватар проекта успешно загружен: $fileName");
      }
      
      return fileName;
    } catch (e) {
      print("Ошибка загрузки аватарки проекта: $e");
      return null;
    }
  }

  // Удаление аватара проекта
  Future<void> deleteAvatar(String fileName) async {
    if (fileName.isEmpty) return;
    
    final fileService = FileService();
    final success = await fileService.deleteFile(fileName, 'Avatars');
    
    if (success) {
      print('Аватар проекта успешно удален');
    } else {
      print('Ошибка при удалении аватара проекта');
    }
  }

  Future<Map<String, int>> getTasksByProject(String projectId) async {
    try {
      final tasksResponse = await _client.from('task').select('''
      *,
      project:project_id(*,
        project_description_id:project_description_id(*),
        project_team:project_team(
          *,
          employee:employee_id(*)
        )
      ),
      task_team:task_team(
        *,
        creator_id:creator_id(*),
        communicator_id:communicator_id(*),
        team_members:team_id(*,
          employee_id:employee_id(*)
        )
      )
    ''').eq('project_id', projectId);

      final statusCounts = <String, int>{};

      // Инициализируем все возможные статусы с нулевым счетчиком
      for (final status in TaskStatus.values) {
        statusCounts[StatusHelper.displayName(status)] = 0;
      }

      // Считаем задачи по статусам
      for (final task in tasksResponse) {
        if (task['status'] != null) {
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
    if (fileName == null || fileName.isEmpty) return '';
    final fileService = FileService();
    return fileService.getPublicUrl(fileName, 'Avatars/projects');
  }

  Future<int> getAllWorkersCount(String projectId) async {
    try {
      final projectResponse = await _client
          .from('project_team')
          .select('employee_id')
          .eq('project_id', projectId);

      // Если ответ содержит список, возвращаем его длину
      return projectResponse.length;
          // Если ответ в другом формате, возможно нужно адаптировать
      return 0;
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
