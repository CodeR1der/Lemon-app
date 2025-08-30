import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:task_tracker/models/correction.dart';
import 'package:task_tracker/services/task_operations.dart';
import 'package:task_tracker/widgets/common/app_buttons.dart';
import 'package:task_tracker/widgets/common/app_common.dart';

import '../../models/task.dart';
import '../../models/task_status.dart';
import '../../services/request_operation.dart';
import '../../services/task_provider.dart';

class AddExtraTimeScreen extends StatefulWidget {
  final Task task;
  final Correction correction;

  const AddExtraTimeScreen(
      {super.key, required this.task, required this.correction});

  @override
  _AddExtraTimeScreen createState() => _AddExtraTimeScreen();
}

class _AddExtraTimeScreen extends State<AddExtraTimeScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Устанавливаем текущий дедлайн как начальную дату, если он есть
    _selectedDay = widget.task.deadline!;
    _focusedDay = widget.task.deadline!;
  }

  String _formatDeadline(DateTime? dateTime) {
    if (dateTime == null) return 'Не установлен';
    final dateFormat = DateFormat('dd.MM.yyyy');
    final timeFormat = DateFormat('HH:mm');
    return '${dateFormat.format(dateTime)}, до ${timeFormat.format(dateTime)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Дополнительное время'),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16.0),//
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Название задачи
              Text(
                'Название задачи',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                widget.task.taskName,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),

              // Причина запроса на дополнительное время (Correction Description)
              Text(
                'Причина запроса на дополнительное время',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Text(
                widget.correction.description ?? 'Причина не указана',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),

              // Текущий дедлайн
              Text(
                'Сдeлать до',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                _formatDeadline(widget.task.endDate),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),

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
                selectedColor: Colors.blue[100],
                todayColor: Colors.blue,
                textColor: Colors.black,
                disabledTextColor: Colors.grey,
              ),
              const SizedBox(height: 24),
              AppButtons.primaryButton(
                  text: 'Продлить срок',
                  onPressed: () {
                    // Сохраняем время из текущего дедлайна, если он есть
                    final currentDeadline = widget.task.endDate;
                    DateTime newDeadline;
                    if (currentDeadline != null) {
                      newDeadline = DateTime(
                        _selectedDay.year,
                        _selectedDay.month,
                        _selectedDay.day,
                        currentDeadline.hour,
                        currentDeadline.minute,
                      );
                    } else {
                      // Если дедлайна не было, используем текущее время
                      final now = DateTime.now();
                      newDeadline = DateTime(
                        _selectedDay.year,
                        _selectedDay.month,
                        _selectedDay.day,
                        now.hour,
                        now.minute,
                      );
                    }

                    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

                    // Обновляем дедлайн в базе данных
                    TaskService().updateDeadline(newDeadline, widget.task.id);
                    taskProvider.updateTaskStatus(widget.task, TaskStatus.atWork);
                    RequestService()
                        .updateCorrection(widget.correction..isDone = true);
                    RequestService().updateCorrectionByStatus(
                        widget.task.id, TaskStatus.extraTime);
                    // Возвращаем новый дедлайн на предыдущий экран
                    Navigator.pop(context, widget.task);
                    //Navigator.pop(context, newDeadline);
                  })
            ],
          ),
        ),
      ),
    );
  }
}
