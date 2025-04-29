import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/employee.dart';
import '../models/project.dart';
import '../models/task.dart';
import 'package:path/path.dart';

import '../models/task_status.dart';

class TaskService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<Task> getTask(String taskId) async {
    try {
      final response = await _client.from('task').select('''
  id,
  task_name,
  description,
  start_date,
  end_date,
  priority,
  attachments,
  audio_message,
  video_message,
  project (
    id,
    name,
    description,
    project_observers (
      employee_id,
      employee (
        id,
        name,
        avatar_url,
        position,
        phone,
        telegram_id,
        vk_id,
        role
      )
    )
  ),
  task_team (
    employee_id,
    employee (
      id,
      name,
      avatar_url,
      position,
      phone,
      telegram_id,
      vk_id,
      role
    )
  )
''').eq('id', taskId).single();

      final projectData = response['project'];

      final task = Task(
        id: taskId,
        taskName: response['task_name'],
        description: response['description'],
        project: Project(
          project_id: projectData['id'],
          name: projectData['name'],
          observers: List<Employee>.from(
            projectData['project_observers'].map((observer) {
              final empData = observer['employee'];
              return Employee(
                user_id: empData['id'],
                name: empData['name'],
                avatar_url: empData['avatar_url'],
                position: empData['position'],
                phone: empData['phone'],
                telegram_id: empData['telegram_id'],
                vk_id: empData['vk_id'],
                role: empData['role'],
              );
            }),
          ),
        ),
        startDate: DateTime.parse(response['start_date']),
        endDate: DateTime.parse(response['end_date']),
        team: List<Employee>.from(
          response['task_team'].map((teamMember) {
            final empData = teamMember['employee'];
            return Employee(
              user_id: empData['id'],
              name: empData['name'],
              avatar_url: empData['avatar_url'],
              position: empData['position'],
              phone: empData['phone'],
              telegram_id: empData['telegram_id'],
              vk_id: empData['vk_id'],
              role: empData['role'],
            );
          }),
        ),
        attachments: List<String>.from(response['attachments']),
        audioMessage: response['audio_message'],
        videoMessage: List<String>.from(response['video_message']),
        status: response['status'],
      );

      return task;
    } catch (e) {
      print('Ошибка при загрузке задачи: ${e}');
      rethrow;
    }
  }

  Future<Map<String, int>> getCountOfTasksByStatus(String position, String employeeId) async {
    try {
      late List<dynamic> tasksResponse;
      final now = DateTime.now();

      if (position == 'Исполнитель') {
        // Логика для исполнителя
        final teamsResponse = await _client
            .from('team_members')
            .select('team_id')
            .eq('employee_id', employeeId);

        if (teamsResponse.isEmpty) return _initializeEmptyStatusMap();

        final teamIds = (teamsResponse as List)
            .map((team) => team['team_id'] as String)
            .toList();

        tasksResponse = await _client
            .from('task_team')
            .select('task:task_id(status, end_date)')
            .inFilter('team_id', teamIds);
      }
      else if (position == 'Постановщик') {
        // Логика для постановщика - получаем задачи, где он создатель
        tasksResponse = await _client
            .from('task_team')
            .select('task:task_id(status, end_date)')
            .eq('creator_id', employeeId);
      }
      else if (position == 'Коммуникатор') {
        // Логика для постановщика - получаем задачи, где он создатель
        tasksResponse = await _client
            .from('task_team')
            .select('task:task_id(status, end_date)')
            .eq('communicator_id', employeeId);
      }

      // Общая логика обработки задач
      final statusCounts = _initializeEmptyStatusMap();

      for (final task in tasksResponse) {
        if (task != null) {
          final status = task['status'] as String? ?? 'new';

          final taskStatus = _mapDbStatusToEnum(status);
          statusCounts[StatusHelper.displayName(taskStatus)] =
              (statusCounts[StatusHelper.displayName(taskStatus)] ?? 0) + 1;
        }
      }

      return statusCounts;

    } on PostgrestException catch (error) {
      print('Ошибка при получении количества задач: ${error.message}');
      return _initializeEmptyStatusMap();
    } catch (e) {
      print('Неожиданная ошибка: $e');
      return _initializeEmptyStatusMap();
    }
  }

  Map<String, int> _initializeEmptyStatusMap() {
    return {
      for (var status in TaskStatus.values)
        StatusHelper.displayName(status): 0
    };
  }

  TaskStatus _mapDbStatusToEnum(String dbStatus) {
    switch (dbStatus) {
      case 'new':
        return TaskStatus.newTask;
      case 'revision':
        return TaskStatus.revision;
      case 'not_read':
        return TaskStatus.notRead;
      case 'need_explanation':
        return TaskStatus.needExplanation;
      case 'in_order':
        return TaskStatus.inOrder;
      case 'in_progress':
        return TaskStatus.atWork;
      case 'control_point':
        return TaskStatus.controlPoint;
      case 'extra_time':
        return TaskStatus.extraTime;
      case 'completed':
        return TaskStatus.completedUnderReview;
      default:
        return TaskStatus.newTask;
    }
  }

  Future<List<Task>> getTasksByStatus({required String position, required TaskStatus status, required String employeeId, }) async {
    try {
      final statusString = status.toString().substring(11);

      if (position == 'Постановщик') {
        // 1. Получаем список ID задач с нужным статусом и creator_id
        final taskIdsResponse = await _client
            .from('task_team')
            .select('task_id')
            .eq('creator_id', employeeId);

        if (taskIdsResponse.isEmpty) return [];

        final taskIds = taskIdsResponse
            .map((item) => item['task_id'] as String)
            .toList();

        // 2. Получаем полные данные задач с фильтрацией по статусу
        final tasksResponse = await _client
            .from('task')  // Исправлено название таблицы с 'task' на 'task_name'
            .select('''
          *,
          project:project_id(*),  
          task_team:task_team(   
            *,
            team_members:team_id(
              *,
              employee:employee_id(*)
            )
          )
        ''')
            .inFilter('id', taskIds)
            .eq('status', statusString);

        return tasksResponse.map((taskData) => Task.fromJson(taskData)).toList();
      } else {
        // Для исполнителя получаем задачи через team_members
        final teamsResponse = await _client
            .from('team_members')
            .select('team_id')
            .eq('employee_id', employeeId);

        if (teamsResponse.isEmpty) return [];

        final teamIds = (teamsResponse as List)
            .map((team) => team['team_id'] as String)
            .toList();

        final tasksResponse = await _client
            .from('task')
            .select('''
            *,
            project:project_id(*),
            task_team:task_team(
              employee:employee_id(*)
            )
          ''')
            .inFilter('id',
            await _client
                .from('task_team')
                .select('task_id')
                .inFilter('team_id', teamIds)
                .then((res) => res.map((r) => r['task_id'] as String).toList())
        )
            .eq('status', statusString);

        return tasksResponse.map((taskData) => Task.fromJson(taskData)).toList();
      }
    } catch (e) {
      print('Error getting tasks: $e');
      return [];
    }
  }

  Future<void> addNewTask(Task task) async {
    try {
      // Генерируем ID для задачи
      if (task.id.isEmpty || task.id == null) {
        task.id = const Uuid().v4();
      }

      // Загрузка вложений
      List<String> uploadedAttachments = [];
      for (var attachment in task.attachments) {
        final uploadedFile = await uploadFile(File(attachment), task.id);
        if (uploadedFile != null) {
          uploadedAttachments.add(uploadedFile);
        }
      }
      task.attachments = uploadedAttachments;

      // Загрузка аудиофайла
      if (task.audioMessage != null) {
        task.audioMessage = await uploadFile(File(task.audioMessage!), task.id);
      }

      // Загрузка вложений
      List<String> uploadedVideo = [];
      for (var video in task.videoMessage!) {
        final uploadedFile = await uploadFile(File(video), task.id);
        if (uploadedFile != null) {
          uploadedVideo.add(uploadedFile);
        }
      }
      task.videoMessage = uploadedVideo;

      print('Все файлы успешно загружены!');

      // Преобразуем задачу в JSON
      final taskJson = task.toMap();
      final teamJson = task.team
          .map((employee) => {
        'employee_id': employee.user_id,
      })
          .toList();

      await _client.rpc('add_task_with_team', params: {
        '_task': taskJson,
        '_team': teamJson,
      });

      print('Задача и команда успешно добавлены!');
    } catch (e) {
      print('Ошибка при добавлении задачи: $e');
      rethrow;
    }
  }

  Future<String?> uploadFile(File file, String id) async {
    final fileName = '${id}_${basename(file.path)}'; // Уникальное имя файла
    try {
      await _client.storage.from('TaskAttachments').upload(fileName, file);
      print("Файл успешно загружен");
      return fileName; // Возвращаем имя файла для сохранения в базе данных
    } on PostgrestException catch (error) {
      print("Ошибка загрузки файла: ${error.message}");
    }
    print("Файл успешно загружен");
    return null;
  }

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

  Future<List<Task>> getTasksByProjectId(String projectId) async {
    try {
      final List<Map<String, dynamic>> response = await _client
          .from('task')
          .select('''
          id,
          task_name,
          description,
          project:project_id (
            project_id,
            name,
            avatar_url,
            project_observers (
              employee_id,
              employee (
                user_id,
                name,
                avatar_url,
                position,
                phone,
                telegram_id,
                vk_id,
                role
              )
            )
          ),
          start_date,
          end_date,
          priority,
          attachments,
          audio_message,
          video_message,
          project_id,
          task_team:task_team (  
            employee:employee_id (  
              user_id,
              avatar_url,
              name,
              position,
              phone,
              telegram_id,
              vk_id,
              role
            )
          )
        ''')
          .eq('project_id', projectId);

      List<Task> taskList = response.map((data) {
        return Task.fromJson(data);
      }).toList();

      return taskList;
    } on PostgrestException catch (error) {
      print('Ошибка при получении задач: ${error.message}');
      return [];
    }
  }

  Future<List<Employee>> getUniqueEmployees(List<Task> tasks) async {
    // Используем Set для хранения уникальных сотрудников
    final Set<Employee> uniqueEmployees = {};
    // Проходим по каждой задаче
    for (final task in tasks) {
      // Добавляем всех сотрудников из команды задачи в Set
      uniqueEmployees.addAll(task.team);
    }

    // Преобразуем Set обратно в List и возвращаем
    return uniqueEmployees.toList();
  }

  Future<List<Project>> getAllProjects() async {
    try {
      final response = await _client.from('project').select('''
          id,
          name,
          description,
          project_observers (
            employee_id,
            employee (
              id,
              name,
              avatar_url,
              position,
              phone,
              telegram_id,
              vk_id,
              role
            )
          )
        ''');

      // Преобразуем данные в список объектов Project
      List<Project> projects = (response as List<dynamic>).map((data) {
        return Project.fromJson(data as Map<String, dynamic>);
      }).toList();

      return projects;
    } catch (e) {
      print('Ошибка при получении списка проектов: $e');
      return [];
    }
  }

  String getTaskAttachment(String? fileName) {
    return _client.storage.from('TaskAttachments').getPublicUrl(fileName!);
  }

  // Получение публичного URL для аватара
  String getAvatarUrl(String? fileName) {
    return _client.storage.from('Avatars').getPublicUrl(fileName!);
  }

}