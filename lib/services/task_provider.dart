import 'package:flutter/foundation.dart';
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

  List<TaskCategory> getCategories(String position, String employeeId, {String? projectId}) {
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
        throw Exception('Не указаны необходимые параметры (projectId или position и employeeId)');
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
        final categories = await taskCategories.getCategories(position, employeeId);
        _categories['$position:$employeeId'] = categories;
      }

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
          case 'Наблюдатель':
            matches &= task.team.observerId?.userId == userId;
        }
      }
      return matches;
    }).toList();
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
        final categories = await TaskCategories().getCategoriesProject(projectId);
        _categories[key] = categories;
      } else {
        final parts = key.split(':');
        final position = parts[0];
        final employeeId = parts[1];
        final categories = await TaskCategories().getCategories(position, employeeId);
        _categories[key] = categories;
      }
    }
    notifyListeners();
  }
}