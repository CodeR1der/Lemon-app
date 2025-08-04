import 'package:flutter/material.dart';

/// Общие стили контейнеров для всего приложения
class AppContainerStyles {
  // Карточка с тенью
  static BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: const [
      BoxShadow(
        color: Colors.black12,
        blurRadius: 12,
        spreadRadius: 0,
      ),
    ],
  );

  // Карточка с меньшей тенью
  static BoxDecoration smallCardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    boxShadow: [
      BoxShadow(
        color: Colors.grey.withOpacity(0.15),
        spreadRadius: 1,
        blurRadius: 6,
        offset: const Offset(0, 3),
      ),
    ],
  );

  // Поле ввода
  static BoxDecoration inputFieldDecoration = BoxDecoration(
    border: Border.all(color: Colors.grey.shade300),
    borderRadius: BorderRadius.circular(8),
  );

  // Поле ввода с заливкой
  static BoxDecoration filledInputDecoration = BoxDecoration(
    color: Colors.grey[200],
    borderRadius: BorderRadius.circular(12),
  );

  // Контейнер для статуса
  static BoxDecoration statusContainerDecoration = BoxDecoration(
    color: const Color(0xFFEBEDF0),
    borderRadius: BorderRadius.circular(12),
  );

  // Контейнер для счетчика
  static BoxDecoration counterContainerDecoration = BoxDecoration(
    color: Colors.grey[300],
    borderRadius: BorderRadius.circular(12),
  );

  // Контейнер для выбора сотрудника
  static BoxDecoration employeeSelectionDecoration = BoxDecoration(
    color: Colors.grey.shade100,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.grey, width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.grey.withOpacity(0.15),
        spreadRadius: 1,
        blurRadius: 6,
        offset: const Offset(0, 3),
      ),
    ],
  );

  // Контейнер для роли в аутентификации
  static BoxDecoration roleSelectionDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: Colors.orange,
      width: 2,
    ),
  );

  // Контейнер для очереди
  static BoxDecoration queueContainerDecoration = BoxDecoration(
    color: Colors.grey[200],
    borderRadius: BorderRadius.circular(12.0),
  );

  // Контейнер для аватара
  static BoxDecoration avatarDecoration = const BoxDecoration(
    color: Colors.white,
    shape: BoxShape.circle,
  );

  // Контейнер для кнопки с тенью
  static BoxDecoration buttonShadowDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.blue.withOpacity(0.3),
        spreadRadius: 1,
        blurRadius: 6,
        offset: const Offset(0, 3),
      ),
    ],
  );
}
