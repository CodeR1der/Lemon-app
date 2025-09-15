import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:task_tracker/models/employee.dart';
import 'package:task_tracker/screens/employee/employee_details_screen.dart';
import 'package:task_tracker/services/employee_operations.dart';
import 'package:task_tracker/widgets/common/app_colors.dart';

import '../../models/task_status.dart';
import 'app_container_styles.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

/// Общие виджеты для всего приложения
class AppCommonWidgets {
  // Месяцы на русском языке
  static const List<String> _months = [
    'Янв',
    'Фев',
    'Мар',
    'Апр',
    'Май',
    'Июн',
    'Июл',
    'Авг',
    'Сен',
    'Окт',
    'Ноя',
    'Дек'
  ];

  // Дни недели на русском
  static const List<String> _daysOfWeek = [
    'Пн',
    'Вт',
    'Ср',
    'Чт',
    'Пт',
    'Сб',
    'Вс'
  ];

  /// Универсальный календарь
  static Widget calendar({
    required DateTime focusedDate,
    required DateTime? selectedDate,
    required ValueChanged<DateTime> onDateSelected,
    required ValueChanged<DateTime> onMonthChanged,
    required ValueChanged<DateTime> onYearChanged,
    bool showNavigation = true,
    bool showTodayIndicator = true,
    Color? selectedColor,
    Color? todayColor,
    Color? textColor,
    Color? disabledTextColor,
    // Новые параметры для диапазона
    DateTime? rangeStart,
    DateTime? rangeEnd,
    ValueChanged<DateTime?>? onRangeStartChanged,
    ValueChanged<DateTime?>? onRangeEndChanged,
    bool isRangeSelection = false,
    Color? rangeColor,
    Color? rangeStartColor,
    Color? rangeEndColor,
  }) {
    return _CalendarWidget(
      focusedDate: focusedDate,
      selectedDate: selectedDate,
      onDateSelected: onDateSelected,
      onMonthChanged: onMonthChanged,
      onYearChanged: onYearChanged,
      showNavigation: showNavigation,
      showTodayIndicator: showTodayIndicator,
      selectedColor: selectedColor ?? Colors.blue[100]!,
      todayColor: todayColor ?? Colors.blue,
      textColor: textColor ?? Colors.black,
      disabledTextColor: disabledTextColor ?? Colors.grey,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
      onRangeStartChanged: onRangeStartChanged,
      onRangeEndChanged: onRangeEndChanged,
      isRangeSelection: isRangeSelection,
      rangeColor: rangeColor ?? Colors.blue[50]!,
      rangeStartColor: rangeStartColor ?? Colors.blue[200]!,
      rangeEndColor: rangeEndColor ?? Colors.blue[200]!,
    );
  }

