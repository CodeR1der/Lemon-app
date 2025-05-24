import 'package:task_tracker/services/project_operations.dart';
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
    // TaskCategory(title: 'Объявления', count: 0, status: ),
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
    // TaskCategory(title: 'Повторяющиеся задачи', count: 0, status: ),
    TaskCategory(title: 'Архив задач', count: 0, status: TaskStatus.completed),
  ];

  Future<List<TaskCategory>> getCategoriesProject(String projectId) async {
    try {
      // Создаем копию списка категорий
      final categories = List<TaskCategory>.from(_communicatorCategories);

      // Получаем задачи проекта
      final tasksData = await ProjectService().getTasksByProject(projectId);

      // Обновляем категории с данными о количестве задач
      return categories.map((category) {
        final count = tasksData[StatusHelper.displayName(category.status)] ?? 0;
        return category.copyWith(count: count);
      }).toList();
    } catch (e) {
      print('Error getting categories: $e');
      // В случае ошибки возвращаем пустые категории
      return List<TaskCategory>.from(_communicatorCategories);
    }
  }

  Future<List<TaskCategory>> getCategories(
      String position, String employeeId) async {
    try {
      // Получаем количество задач для каждого статуса
      final tasksCount =
          await TaskService().getCountOfTasksByStatus(position, employeeId);

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
        final count =
            tasksCount[StatusHelper.displayName(category.status)] ?? 0;
        category.count = count;
        return category;
      }).toList();
    } catch (e) {
      print('Error getting categories: $e');
      // В случае ошибки возвращаем список с нулевыми значениями
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

}
