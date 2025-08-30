import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:task_tracker/services/control_point_operations.dart';
import 'package:task_tracker/services/task_operations.dart';

import '../models/task.dart';
import '../models/task_category.dart';
import '../models/task_status.dart';
import '../services/task_categories.dart';

class TaskProvider with ChangeNotifier {
  final Map<String, Task> _tasks = {};
  final Map<String, List<TaskCategory>> _categories = {};
  String? _error;
  bool _isLoading = false;

  // Realtime подписки
  RealtimeChannel? _taskChannel;
  RealtimeChannel? _controlPointChannel;
  String? _currentProjectId;
  String? _currentPosition;
  String? _currentEmployeeId;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Task? getTask(String taskId) => _tasks[taskId];

  List<TaskCategory> getCategories(String position, String employeeId,
      {String? projectId}) {
    //
    if (projectId != null) {
      return _categories['project:$projectId'] ?? [];
    }
    return _categories['$position:$employeeId'] ?? [];
  }

  Future<void> loadTasksAndCategories({
    required TaskCategories taskCategories,
    String? projectId,
    String? position,
    String? employeeId,
  }) async {
    try {
      List<Task> tasks = [];
      if (projectId != null) {
        // Load all tasks for the project
        tasks = await TaskService().getProjectTasksByStatus(
          projectId: projectId,
        );
      } else if (position != null && employeeId != null) {
        // Load tasks for the specific employee and position
        tasks = await TaskService().getTasksByPosition(
          position: position,
          employeeId: employeeId,
        );
      } else {
        throw Exception(
            'Не указаны необходимые параметры (projectId или position и employeeId)');
      }

      // Update local cache of tasks
      _tasks.clear();
      for (var task in tasks) {
        _tasks[task.id] = task;
      }

      // Load categories based on the context
      if (projectId != null) {
        final categories = await taskCategories.getCategoriesProject(projectId);
        _categories['project:$projectId'] = categories;
      } else if (position != null && employeeId != null) {
        final categories =
            await taskCategories.getCategories(position, employeeId);
        _categories['$position:$employeeId'] = categories;
      }//
      _error = null;

      // Настраиваем Realtime подписки
      _setupRealtimeSubscriptions(
        projectId: projectId,
        position: position,
        employeeId: employeeId,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Task> getTasksByStatus(TaskStatus status,
      {String? projectId, String? userId, String? position}) {
    return _tasks.values.where((task) {
      bool matches = task.status == status;

      // Для проектов используем реальный статус из БД без учета контрольных точек
      if (projectId != null) {
        matches &= task.project?.projectId == projectId;
        return matches; // Возвращаем задачи в их реальном статусе
      }

      // Специальная логика для контрольных точек коммуникатора (только для личных задач)
      if (status == TaskStatus.controlPoint && position == 'Коммуникатор') {
        // Для статуса "Контрольная точка" ищем задачи "В работе" с незакрытыми контрольными точками
        matches = task.status == TaskStatus.atWork;
        // Примечание: проверка контрольных точек будет происходить асинхронно в UI
      }

      if (userId != null && position != null) {
        switch (position) {
          case 'Коммуникатор':
            matches &= task.team.communicatorId.userId == userId;
          case 'Исполнитель':
            matches &=
                task.team.teamMembers.any((member) => member.userId == userId);
          case 'Постановщик':
            matches &= task.team.creatorId.userId == userId;
          case 'Наблюдатель':
            matches &= task.team.observerId?.userId == userId;
        }
      }
      return matches;
    }).toList();
  }

  // Асинхронный метод для получения задач с контрольными точками
  Future<List<Task>> getTasksByStatusWithControlPoints(TaskStatus status,
      {String? projectId, String? userId, String? position}) async {
    final controlPointService = ControlPointService();

    if (status == TaskStatus.controlPoint && position == 'Коммуникатор') {
      print(
          'TaskProvider: Получаем задачи с контрольными точками для коммуникатора');
      // Получаем задачи "В работе" для коммуникатора
      final atWorkTasks = getTasksByStatus(TaskStatus.atWork,
          projectId: projectId, userId: userId, position: position);
      print('TaskProvider: Найдено задач "В работе": ${atWorkTasks.length}');

      // Фильтруем задачи с незакрытыми контрольными точками
      final tasksWithControlPoints = <Task>[];
      for (final task in atWorkTasks) {
        final hasUnclosedControlPoints =
            await controlPointService.hasUnclosedControlPoints(task.id);
        print(
            'TaskProvider: Задача ${task.id} имеет незакрытые контрольные точки: $hasUnclosedControlPoints');
        if (hasUnclosedControlPoints) {
          tasksWithControlPoints.add(task);
        }
      }

      print(
          'TaskProvider: Итого задач с контрольными точками: ${tasksWithControlPoints.length}');
      return tasksWithControlPoints;
    } else if (status == TaskStatus.atWork && position == 'Коммуникатор') {
      print(
          'TaskProvider: Получаем задачи "В работе" для коммуникатора (исключая контрольные точки)');
      // Получаем задачи "В работе" для коммуникатора, исключая те, что имеют контрольные точки
      final atWorkTasks = getTasksByStatus(TaskStatus.atWork,
          projectId: projectId, userId: userId, position: position);
      print('TaskProvider: Найдено задач "В работе": ${atWorkTasks.length}');

      // Исключаем задачи с незакрытыми контрольными точками
      final tasksWithoutControlPoints = <Task>[];
      for (final task in atWorkTasks) {
        final hasUnclosedControlPoints =
            await controlPointService.hasUnclosedControlPoints(task.id);
        print(
            'TaskProvider: Задача ${task.id} имеет незакрытые контрольные точки: $hasUnclosedControlPoints');
        if (!hasUnclosedControlPoints) {
          tasksWithoutControlPoints.add(task);
        }
      }

      print(
          'TaskProvider: Итого задач "В работе" без контрольных точек: ${tasksWithoutControlPoints.length}');
      return tasksWithoutControlPoints;
    } else {
      print(
          'TaskProvider: Используем обычную логику для статуса: $status, позиции: $position');
      // Для остальных случаев используем обычную логику
      return getTasksByStatus(status,
          projectId: projectId, userId: userId, position: position);
    }
  }

  Future<void> updateTaskFields(Task task) async {
    try {
      _isLoading = true;
      notifyListeners();

      await TaskService().updateTask(task);
      _tasks[task.id] = task;
      await _refreshCategories();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateTask(Task task) async {
    try {
      _isLoading = true;
      notifyListeners();

      await TaskService().updateQueuePosTask(task);
      _tasks[task.id] = task;
      await _refreshCategories();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateTaskStatus(Task task, TaskStatus status) async {
    try {
       _isLoading = true;
      notifyListeners();

      final updatedTask = task.copyWith(status: status);
      await task.changeStatus(status);
      _tasks[task.id] = updatedTask;
      await _refreshCategories();
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _refreshCategories() async {
    for (var key in _categories.keys) {
      if (key.startsWith('project:')) {
        final projectId = key.split(':')[1];
        final categories =
            await TaskCategories().getCategoriesProject(projectId);
        _categories[key] = categories;
      } else {
        final parts = key.split(':');
        final position = parts[0];
        final employeeId = parts[1];
        final categories =
            await TaskCategories().getCategories(position, employeeId);
        _categories[key] = categories;
      }
    }
    notifyListeners();
  }

  // Методы для управления Realtime подписками
  void _setupRealtimeSubscriptions({
    String? projectId,
    String? position,
    String? employeeId,
  }) {
    // Отписываемся от предыдущих подписок
    disposeRealtimeSubscriptions();

    _currentProjectId = projectId;
    _currentPosition = position;
    _currentEmployeeId = employeeId;

    final client = Supabase.instance.client;
//
    // Подписываемся на изменения задач
    if (projectId != null) {
      // Для проектов подписываемся на все задачи проекта
      _taskChannel = client
          .channel('task_changes_project_$projectId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'task',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'project_id',
              value: projectId,
            ),
            callback: (payload) {
              print(
                  'TaskProvider: Получено изменение задачи в проекте: $payload');
              _handleTaskChange(payload);
            },
          )
          .subscribe();
    } else if (position != null && employeeId != null) {
      // Для личных задач подписываемся на задачи пользователя
      _taskChannel = client
          .channel('task_changes_user_${position}_$employeeId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'task',
            callback: (payload) {
              print(
                  'TaskProvider: Получено изменение задачи пользователя: $payload');
              _handleTaskChange(payload);
            },
          )
          .subscribe();
    }

    // Подписываемся на изменения контрольных точек
    _controlPointChannel = client
        .channel('control_point_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'control_point',
          callback: (payload) {
            print(
                'TaskProvider: Получено изменение контрольной точки: $payload');
            _handleControlPointChange(payload);
          },
        )
        .subscribe();
  }

  void disposeRealtimeSubscriptions() {
    _taskChannel?.unsubscribe();
    _controlPointChannel?.unsubscribe();
    _taskChannel = null;
    _controlPointChannel = null;
  }

  void _handleTaskChange(PostgresChangePayload payload) {
    final eventType = payload.eventType.name;
    final record = payload.newRecord;
    final oldRecord = payload.oldRecord;

    print('TaskProvider: Обработка изменения задачи: $eventType');

    switch (eventType) {
      case 'INSERT':
        if (record != null) {
          _addTask(record);
        }
        break;
      case 'UPDATE':
        if (record != null) {
          _updateTask(record);
        }
        break;
      case 'DELETE':
        if (oldRecord != null) {
          _removeTask(oldRecord['id'] as String);
        }
        break;
    }

    // Обновляем категории и уведомляем слушателей
    _refreshCategories();
    notifyListeners();
  }

  void _handleControlPointChange(PostgresChangePayload payload) {
    final eventType = payload.eventType.name;

    print('TaskProvider: Обработка изменения контрольной точки: $eventType');

    // При изменении контрольных точек обновляем категории и уведомляем слушателей
    if (eventType == 'INSERT' ||
        eventType == 'UPDATE' ||
        eventType == 'DELETE') {
      _refreshCategories();
      notifyListeners();
    }
  }

  void _addTask(Map<String, dynamic> taskData) {
    try {
      final task = Task.fromJson(taskData);
      _tasks[task.id] = task;
      print('TaskProvider: Добавлена новая задача: ${task.id}');
    } catch (e) {
      print('TaskProvider: Ошибка при добавлении задачи: $e');
    }
  }

  void _updateTask(Map<String, dynamic> taskData) {
    try {
      final task = Task.fromJson(taskData);
      _tasks[task.id] = task;
      print('TaskProvider: Обновлена задача: ${task.id}');
    } catch (e) {
      print('TaskProvider: Ошибка при обновлении задачи: $e');
    }
  }

  void _removeTask(String taskId) {
    _tasks.remove(taskId);
    print('TaskProvider: Удалена задача: $taskId');
  }

  @override
  void dispose() {
    disposeRealtimeSubscriptions();
    super.dispose();
  }
}
