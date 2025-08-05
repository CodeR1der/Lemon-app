import 'package:flutter/material.dart';
import 'package:task_tracker/widgets/common/app_colors.dart';

/// Общие стили кнопок для всего приложения
class AppButtonStyles {
  // Основная оранжевая кнопка
  static ButtonStyle primaryButton = ElevatedButton.styleFrom(
    backgroundColor: AppColors.appPrimary,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 4,
    shadowColor: Colors.blue.withOpacity(0.3),
  );

  // Вторичная кнопка с белым фоном и оранжевой границей
  static ButtonStyle secondaryButton = OutlinedButton.styleFrom(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
    side: const BorderSide(color: AppColors.appPrimary, width: 1),
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  );

  // Кнопка с синей границей
  static ButtonStyle blueBorderButton = OutlinedButton.styleFrom(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
    side: const BorderSide(color: Colors.blue, width: 1),
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  );

  // Кнопка для аутентификации
  static ButtonStyle authButton = ElevatedButton.styleFrom(
    backgroundColor: AppColors.appPrimary,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  );

  // Кнопка для изменения роли
  static ButtonStyle roleButton = OutlinedButton.styleFrom(
    backgroundColor: Colors.white,
    foregroundColor: Colors.white,
    side: const BorderSide(color: AppColors.appPrimary, width: 1),
    padding: const EdgeInsets.symmetric(vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  );

  // Кнопка для принятия/отклонения
  static ButtonStyle acceptButton = ElevatedButton.styleFrom(
    foregroundColor: Colors.white,
    backgroundColor: AppColors.appPrimary,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    padding: const EdgeInsets.symmetric(vertical: 16),
  );

  // Кнопка для отклонения
  static ButtonStyle rejectButton = ElevatedButton.styleFrom(
    foregroundColor: Colors.white,
    backgroundColor: Colors.grey,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    padding: const EdgeInsets.symmetric(vertical: 16),
  );

  // Кнопка для добавления файлов
  static ButtonStyle addFilesButton = ElevatedButton.styleFrom(
    foregroundColor: Colors.black,
    backgroundColor: Colors.white,
    side: const BorderSide(color: AppColors.appPrimary),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
  );

  // Кнопка для создания сотрудника
  static ButtonStyle createEmployeeButton = ElevatedButton.styleFrom(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
    side: const BorderSide(color: AppColors.appPrimary, width: 1),
    minimumSize: const Size(double.infinity, 48),
  );

  // Кнопка для показа кода компании
  static ButtonStyle companyCodeButton = ElevatedButton.styleFrom(
    backgroundColor: AppColors.appPrimary,
    foregroundColor: Colors.white,
    minimumSize: const Size(double.infinity, 48),
  );

  // Кнопка для постановки задачи
  static ButtonStyle addTaskButton = ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFFFF9700),
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );
}
