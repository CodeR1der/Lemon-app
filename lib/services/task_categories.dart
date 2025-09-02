import 'package:flutter/cupertino.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:task_tracker/services/task_operations.dart';

import '../models/task_category.dart';
import '../models/task_status.dart';

class TaskCategories {
  final List<TaskCategory> _createrCategories = [
    TaskCategory(title: 'Новые задачи', count: 0, status: TaskStatus.newTask),
    TaskCategory(
        title: 'Доработать задачу', count: 0, status: TaskStatus.revision),
    TaskCategory(
        title: 'Проверить завершённые задачи',
        count: 0,
        status: TaskStatus.completedUnderReview),
    TaskCategory(
        title: 'Не прочитано / не понято',
        count: 0,
        status: TaskStatus.notRead),
    TaskCategory(
        title: 'В очереди на выполнение', count: 0, status: TaskStatus.inOrder),
    TaskCategory(title: 'Сейчас в работе', count: 0, status: TaskStatus.atWork),
    TaskCategory(
        title: 'Просроченные задачи', count: 0, status: TaskStatus.overdue),
    TaskCategory(
        title: 'Запросы на дополнительное время',
        count: 0,
        status: TaskStatus.extraTime),
    TaskCategory(title: 'Архив задач', count: 0, status: TaskStatus.completed),
  ];

  final List<TaskCategory> _executerCategories = [
    TaskCategory(title: 'Сейчас в работе', count: 0, status: TaskStatus.atWork),
    TaskCategory(
        title: 'Нужно письмо-решение', count: 0, status: TaskStatus.needTicket),
    TaskCategory(
        title: 'Просроченные задачи', count: 0, status: TaskStatus.overdue),
    TaskCategory(
        title: 'В очереди на выполнение', count: 0, status: TaskStatus.queue),
    TaskCategory(
        title: 'Запросы на дополнительное время',
        count: 0,
        status: TaskStatus.extraTime),
    TaskCategory(
        title: 'Не прочитано / не понято',
        count: 0,
        status: TaskStatus.notRead),
    TaskCategory(
        title: 'Завершенные задачи на проверке',
        count: 0,
        status: TaskStatus.completedUnderReview),
    TaskCategory(title: 'Архив задач', count: 0, status: TaskStatus.completed),
  ];

  final List<TaskCategory> _communicatorCategories = [
    TaskCategory(title: 'Новые задачи', count: 0, status: TaskStatus.newTask),
    TaskCategory(
        title: 'Задача на доработке', count: 0, status: TaskStatus.revision),
    TaskCategory(
        title: 'Выставить в очередь на выполнение',
        count: 0,
        status: TaskStatus.inOrder),
    TaskCategory(
        title: 'Не прочитано / не понято',
        count: 0,
        status: TaskStatus.notRead),
    TaskCategory(
        title: 'В очереди на выполнение', count: 0, status: TaskStatus.queue),
    TaskCategory(
        title: 'Контрольная точка', count: 0, status: TaskStatus.controlPoint),
    TaskCategory(
        title: 'Нужно разъяснение или одобрение',
        count: 0,
        status: TaskStatus.needExplanation),
    TaskCategory(
        title: 'Нужно письмо-решение', count: 0, status: TaskStatus.needTicket),
    TaskCategory(
        title: 'Запросы на дополнительное время',
        count: 0,
        status: TaskStatus.extraTime),
    TaskCategory(title: 'Сейчас в работе', count: 0, status: TaskStatus.atWork),
    TaskCategory(
        title: 'Просроченные задачи', count: 0, status: TaskStatus.overdue),
    TaskCategory(
        title: 'Завершенные задачи на проверке',
        count: 0,
        status: TaskStatus.completedUnderReview),
    TaskCategory(title: 'Архив задач', count: 0, status: TaskStatus.completed),
  ];

  Future<List<TaskCategory>> getCategoriesProject(String projectId) async {
    try {
      // Создаем копию списка категорий
      final categories = List<TaskCategory>.from(_communicatorCategories);

      // Получаем задачи проекта в их реальном статусе из БД
      final tasksData = await _getTasksByProjectRaw(projectId);

      // Обновляем категории с данными о количестве задач
      return categories.map((category) {
        if (category.status == TaskStatus.completed) {
          // Для архива считаем completed и closed вместе
          final completedCount = tasksData[StatusHelper.displayName(TaskStatus.completed)] ?? 0;
          final closedCount = tasksData[StatusHelper.displayName(TaskStatus.closed)] ?? 0;
          return category.copyWith(count: completedCount + closedCount);
        } else {
          final count = tasksData[StatusHelper.displayName(category.status)] ?? 0;
          return category.copyWith(count: count);
        }
      }).toList();
    } catch (e) {
      print('Error getting categories: $e');
      // В случае ошибки возвращаем пустые категории
      return List<TaskCategory>.from(_communicatorCategories);
    }
  }

