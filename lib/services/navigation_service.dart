import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task_tracker/models/employee.dart';
import 'package:task_tracker/models/project.dart';
import 'package:task_tracker/models/task.dart';
import 'package:task_tracker/screens/task/task_details_screen.dart';
import 'package:task_tracker/task_screens/task_title_screen.dart';

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  // Флаг для предотвращения множественных навигаций
  bool _isNavigating = false;

  /// Безопасная навигация с проверкой на множественные переходы
  Future<T?> safeNavigate<T>(Widget page, {String? routeName}) async {
    if (_isNavigating) {
      debugPrint('Navigation blocked: already navigating');
      return null;
    }

    _isNavigating = true;

    try {
      final result = await Get.to<T>(() => page);
      return result;
    } catch (e) {
      debugPrint('Navigation error: $e');
      return null;
    } finally {
      // Небольшая задержка для предотвращения быстрых переходов
      await Future.delayed(const Duration(milliseconds: 100));
      _isNavigating = false;
    }
  }

  static const String createTaskStartRoute = '/createTaskStart';
  static const String taskDetailsRoute = '/taskDetails';

  /// Навигация к созданию задачи с возможностью передачи сотрудника или проекта
  static Future<Task?> navigateToCreateTask({
    Employee? employee,
    Project? project,
    BuildContext? context,
  }) async {
    // Создаем экран создания задачи с переданными параметрами
    final taskTitleScreen = TaskTitleScreen(
      employee: employee,
      project: project,
    );

    // Используем GetX для навигации
    final result = await Get.to(() => taskTitleScreen);

    // Если задача была создана успешно, возвращаем её
    if (result is Task) {
      return result;
    }

    return null;
  }

  /// Навигация к деталям задачи с очисткой стека навигации
  static void navigateToTaskDetails(Task task) {
    // Очищаем весь стек навигации до корня
    Get.to(() => TaskDetailsScreen(task: task));
  }

  /// Навигация к созданию задачи с переходом на детали после создания
  static Future<void> navigateToCreateTaskWithDetails({
    Employee? employee,
    Project? project,
    BuildContext? context,
  }) async {
    final createdTask = await navigateToCreateTask(
      employee: employee,
      project: project,
      context: context,
    );

    // Если задача была создана, переходим к её деталям
    if (createdTask != null) {
      navigateToTaskDetails(createdTask);
    }
  }

  /// Навигация к созданию задачи из главного экрана
  static Future<void> navigateToCreateTaskFromHome() async {
    await navigateToCreateTaskWithDetails();
  }

  /// Навигация к созданию задачи для конкретного сотрудника
  static Future<void> navigateToCreateTaskForEmployee(Employee employee) async {
    await navigateToCreateTaskWithDetails(employee: employee);
  }

  /// Навигация к созданию задачи для конкретного проекта
  static Future<void> navigateToCreateTaskForProject(Project project) async {
    await navigateToCreateTaskWithDetails(project: project);
  }

  /// Навигация к деталям проекта
  Future<void> navigateToProjectDetails(dynamic project) async {
    if (_isNavigating) return;

    _isNavigating = true;

    try {
      await Get.toNamed('/project_details', arguments: project);
    } catch (e) {
      debugPrint('Error navigating to project details: $e');
    } finally {
      await Future.delayed(const Duration(milliseconds: 100));
      _isNavigating = false;
    }
  }

  /// Навигация к деталям сотрудника
  Future<void> navigateToEmployeeDetails(dynamic employee) async {
    if (_isNavigating) return;

    _isNavigating = true;

    try {
      await Get.toNamed('/employee_details', arguments: employee);
    } catch (e) {
      debugPrint('Error navigating to employee details: $e');
    } finally {
      await Future.delayed(const Duration(milliseconds: 100));
      _isNavigating = false;
    }
  }

  /// Очистка стека навигации
  void clearNavigationStack() {
    Get.offAllNamed('/');
  }

  /// Возврат назад с проверкой
  void goBack() {
    if (Navigator.canPop(Get.context!)) {
      Get.back();
    }
  }
}
