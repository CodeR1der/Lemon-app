import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:task_tracker/services/task_provider.dart';

import '../models/task.dart';
import 'queue_screen.dart';

class TaskCompletionPage extends StatefulWidget {
  final Task task;

  const TaskCompletionPage({super.key, required this.task});

  @override
  _TaskCompletionPageState createState() => _TaskCompletionPageState();
}

class _TaskCompletionPageState extends State<TaskCompletionPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Возвращаемся без изменений
            Navigator.pop(context);
          },
        ),
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

              ElevatedButton(
                onPressed: () => _showCustomTimePicker(context),
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
                      'Назначить время сдачи',
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
                          _selectedDay = DateTime(
                              _selectedDay.year,
                              _selectedDay.month,
                              _selectedDay.day,
                              _selectedTime!.hour,
                              _selectedTime!.minute);
                        });
                      }

                      final taskProvider =
                          Provider.of<TaskProvider>(context, listen: false);
                      final updatedTask =
                          widget.task.copyWith(deadline: _selectedDay);
                      await taskProvider.updateTask(updatedTask);

                      // Закрываем текущий экран и переходим на queue_screen
                      Navigator.pop(context); // Закрываем bottom sheet
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QueueScreen(task: updatedTask),
                        ),
                      );
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
