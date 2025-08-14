import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Общие стили текста для всего приложения
class AppTextStyles {
  // Заголовки

  static const TextStyle titleAnnouncement = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.black,
    fontFamily: 'Roboto',
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.black,
    fontFamily: 'Roboto',
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Colors.black,
    fontFamily: 'Roboto',
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.primaryGrey,
    fontFamily: 'Roboto',
  );

  // Основной текст
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    color: Colors.black,
    fontWeight: FontWeight.w400,
    fontFamily: 'Roboto',
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 15,
    color: Colors.black,
    fontWeight: FontWeight.w400,
    fontFamily: 'Roboto',
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
    color: Colors.black,
    fontWeight: FontWeight.w400,
    fontFamily: 'Roboto',
  );

  // Подписи и метки
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: AppColors.primaryGrey,
    fontFamily: 'Roboto',
  );

  // Стили для кнопок
  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: Colors.white,
    fontFamily: 'Roboto',
  );

  static const TextStyle buttonTextSecondary = TextStyle(
    fontSize: 16,
    color: Colors.black,
    fontWeight: FontWeight.w400,
    fontFamily: 'Roboto',
  );

  static const TextStyle linkText = TextStyle(
    fontSize: 14,
    color: Colors.grey,
    fontFamily: 'Roboto',
  );

  // Стили для полей ввода
  static const TextStyle inputText = TextStyle(
    fontSize: 16,
    color: Colors.black,
    fontFamily: 'Roboto',
  );

  static const TextStyle inputHint = TextStyle(
    fontSize: 16,
    color: Colors.grey,
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w400,
  );

  static const TextStyle dropDownHint = TextStyle(
    fontSize: 16,
    color: AppColors.dropDownGrey,
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w400,
  );

  // Стили для статусов
  static TextStyle statusText(Color color) => TextStyle(
        fontSize: 14,
        color: color,
        fontFamily: 'Roboto',
      );

  // Стили для счетчиков
  static const TextStyle counterText = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.black,
    fontFamily: 'Roboto',
  );
}
