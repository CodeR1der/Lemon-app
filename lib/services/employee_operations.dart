import 'dart:io';

import 'package:path/path.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:task_tracker/services/file_service.dart';

import '/models/employee.dart';
import '/models/project.dart';
import '/models/task.dart';

class EmployeeService {
  final SupabaseClient _client = Supabase.instance.client;
  final _uuid = Uuid();

  // Добавление сотрудника в Supabase
  Future<void> addEmployee(Employee employee) async {
    if (employee.userId.isEmpty) {
      employee.userId = _uuid.v4();
    }

    try {
      await _client.from('employee').insert(employee.toJson());
      print('Сотрудник успешно добавлен');
    } on PostgrestException catch (error) {
      print('Ошибка при добавлении сотрудника: ${error.message}');
    }
  }

  // Получение списка всех сотрудников
  Future<List<Employee>> getAllEmployees() async {
    try {
      final response = await _client.from('employee').select();
      List<Employee> employeeList = (response as List<dynamic>).map((data) {
        return Employee.fromJson(data as Map<String, dynamic>);
      }).toList();
      return employeeList;
    } on PostgrestException catch (error) {
      print('Ошибка при получении списка сотрудников: ${error.message}');
      return [];
    }
  }

  // Получение данных сотрудника по userId
  Future<Employee?> getEmployee(String userId) async {
    try {
      final response = await _client
          .from('employee')
          .select()
          .eq('user_id', userId)
          .single();
      return Employee.fromJson(response);
    } on PostgrestException catch (error) {
      print('Ошибка при получении данных сотрудника: ${error.message}');
      return null;
    }
  }

  // Обновление данных сотрудника
  Future<void> updateEmployee(Employee employee) async {
    try {
      await _client
          .from('employee')
          .update(employee.toJson())
          .eq('user_id', employee.userId);
      print('Данные сотрудника успешно обновлены');
    } on PostgrestException catch (error) {
      print('Ошибка при обновлении данных сотрудника: ${error.message}');
    }
  }

  // Удаление сотрудника
  Future<void> deleteEmployee(String userId) async {
    try {
      await _client.from('employee').delete().eq('userId', userId);
      print('Сотрудник успешно удален');
    } on PostgrestException catch (error) {
      print('Ошибка при удалении сотрудника: ${error.message}');
    }
  }

  Future<String?> uploadAvatar(File imageFile, String userId) async {
    final fileService = FileService();
    
    // Валидация файла
    if (!fileService.validateFile(
      imageFile,
      maxSizeInBytes: 10 * 1024 * 1024, // 10MB
      allowedExtensions: ['.jpg', '.jpeg', '.png', '.webp'],
    )) {
      print("Файл не прошел валидацию");
      return null;
    }
    
    try {
      final fileName = await fileService.uploadFile(
        imageFile,
        'Avatars/users',
        prefix: 'user_$userId'
      );
      
      if (fileName != null) {
        print("Аватарка успешно загружена: $fileName");
      }
      
      return fileName;
    } catch (e) {
      print("Ошибка загрузки аватарки: $e");
      return null;
    }
  }

  // Удаление аватара сотрудника
  Future<void> deleteAvatar(String fileName) async {
    if (fileName.isEmpty) return;
    
    final fileService = FileService();
    final success = await fileService.deleteFile(fileName, 'Avatars');
    
    if (success) {
      print('Аватар успешно удален');
    } else {
      print('Ошибка при удалении аватара');
    }
  }

  // Получение публичного URL для аватара
  String getAvatarUrl(String? fileName) {
    if (fileName == null || fileName.isEmpty) return '';
    final fileService = FileService();
    return fileService.getPublicUrl(fileName, 'Avatars/users');
  }

  Future<List<Project>> getEmployeeProjects(String employeeId) async {
    try {
      final teamProjects = await _client.from('project_team').select('''
        project_id,
        project:project_id(*,
          project_description_id:project_description_id(*),
          project_team(
            *,
            employee:employee_id(*)
          )
        )
        ''').eq('employee_id', employeeId);

      final allProjects = <dynamic>{
        ..._extractProjectsFromResponse(teamProjects),
      }.toList();

      return allProjects.map((json) => Project.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error getting projects: $e');
    }
  }

  Future<List<Task>> getEmployeeTasksByProject(
      String employeeId, String projectId) async {
    try {
      final tasksResponse = await _client
          .from('task')
          .select('''
  *,
  project:project_id(*,
    project_description_id:project_description_id(*),
    project_team:project_team(*,
      employee:employee_id(*)
    )
  ),
  task_team:task_team(*,
    creator_id:creator_id(*),
    communicator_id:communicator_id(*),
    observer_id:observer_id(*),
    team_members:team_members(*,
      employee_id:employee_id(*)
    )
  )
''')
          .eq('project_id', projectId)
          .eq('task_team.team_members.employee_id', employeeId);

      if (tasksResponse.isEmpty) return [];

      return tasksResponse.map((taskData) => Task.fromJson(taskData)).toList();
    } catch (e) {
      throw Exception('Error getting tasks by project: $e');
    }
  }

  Future<List<Project>> getAllProjects(String employeeId) async {
    try {
      final response = await _client.from('project_team').select('''
      project:project_id (
        *,
        project_description_id:project_description_id (*)
      )
    ''').eq('employee_id', employeeId);

      return response.map((json) => Project.fromJson(json['project'])).toList();
    } catch (e) {
      throw Exception('Error getting projects: $e');
    }
  }

  List<Map<String, dynamic>> _extractProjectsFromResponse(dynamic response) {
    final projects = <Map<String, dynamic>>[];

    for (final item in response) {
      if (item['task_team'] != null) {
        final taskTeam = item['task_team'];
        if (taskTeam['task'] != null && taskTeam['task']['project'] != null) {
          if (projects.isEmpty) {
            projects.add(taskTeam['task']['project']);
          } else if (projects
              .where((p) =>
                  p['project_id'] == taskTeam['task']['project']['project_id'])
              .isEmpty) {
            projects.add(taskTeam['task']['project']);
          }
        }
      } else if (item['task'] != null && item['task']['project'] != null) {
        if (projects.isEmpty) {
          projects.add(item['task']['project']);
        } else if (projects
            .where(
                (p) => p['project_id'] == item['task']['project']['project_id'])
            .isEmpty) {
          projects.add(item['task']['project']);
        }
      } else if (item['project'] != null) {
        if (projects.isEmpty) {
          projects.add(item['project']);
        } else if (projects
            .where((p) => p['project_id'] == item['project']['project_id'])
            .isEmpty) {
          projects.add(item['project']);
        }
      }
    }

    return projects;
  }
}