  // Новый метод для получения задач проекта в их реальном статусе из БД
  Future<Map<String, int>> _getTasksByProjectRaw(String projectId) async {
    try {
      final tasksResponse = await Supabase.instance.client
          .from('task')
          .select('status')
          .eq('project_id', projectId);

      final statusCounts = <String, int>{};

      // Инициализируем все возможные статусы с нулевым счетчиком
      for (final status in TaskStatus.values) {
        statusCounts[StatusHelper.displayName(status)] = 0;
      }

      // Считаем задачи по их реальным статусам из БД
      for (final task in tasksResponse) {
        if (task['status'] != null) {
          final status = task['status'] as String;
          final taskStatus = StatusHelper.toTaskStatus(status);

          // Просто считаем по реальному статусу из БД
          statusCounts[StatusHelper.displayName(taskStatus)] =
              (statusCounts[StatusHelper.displayName(taskStatus)] ?? 0) + 1;
        }
      }

      return statusCounts;
    } catch (e) {
      print('Error getting tasks by project raw: $e');
      return {};
    }
  }

  Future<List<TaskCategory>> getCategories(String position, String employeeId,
      {String? projectId}) async {
    try {
      if (projectId != null) {
        return await getCategoriesProject(projectId);
      }

      // Получаем количество задач для каждого статуса
      Map<String, int> tasksCount;

      // Для коммуникатора используем специальную логику с контрольными точками
      if (position == "Коммуникатор") {
        tasksCount = await TaskService()
            .getTasksWithControlPointsForCommunicator(employeeId);
      } else {
        tasksCount =
        await TaskService().getCountOfTasksByStatus(position, employeeId);
      }

      // Выбираем соответствующий список категорий
      List<TaskCategory> categories = [];
      switch (position) {
        case "Исполнитель":
          categories = List.from(_executerCategories);
          break;
        case "Коммуникатор" || "Наблюдатель":
          categories = List.from(_communicatorCategories);
          break;
        case "Постановщик":
          categories = List.from(_createrCategories);
          break;
        default:
          categories = List.from(_executerCategories);
      }

      // Обновляем count для каждой категории
      return categories.map((category) {
        late int count = 0;

        // Для архива считаем completed и closed вместе
        if (category.status == TaskStatus.completed) {
          final completedCount = tasksCount[StatusHelper.displayName(TaskStatus.completed)] ?? 0;
          final closedCount = tasksCount[StatusHelper.displayName(TaskStatus.closed)] ?? 0;
          count = completedCount + closedCount;
        } else if (position == "Исполнитель" && category.status == TaskStatus.queue) {
          count = (tasksCount[StatusHelper.displayName(category.status)]! +
              tasksCount[StatusHelper.displayName(TaskStatus.inOrder)]!);
        } else if ((position == "Исполнитель" || position == "Постановщик") &&
            category.status == TaskStatus.atWork) {
          count = (tasksCount[StatusHelper.displayName(category.status)]! +
              tasksCount[StatusHelper.displayName(TaskStatus.controlPoint)]!);
        } else {
          count = tasksCount[StatusHelper.displayName(category.status)] ?? 0;
        }

        return category.copyWith(count: count);
      }).toList();
    } catch (e) {
      print('Error getting categories: $e');
      // В случае ошибки возвращаем список с нулевыми значениями
      if (projectId != null) {
        return List<TaskCategory>.from(_communicatorCategories);
      }
      switch (position) {
        case "Исполнитель":
          return _executerCategories;
        case "Коммуникатор" || "Наблюдатель":
          return _communicatorCategories;
        case "Постановщик":
          return _createrCategories;
        default:
          return _executerCategories;
      }
    }
  }

  static IconData getCategoryIcon(TaskStatus status) {
    if (status == TaskStatus.completed) {
      return Iconsax.folder_open_copy; // Иконка для категории "Архив задач"
    }
    return StatusHelper.getStatusIcon(status); // Стандартные иконки для других категорий
  }

  Future<List<TaskCategory>> getCategoriesList(String position) async {
    switch (position) {
      case "Исполнитель":
        return List.of(_executerCategories);
      case "Коммуникатор" || "Наблюдатель":
        return _communicatorCategories;
      case "Постановщик":
        return _createrCategories;
      default:
        return _executerCategories;
    }
  }
}