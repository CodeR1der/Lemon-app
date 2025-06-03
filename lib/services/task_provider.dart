import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  bool get isLoading => _isLoading;
  String? get error => _error;

  Task? getTask(String taskId) => _tasks[taskId];

  List<TaskCategory> getCategories(String position, String employeeId) =>
      _categories['$position:$employeeId'] ?? [];

  Future<void> loadTasksAndCategories({
    required TaskCategories taskCategories,
    String? projectId,
    required String position,
    required String employeeId,
  }) async {
    try {
      // Оптимизированный запрос: получаем задачи в зависимости от роли
      List<Task> tasks = [];
      if (projectId != null) {
        tasks = await TaskService().getProjectTasksByStatus(
          status: TaskStatus.values.first, // Загружаем задачи всех статусов
          projectId: projectId,
        );
      } else {
        tasks = await TaskService().getTasksByPosition(
          position: position,
          employeeId: employeeId,
        );
      }

      // Обновляем локальный кэш задач
      _tasks.clear();
      for (var task in tasks) {
        _tasks[task.id] = task;
      }

      // Загружаем категории
      final categories = await taskCategories.getCategories(position, employeeId);
      _categories['$position:$employeeId'] = categories;

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Task> getTasksByStatus(TaskStatus status, {String? projectId, String? userId, String? position}) {
    return _tasks.values.where((task) {
      bool matches = task.status == status;
      if (projectId != null) {
        matches &= task.project?.projectId == projectId;
      }
      if (userId != null && position != null) {
        switch (position) {
          case 'Коммуникатор':
            matches &= task.team.communicatorId.userId == userId;
          case 'Исполнитель':
            matches &= task.team.teamMembers.any((member) => member.userId == userId);
          case 'Постановщик':
            matches &= task.team.creatorId.userId == userId;
        }
      }
      return matches;
    }).toList();
  }

  Future<void> updateTask(Task task) async {
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

  Future<void> updateTaskStatus(Task task, TaskStatus status) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Создаем копию задачи с новым статусом
      final updatedTask = task.copyWith(status: status);

      // Обновляем в базе данных
      await task.changeStatus(status);

      // Обновляем в локальном кэше
      _tasks[task.id] = updatedTask;

      // Обновляем категории
      await _refreshCategories();

      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow; // Пробрасываем ошибку для обработки в UI
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _refreshCategories() async {
    for (var key in _categories.keys) {
      final parts = key.split(':');
      final position = parts[0];
      final employeeId = parts[1];
      final categories = await TaskCategories().getCategories(position, employeeId);
      _categories[key] = categories;
    }
    notifyListeners();
  }
}