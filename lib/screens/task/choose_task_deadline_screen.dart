import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_tracker/services/navigation_service.dart';
import 'package:task_tracker/services/task_operations.dart';
import 'package:task_tracker/services/task_provider.dart';
import 'package:task_tracker/widgets/common/app_colors.dart';
import 'package:task_tracker/widgets/common/app_common.dart';

import '../../models/task.dart';
import '../../models/task_status.dart';

class TaskCompletionPage extends StatefulWidget {
  final Task task;

  const TaskCompletionPage({super.key, required this.task});

  @override
  _TaskCompletionPageState createState() => _TaskCompletionPageState();
}

class _TaskCompletionPageState extends State<TaskCompletionPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  TimeOfDay? _selectedTime;
  DateTime _initialDateTime = DateTime.now();


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Выберите дедлайн'),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Название задачи',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                widget.task.taskName,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),

              // Календарь
              AppCommonWidgets.calendar(
                focusedDate: _focusedDay,
                selectedDate: _selectedDay,
                onDateSelected: (selectedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = selectedDay;
                  });
                },
                onMonthChanged: (focusedDay) {
                  setState(() {
                    _focusedDay = focusedDay;
                  });
                },
                onYearChanged: (focusedDay) {
                  setState(() {
                    _focusedDay = focusedDay;
                  });
                },
                showNavigation: true,
                showTodayIndicator: true,
                selectedColor: AppColors.primaryGrey,
                todayColor: Colors.blue,
                textColor: Colors.black,
                disabledTextColor: Colors.grey,
              ),
              const SizedBox(height: 24),
              AppButtons.primaryButton(
                  text: 'Назначить время сдачи',
                  onPressed: () => _showCustomTimePicker(context))
             ],
          ),
        ),
      ),
    );
  }

  void _showCustomTimePicker(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      builder: (BuildContext context) {
        return SizedBox(
          height: 350,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Отмена', style: TextStyle(fontSize: 18)),
                  ),
                  TextButton(
                    onPressed: () async {
                      if (_selectedTime != null) {
                        setState(() {
                          //
                          _selectedDay = DateTime(
                              _selectedDay.year,
                              _selectedDay.month,
                              _selectedDay.day,
                              _selectedTime!.hour,
                              _selectedTime!.minute);
                        });
                      }

                      // Обновляем дедлайн задачи
                      await TaskService()
                          .updateDeadline(_selectedDay, widget.task.id);

                      // Закрываем модальное окно
                      Navigator.pop(context);
                      final taskProvider = Provider.of<TaskProvider>(context, listen: false);

                      await taskProvider.updateTaskStatus(widget.task, TaskStatus.queue);

                      // Очищаем стек навигации и переходим к деталям задачи
                      NavigationService.clearNavigationStackStatic();
                      NavigationService.navigateToTaskDetails(widget.task);
                    },
                    child: const Text('Готово', style: TextStyle(fontSize: 18)),
                  ),
                ],
              ),
              Expanded(
                child: Stack(
                  children: [
                    CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.time,
                      use24hFormat: true,
                      initialDateTime: _initialDateTime,
                      onDateTimeChanged: (DateTime newDateTime) {
                        setState(() {
                          _selectedTime = TimeOfDay.fromDateTime(newDateTime);
                          _initialDateTime = newDateTime;
                        });
                      },
                      itemExtent: 30,
                      backgroundColor: Colors.white,
                    ),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          ":",
                          style: TextStyle(
                            fontSize: 30,
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
