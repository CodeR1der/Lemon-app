import 'package:flutter/material.dart';
import 'package:get/get.dart';

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

  /// Навигация к экрану создания задачи с оптимизацией
  Future<void> navigateToCreateTask({
    dynamic employee,
    dynamic project,
  }) async {
    if (_isNavigating) return;

    _isNavigating = true;

    try {
      // Импортируем здесь для избежания циклических зависимостей
      await Get.toNamed('/createTaskStart', arguments: {
        'employee': employee,
        'project': project,
      });
    } catch (e) {
      debugPrint('Error navigating to create task: $e');
    } finally {
      await Future.delayed(const Duration(milliseconds: 150));
      _isNavigating = false;
    }
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