  /// Виджет для отображения статуса задачи
  static Widget statusChip(
      {required IconData icon,
        required String text,
        Color? textColor,
        TaskStatus? status}) {
    var backgroundColor = status == TaskStatus.completed
        ? Colors.green.withOpacity(0.2)
        : status == TaskStatus.closed
        ? Colors.red.withOpacity(0.2)
        : const Color(0xFFEBEDF0);
    var textColor = status == TaskStatus.completed
        ? Colors.green[800]
        : status == TaskStatus.closed
        ? Colors.red[800]
        : Colors.black;
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
    //
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
      width: double.infinity,
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
        textCapitalization: TextCapitalization.words,
        controller: controller,
        expands: isMultiline,
        maxLines: maxLines,
        keyboardType: keyboardType ??
            (isMultiline ? TextInputType.multiline : TextInputType.text),
        onChanged: onChanged,
        style: AppTextStyles.inputText,
        decoration: InputDecoration(
          contentPadding: AppSpacing.paddingAll12,
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: AppTextStyles.inputHint,
        ),
      ),
    );
  }

  /// Универсальный алерт с настраиваемыми параметрами
  static Widget customAlert({
    required String title,
    String? description,
    IconData? icon,
    Color? backgroundColor,
    Color? iconColor,
    Color? buttonColor,
    String buttonText = 'Закрыть',
    VoidCallback? onButtonPressed,
  }) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      backgroundColor: backgroundColor ??
          const Color(0xFFF0F7E9), // Светло-зеленый фон по умолчанию
      content: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon ?? Icons.check_circle,
              color: iconColor ?? Colors.green,
              size: 40.0,
            ),
            const SizedBox(height: 16.0),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            if (description != null) ...[
              const SizedBox(height: 8.0),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14.0,
                  color: Colors.black54,
                ),
              ),
            ],
            const SizedBox(height: 24.0),
            ElevatedButton(
              onPressed: onButtonPressed ??
                      () {
                    Navigator.of(Get.context!).pop();
                  },
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor ?? Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Дефолтный алерт для успешных операций
  static Widget defaultAlert({required String title, String? description}) {
    return customAlert(
      title: title,
      description: description,
      icon: Icons.check_circle,
      backgroundColor: const Color(0xFFF0F7E9),
      iconColor: Colors.green,
      buttonColor: Colors.green,
      buttonText: 'Закрыть',
    );
  }

  /// Виджет для отображения поля ввода с заливкой
  static Widget filledInputField({
    required TextEditingController controller,
    required String hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool enabled = true,
    VoidCallback? onTap,
    ValueChanged<String>? onChanged,
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
          suffixIcon: suffixIcon,
          hintText: hintText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: AppSpacing.paddingVertical12,
        ),
        onChanged: onChanged,
      ),
    );
  }

  static Widget inputPhoneField(
      {required TextEditingController phoneController,
        required String hintText,
        Widget? prefixIcon,
        bool enabled = true,
        VoidCallback? onTap,
        VoidCallback? onChanged}) {
    return GestureDetector(
      onTap: onTap,
      child: TextFormField(
        controller: phoneController,
        keyboardType: TextInputType.phone,
        decoration: InputDecoration(
          prefixText: '+7 ',
          prefixStyle: AppTextStyles.bodySmall,
          isCollapsed: true,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[400]!, width: 1),
          ),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          hintText: 'XXX XXX-XX-XX',
          hintStyle: AppTextStyles.titleSmall,
        ),
        style: AppTextStyles.bodySmall,
        onChanged: (value) {
          onChanged;
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Пожалуйста, введите номер телефона';
          }
          if (!RegExp(r'^[0-9]{10}$')
              .hasMatch(value.replaceAll(RegExp(r'[^0-9]'), ''))) {
            return 'Введите корректный номер телефона';
          }
          return null;
        },
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(10),
          TextInputFormatter.withFunction(
                (oldValue, newValue) {
              if (newValue.text.isEmpty) return newValue;

              final text = newValue.text;
              String newText = text;

              if (text.length > 3) {
                newText = '${text.substring(0, 3)} ${text.substring(3)}';
              }
              if (text.length > 6) {
                newText = '${newText.substring(0, 7)}-${newText.substring(7)}';
              }
              if (text.length > 8) {
                newText =
                '${newText.substring(0, 10)}-${newText.substring(10)}';
              }

              return TextEditingValue(
                text: newText,
                selection: TextSelection.collapsed(offset: newText.length),
              );
            },
          )
        ],
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
    return const Padding(
      padding: AppSpacing.dividerPadding,
      child: Divider(
        height: 1.0,
        color: AppColors.divider,
      ),
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

  /// Виджет для отображения сотрудника в виде ListTile
  static Widget employeeTile({
    required Employee employee,
    required BuildContext context,
    double avatarRadius = 24,
    EdgeInsets? contentPadding,
    Widget? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    bool showNavigation = true,
  }) {
    final employeeService = EmployeeService();

    return ListTile(
      contentPadding:
      contentPadding ?? const EdgeInsets.symmetric(vertical: 4.0),
      leading: CircleAvatar(
        radius: avatarRadius,
        backgroundImage: employee.avatarUrl != null &&
            employee.avatarUrl!.isNotEmpty
            ? NetworkImage(employeeService.getAvatarUrl(employee.avatarUrl!))
            : null,
        child: employee.avatarUrl == null || employee.avatarUrl!.isEmpty
            ? Icon(Icons.person, size: avatarRadius)
            : null,
      ),
      title: Text(
        employee.fullName,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 16),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: subtitle ??
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  employee.position,
                  style: const TextStyle(
                    color: Colors.black38,
                    fontSize: 12,
                    fontFamily: 'Roboto',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
      trailing: trailing,
      onTap: onTap ??
          (showNavigation
              ? () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    EmployeeDetailScreen(employee: employee),
              ),
            );
          }
              : null),
    );
  }

  /// Виджет для отображения сотрудника в виде ListTileSmall
  static Widget employeeTileSmall({
    required Employee employee,
    required BuildContext context,
    double avatarRadius = 17,
    EdgeInsets? contentPadding,
    Widget? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    bool showNavigation = true,
  }) {
    final employeeService = EmployeeService();

    return ListTile(
      contentPadding:
      contentPadding ?? const EdgeInsets.symmetric(vertical: 0.0),
      leading: CircleAvatar(
        radius: avatarRadius,
        backgroundImage: employee.avatarUrl != null &&
            employee.avatarUrl!.isNotEmpty
            ? NetworkImage(employeeService.getAvatarUrl(employee.avatarUrl!))
            : null,
        child: employee.avatarUrl == null || employee.avatarUrl!.isEmpty
            ? Icon(Icons.person, size: avatarRadius)
            : null,
      ),
      title: Text(
        employee.fullName,
        style: AppTextStyles.bodySmall,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: subtitle ??
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  employee.position,
                  style: AppTextStyles.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
      trailing: trailing,
      onTap: onTap ??
          (showNavigation
              ? () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    EmployeeDetailScreen(employee: employee),
              ),
            );
          }
              : null),
    );
  }

  /// Виджет для отображения сотрудника в виде карточки
  static Widget employeeCard({
    required Employee employee,
    required BuildContext context,
    double avatarRadius = 24,
    EdgeInsets? margin,
    VoidCallback? onTap,
    bool showNavigation = true,
  }) {
    final employeeService = EmployeeService();

    return Card(
      color: Colors.white,
      margin: margin ?? const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          radius: avatarRadius,
          backgroundImage: employee.avatarUrl != null &&
              employee.avatarUrl!.isNotEmpty
              ? NetworkImage(employeeService.getAvatarUrl(employee.avatarUrl!))
              : null,
          child: employee.avatarUrl == null || employee.avatarUrl!.isEmpty
              ? const Icon(Icons.person)
              : null,
        ),
        title: Text(
          employee.fullName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(employee.position),
        onTap: onTap ??
            (showNavigation
                ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      EmployeeDetailScreen(employee: employee),
                ),
              );
            }
                : null),
      ),
    );
  }

  /// Виджет для отображения сотрудника в виде ячейки (для горизонтальных списков)
  static Widget employeeCell({
    required Employee employee,
    required BuildContext context,
    double avatarRadius = 34,
    double width = 120,
    VoidCallback? onTap,
    bool showNavigation = true,
  }) {
    return GestureDetector(
      onTap: onTap ??
          (showNavigation
              ? () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    EmployeeDetailScreen(employee: employee),
              ),
            );
          }
              : null),
      child: SizedBox(
        width: width,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: avatarRadius * 2,
                child: avatar(
                  radius: avatarRadius,
                  imageUrl: EmployeeService().getAvatarUrl(employee.avatarUrl!),
                ),
              ),
              AppSpacing.height6,
              SizedBox(
                height: 38,
                child: Text(
                  employee.fullName.split(' ').take(2).join(' '),
                  style: AppTextStyles.bodySmall,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              AppSpacing.height8,
              SizedBox(
                height: 20,
                child: Text(
                  employee.position,
                  style: AppTextStyles.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Показать алерт успеха
  static Future<void> showSuccessAlert({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'Закрыть',
    VoidCallback? onClose,
    bool dismissible = true,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: dismissible,
      builder: (BuildContext context) {
        return _SuccessAlertDialog(
          title: title,
          message: message,
          buttonText: buttonText,
          onClose: onClose,
        );
      },
    );
  }
}

/// Приватный виджет календаря
class _CalendarWidget extends StatefulWidget {
  final DateTime focusedDate;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onYearChanged;
  final bool showNavigation;
  final bool showTodayIndicator;
  final Color selectedColor;
  final Color todayColor;
  final Color textColor;
  final Color disabledTextColor;

  // Новые параметры для диапазона
  final DateTime? rangeStart;
  final DateTime? rangeEnd;
  final ValueChanged<DateTime?>? onRangeStartChanged;
  final ValueChanged<DateTime?>? onRangeEndChanged;
  final bool isRangeSelection;
  final Color? rangeColor;
  final Color? rangeStartColor;
  final Color? rangeEndColor;

  const _CalendarWidget({
    required this.focusedDate,
    required this.selectedDate,
    required this.onDateSelected,
    required this.onMonthChanged,
    required this.onYearChanged,
    required this.showNavigation,
    required this.showTodayIndicator,
    required this.selectedColor,
    required this.todayColor,
    required this.textColor,
    required this.disabledTextColor,
    this.rangeStart,
    this.rangeEnd,
    this.onRangeStartChanged,
    this.onRangeEndChanged,
    this.isRangeSelection = false,
    this.rangeColor,
    this.rangeStartColor,
    this.rangeEndColor,
  });

  @override
  State<_CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<_CalendarWidget> {
  void _selectMonth() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Выберите месяц',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: AppCommonWidgets._months.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(
                        AppCommonWidgets._months[index],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: widget.focusedDate.month == index + 1
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: widget.focusedDate.month == index + 1
                              ? Colors.blue
                              : Colors.black,
                        ),
                      ),
                      onTap: () {
                        final newDate =
                        DateTime(widget.focusedDate.year, index + 1, 1);
                        widget.onMonthChanged(newDate);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleRangeSelection(DateTime date) {
    if (widget.onRangeStartChanged == null || widget.onRangeEndChanged == null)
      return;

    if (widget.rangeStart == null ||
        (widget.rangeStart != null && widget.rangeEnd != null)) {
      // Начинаем новый диапазон
      widget.onRangeStartChanged!(date);
      widget.onRangeEndChanged!(null);
    } else {
      // Завершаем диапазон
      if (date.isBefore(widget.rangeStart!)) {
        widget.onRangeEndChanged!(widget.rangeStart);
        widget.onRangeStartChanged!(date);
      } else {
        widget.onRangeEndChanged!(date);
      }
    }
  }

  void _selectYear() {
    final currentYear = DateTime.now().year;
    final years = List.generate(10, (index) => currentYear + index);

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Выберите год',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: years.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(
                        years[index].toString(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: widget.focusedDate.year == years[index]
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: widget.focusedDate.year == years[index]
                              ? Colors.blue
                              : Colors.black,
                        ),
                      ),
                      onTap: () {
                        final newDate =
                        DateTime(years[index], widget.focusedDate.month, 1);
                        widget.onYearChanged(newDate);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCalendar() {
    final firstDayOfMonth =
    DateTime(widget.focusedDate.year, widget.focusedDate.month, 1);
    final lastDayOfMonth =
    DateTime(widget.focusedDate.year, widget.focusedDate.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;

    // Получаем дни предыдущего месяца для заполнения начала календаря
    final prevMonth =
    DateTime(widget.focusedDate.year, widget.focusedDate.month - 1, 0);
    final daysInPrevMonth = prevMonth.day;

    List<Widget> calendarDays = [];

    // Добавляем дни предыдущего месяца
    for (int i = firstWeekday - 1; i > 0; i--) {
      final day = daysInPrevMonth - i + 1;
      calendarDays.add(
        Container(
          alignment: Alignment.center,
          child: Text(
            day.toString(),
            style: TextStyle(color: widget.disabledTextColor),
          ),
        ),
      );
    }

    // Добавляем дни текущего месяца
    for (int day = 1; day <= daysInMonth; day++) {
      final date =
      DateTime(widget.focusedDate.year, widget.focusedDate.month, day);

      // Определяем состояние для диапазона
      bool isInRange = false;
      bool isRangeStart = false;
      bool isRangeEnd = false;

      if (widget.isRangeSelection &&
          widget.rangeStart != null &&
          widget.rangeEnd != null) {
        isInRange =
            date.isAfter(widget.rangeStart!) && date.isBefore(widget.rangeEnd!);
        isRangeStart = date.year == widget.rangeStart!.year &&
            date.month == widget.rangeStart!.month &&
            date.day == widget.rangeStart!.day;
        isRangeEnd = date.year == widget.rangeEnd!.year &&
            date.month == widget.rangeEnd!.month &&
            date.day == widget.rangeEnd!.day;
      }

      // Определяем состояние для одиночного выбора
      final isSelected = !widget.isRangeSelection &&
          widget.selectedDate != null &&
          widget.selectedDate!.year == date.year &&
          widget.selectedDate!.month == date.month &&
          widget.selectedDate!.day == date.day;

      final isToday = widget.showTodayIndicator &&
          date.year == DateTime.now().year &&
          date.month == DateTime.now().month &&
          date.day == DateTime.now().day;

      calendarDays.add(
        InkWell(
          onTap: () {
            if (widget.isRangeSelection) {
              _handleRangeSelection(date);
            } else {
              widget.onDateSelected(date);
            }
          },
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isRangeStart
                  ? widget.rangeStartColor
                  : isRangeEnd
                  ? widget.rangeEndColor
                  : isInRange
                  ? widget.rangeColor
                  : isSelected
                  ? widget.selectedColor
                  : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  day.toString(),
                  style: TextStyle(
                    color: (isRangeStart || isRangeEnd || isSelected)
                        ? Colors.white
                        : widget.textColor,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (isRangeStart || isRangeEnd || isSelected)
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    // Добавляем дни следующего месяца для заполнения конца календаря
    final remainingDays = 42 - calendarDays.length; // 6 недель * 7 дней
    for (int day = 1; day <= remainingDays; day++) {
      calendarDays.add(
        Container(
          alignment: Alignment.center,
          child: Text(
            day.toString(),
            style: TextStyle(color: widget.disabledTextColor),
          ),
        ),
      );
    }

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! > 0) {
          // Свайп вправо - предыдущий месяц
          final newDate = DateTime(
              widget.focusedDate.year, widget.focusedDate.month - 1, 1);
          widget.onMonthChanged(newDate);
        } else if (details.primaryVelocity! < 0) {
          // Свайп влево - следующий месяц
          final newDate = DateTime(
              widget.focusedDate.year, widget.focusedDate.month + 1, 1);
          widget.onMonthChanged(newDate);
        }
      },
      child: Column(
        children: [
          if (widget.showNavigation) ...[
            // Навигация по месяцам и годам
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Навигация по месяцам
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        final newDate = DateTime(widget.focusedDate.year,
                            widget.focusedDate.month - 1, 1);
                        widget.onMonthChanged(newDate);
                      },
                      icon: const Icon(Icons.chevron_left),
                    ),
                    InkWell(
                      onTap: _selectMonth,
                      child: Row(
                        children: [
                          Text(
                            AppCommonWidgets
                                ._months[widget.focusedDate.month - 1],
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const Icon(Icons.keyboard_arrow_down),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        final newDate = DateTime(widget.focusedDate.year,
                            widget.focusedDate.month + 1, 1);
                        widget.onMonthChanged(newDate);
                      },
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                // Навигация по годам
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        final newDate = DateTime(widget.focusedDate.year - 1,
                            widget.focusedDate.month, 1);
                        widget.onYearChanged(newDate);
                      },
                      icon: const Icon(Icons.chevron_left),
                    ),
                    InkWell(
                      onTap: _selectYear,
                      child: Row(
                        children: [
                          Text(
                            widget.focusedDate.year.toString(),
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const Icon(Icons.keyboard_arrow_down),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        final newDate = DateTime(widget.focusedDate.year + 1,
                            widget.focusedDate.month, 1);
                        widget.onYearChanged(newDate);
                      },
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          // Дни недели
          Row(
            children: AppCommonWidgets._daysOfWeek
                .map((day) => Expanded(
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  day,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
            ))
                .toList(),
          ),
          // Календарная сетка
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: calendarDays.length,
            itemBuilder: (context, index) => calendarDays[index],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildCalendar();
  }
}

/// Приватный виджет алерта успеха
class _SuccessAlertDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback? onClose;

  const _SuccessAlertDialog({
    required this.title,
    required this.message,
    required this.buttonText,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Закрываем диалог при нажатии вне его области
        Navigator.of(context).pop();
        // Выполняем ожидаемое действие
        onClose?.call();
      },
      child: Container(
        color: Colors.black.withOpacity(0.3),
        child: Center(
          child: GestureDetector(
            onTap: () {
              // Предотвращаем закрытие при нажатии на сам диалог
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E8), // Светло-зеленый фон
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Иконка успеха
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4CAF50), // Зеленый цвет
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Заголовок
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  // Сообщение
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // Кнопка закрытия
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onClose?.call();
                      },
                      child: Text(
                        buttonText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4CAF50), // Зеленый цвет
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
