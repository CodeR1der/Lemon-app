import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:task_tracker/models/correction.dart';
import 'package:task_tracker/services/task_operations.dart';

import '../../models/task.dart';
import '../../models/task_status.dart';
import '../../services/request_operation.dart';

class AddExtraTimeScreen extends StatefulWidget {
  final Task task;
  final Correction correction;

  const AddExtraTimeScreen(
      {super.key, required this.task, required this.correction});

  @override
  _AddExtraTimeScreen createState() => _AddExtraTimeScreen();
}

class _AddExtraTimeScreen extends State<AddExtraTimeScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Устанавливаем текущий дедлайн как начальную дату, если он есть
    _selectedDay = widget.task.endDate;
    _focusedDay = widget.task.endDate;
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
          padding: const EdgeInsets.all(16.0),
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
                'Сдлеать до',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                _formatDeadline(widget.task.endDate),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),

              // Календарь
              TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                startingDayOfWeek: StartingDayOfWeek.monday,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                locale: 'ru_Ru',
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
                calendarStyle: const CalendarStyle(
                  outsideDaysVisible: false,
                ),
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle: TextStyle(fontWeight: FontWeight.bold),
                  weekendStyle: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),

              // Кнопка подтверждения
              ElevatedButton(
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

                  // Обновляем дедлайн в базе данных
                  TaskService().updateDeadline(newDeadline, widget.task.id);
                  TaskService().changeStatus(TaskStatus.atWork, widget.task.id);
                  RequestService()
                      .updateCorrection(widget.correction..isDone = true);
                  RequestService().updateCorrectionByStatus(
                      widget.task.id, TaskStatus.extraTime);
                  // Возвращаем новый дедлайн на предыдущий экран
                  Navigator.pop(context, widget.task);
                  //Navigator.pop(context, newDeadline);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 8),
                    Text(
                      'Продлить срок',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
