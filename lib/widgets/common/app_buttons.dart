import 'package:flutter/material.dart';

import 'app_button_styles.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

/// Общие кнопки для всего приложения
class AppButtons {
  /// Основная кнопка с иконкой и текстом
  static Widget primaryButton({
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
    bool isLoading = false,
    bool isFullWidth = true,
  }) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: AppButtonStyles.primaryButton,
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: Colors.black,),
                    AppSpacing.width8,
                  ],
                  Text(text, style: AppTextStyles.buttonText),
                ],
              ),
      ),
    );
  }

  /// Вторичная кнопка с иконкой и текстом
  static Widget secondaryButton({
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
    bool isLoading = false,
    bool isFullWidth = true,
  }) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: AppButtonStyles.secondaryButton,
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    AppSpacing.width8,
                  ],
                  Text(text, style: AppTextStyles.buttonTextSecondary),
                ],
              ),
      ),
    );
  }

  /// Кнопка для аутентификации
  static Widget authButton({
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: AppButtonStyles.authButton,
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppSpacing.width8,
                Text(text, style: AppTextStyles.buttonText),
              ],
            ),
    );
  }

  /// Кнопка для изменения роли
  static Widget roleButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: AppButtonStyles.roleButton,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppSpacing.width8,
          Text(text, style: AppTextStyles.buttonTextSecondary),
        ],
      ),
    );
  }

  /// Кнопка для принятия
  static Widget acceptButton({
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: AppButtonStyles.acceptButton,
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppSpacing.width8,
                  Text(text, style: AppTextStyles.buttonText),
                ],
              ),
      ),
    );
  }

  /// Кнопка для отклонения
  static Widget rejectButton({
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: AppButtonStyles.rejectButton,
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppSpacing.width8,
                  Text(text, style: AppTextStyles.buttonText),
                ],
              ),
      ),
    );
  }

  /// Кнопка для добавления файлов
  static Widget addFilesButton({
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: AppButtonStyles.addFilesButton,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 24),
            AppSpacing.width8,
          ],
          Text(text, style: AppTextStyles.buttonTextSecondary),
        ],
      ),
    );
  }

  /// Кнопка для создания сотрудника
  static Widget createEmployeeButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: AppButtonStyles.createEmployeeButton,
      child: Text(text, style: AppTextStyles.buttonTextSecondary),
    );
  }

  /// Кнопка для показа кода компании
  static Widget companyCodeButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: AppButtonStyles.companyCodeButton,
      child: Text(text, style: AppTextStyles.buttonText),
    );
  }

  /// Кнопка для постановки задачи
  static Widget addTaskButton({
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: AppButtonStyles.addTaskButton,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, size: 24),
            AppSpacing.width8,
          ],
          Text(
            text,
            style: AppTextStyles.buttonText.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Текстовая кнопка
  static Widget textButton({
    required String text,
    required VoidCallback onPressed,
    Color? textColor,
  }) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        text,
        style: AppTextStyles.linkText.copyWith(color: textColor),
      ),
    );
  }

  /// Кнопка с синей границей
  static Widget blueBorderButton({
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: AppButtonStyles.blueBorderButton,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.blue, size: 24),
            AppSpacing.width12,
          ],
          Text(
            text,
            style:
                AppTextStyles.buttonTextSecondary.copyWith(color: Colors.blue),
          ),
        ],
      ),
    );
  }
}
