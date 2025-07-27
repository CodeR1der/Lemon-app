import 'package:flutter/material.dart';

import 'app_container_styles.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

/// Общие виджеты для всего приложения
class AppCommonWidgets {
  /// Виджет для отображения статуса задачи
  static Widget statusChip({
    required IconData icon,
    required String text,
    Color? backgroundColor,
    Color? textColor,
  }) {
    return Container(
      padding: AppSpacing.paddingHorizontal8Vertical4,
      decoration: AppContainerStyles.statusContainerDecoration.copyWith(
        color: backgroundColor ?? const Color(0xFFEBEDF0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          AppSpacing.width6,
          Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(color: textColor),
          ),
        ],
      ),
    );
  }

  /// Виджет для отображения счетчика
  static Widget counterChip({
    required String count,
    Color? backgroundColor,
  }) {
    return Container(
      padding: AppSpacing.paddingHorizontal8Vertical4,
      decoration: AppContainerStyles.counterContainerDecoration.copyWith(
        color: backgroundColor ?? Colors.grey[300],
      ),
      child: Text(
        count,
        style: AppTextStyles.counterText,
      ),
    );
  }

  /// Виджет для отображения заголовка секции
  static Widget sectionHeader({
    required String title,
    String? counter,
    VoidCallback? onTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.titleLarge),
        if (counter != null) counterChip(count: counter),
        if (onTap != null)
          GestureDetector(
            onTap: onTap,
            child: Text(
              'Показать все',
              style: AppTextStyles.linkText.copyWith(color: Colors.blue),
            ),
          ),
      ],
    );
  }

  /// Виджет для отображения поля с заголовком
  static Widget labeledField({
    required String label,
    required Widget child,
    EdgeInsets? padding,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.titleSmall),
        AppSpacing.height4,
        child,
        if (padding != null) Padding(padding: padding),
      ],
    );
  }

  /// Виджет для отображения карточки
  static Widget card({
    required Widget child,
    EdgeInsets? padding,
    EdgeInsets? margin,
    VoidCallback? onTap,
  }) {
    Widget cardWidget = Container(
      decoration: AppContainerStyles.cardDecoration,
      padding: padding ?? AppSpacing.paddingAll16,
      margin: margin,
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: cardWidget,
      );
    }

    return cardWidget;
  }

  /// Виджет для отображения поля ввода
  static Widget inputField({
    required TextEditingController controller,
    required String hintText,
    bool isMultiline = false,
    int? maxLines,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: AppContainerStyles.inputFieldDecoration,
      child: TextField(
        controller: controller,
        maxLines: isMultiline ? null : 1,
        keyboardType: keyboardType ??
            (isMultiline ? TextInputType.multiline : TextInputType.text),
        style: AppTextStyles.inputText,
        decoration: InputDecoration(
          contentPadding: AppSpacing.paddingAll12,
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: AppTextStyles.inputHint,
        ),
        onChanged: onChanged,
      ),
    );
  }

  /// Виджет для отображения поля ввода с заливкой
  static Widget filledInputField({
    required TextEditingController controller,
    required String hintText,
    Widget? prefixIcon,
    bool enabled = true,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: TextField(
        controller: controller,
        enabled: enabled,
        style: AppTextStyles.inputText,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey[200],
          prefixIcon: prefixIcon,
          hintText: hintText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: AppSpacing.paddingVertical12,
        ),
      ),
    );
  }

  /// Виджет для отображения аватара
  static Widget avatar({
    required double radius,
    String? imageUrl,
    IconData? fallbackIcon,
    Color? backgroundColor,
  }) {
    return CircleAvatar(
      radius: radius,
      backgroundImage: imageUrl != null && imageUrl.isNotEmpty
          ? NetworkImage(imageUrl)
          : null,
      backgroundColor: backgroundColor ?? Colors.grey[300],
      child: imageUrl == null || imageUrl.isEmpty
          ? Icon(fallbackIcon ?? Icons.person, size: radius)
          : null,
    );
  }

  /// Виджет для отображения разделителя
  static Widget divider() {
    return Padding(
      padding: AppSpacing.dividerPadding,
      child: const Divider(),
    );
  }

  /// Виджет для отображения загрузки
  static Widget loadingIndicator() {
    return const Center(child: CircularProgressIndicator());
  }

  /// Виджет для отображения ошибки
  static Widget errorWidget(String message) {
    return Center(
      child: Text(
        message,
        style: AppTextStyles.bodyMedium.copyWith(color: Colors.red),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Виджет для отображения пустого состояния
  static Widget emptyState(String message) {
    return Center(
      child: Text(
        message,
        style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
        textAlign: TextAlign.center,
      ),
    );
  }
}
