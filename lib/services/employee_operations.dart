import 'dart:io';

import 'package:path/path.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

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
  Future<Employee?> getEmployee(String user_id) async {
    try {
      final response = await _client
          .from('employee')
          .select()
          .eq('user_id', user_id)
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
    final String fileName =
        'users/${userId}_${basename(imageFile.path)}'; // Уникальное имя файла
    try {
      await Supabase.instance.client.storage
          .from('Avatars')
          .upload(fileName, imageFile);
      print("Аватарка успешно загружена");
      return fileName; // Возвращаем имя файла для сохранения в базе данных
    } on PostgrestException catch (error) {
      print("Ошибка загрузки аватарки: ${error.message}");
    }
    print("Аватарка успешно загружена");
    return null;
  }

  // Удаление аватара сотрудника
  Future<void> deleteAvatar(String fileName) async {
    try {
      await _client.storage.from('Avatars').remove([fileName]);
      print('Аватар успешно удален');
    } on PostgrestException catch (error) {
      print('Ошибка при удалении аватара: ${error.message}');
    }
  }

  // Получение публичного URL для аватара
  String getAvatarUrl(String? fileName) {
    return _client.storage.from('Avatars').getPublicUrl(fileName!);
  }

  Future<List<Project>> getEmployeeProjects(String employeeId) async {
    try {
      // Получаем проекты, где сотрудник является членом команды
      final teamProjects = await _client.from('team_members').select('''
          team_id,
          task_team:team_id(
            task_id,
            task:task_id(
              project_id,
              project:project_id(*,
              project_description_id:project_description_id(*),
              project_observers:project_observers(
              *,
              employee:employee_id(*)
              )
             )
            )
          )
          ''').eq('employee_id', employeeId);

      // Объединяем все проекты и убираем дубликаты
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
    project_observers:project_observers(
      *,
      employee:employee_id(*)
    )
  ),
  task_team:task_team(
    *,
    creator_id:creator_id(*),
    communicator_id:communicator_id(*),
    team_members:team_members(
      *,
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
        final task_team = item['task_team'];
        if (task_team['task'] != null && task_team['task']['project'] != null) {
          if (projects.isEmpty) {
            projects.add(task_team['task']['project']);
          } else if (projects
              .where((p) =>
                  p['project_id'] == task_team['task']['project']['project_id'])
              .isEmpty) {
            projects.add(task_team['task']['project']);
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
