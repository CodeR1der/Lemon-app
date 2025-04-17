import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/employee.dart';
import '../models/project.dart';
import '../models/task.dart';
import 'package:path/path.dart';

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
      );

      return task;
    } catch (e) {
      print('Ошибка при загрузке задачи: ${e}');
      rethrow;
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