import 'package:flutter/material.dart';
import 'package:task_tracker/models/priority.dart';
import 'package:task_tracker/screens/task_details_screen.dart';
import 'package:task_tracker/services/task_operations.dart';

import '../models/task.dart';
import 'SelectPeriodScreen.dart';

class DeadlineScreen extends StatefulWidget {
  final Task taskData;

  const DeadlineScreen(this.taskData, {super.key});

  @override
  _DeadlinescreenState createState() => _DeadlinescreenState();
}

class _DeadlinescreenState extends State<DeadlineScreen> {
  DateTime selectedStartDate = DateTime.now();
  DateTime selectedEndDate = DateTime.now().add(const Duration(days: 1));
  Priority selectedPriority = Priority.low; // Значение по умолчанию
  final List<String> priorities = ['Низкий', 'Средний', 'Высокий'];
  final TaskService _database = TaskService();

  // Переход на экран SelectPeriodScreen
  Future<void> _selectPeriod() async {
    final List<DateTime>? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectPeriodScreen(
          selectedStartDate: selectedStartDate,
          selectedEndDate: selectedEndDate,
        ),
      ),
    );

    if (result != null && result.length == 2) {
      setState(() {
        selectedStartDate = result[0];
        selectedEndDate = result[1];
      });
    }
  }

  // Виджет для выбора приоритета
  Widget _buildPriorityDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: DropdownButton<Priority>(
        value: selectedPriority,
        hint: const Text('Выберите приоритет'),
        icon: const Icon(Icons.arrow_drop_down),
        isExpanded: true,
        underline: Container(),
        onChanged: (Priority? newValue) {
          setState(() {
            selectedPriority = newValue!;
          });
        },
        items: Priority.values.map((Priority priority) {
          return DropdownMenuItem<Priority>(
            value: priority,
            child: Text(priority.displayName), // Используем displayName
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Создание задачи'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: _selectPeriod, // Переход на SelectPeriodScreen
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Период: ${selectedStartDate.toLocal().toString().split(' ')[0]} - ${selectedEndDate.toLocal().toString().split(' ')[0]}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  textAlign: TextAlign.start,
                  "Приоритет",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildPriorityDropdown(),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  // Сохраняем данные в объекте задачи
                  widget.taskData.startDate = selectedStartDate;
                  widget.taskData.endDate = selectedEndDate;
                  widget.taskData.priority = selectedPriority;

                  // Показываем индикатор загрузки
                  showDialog(
                    context: context,
                    barrierDismissible: false, // Запрещаем закрывать вручную
                    builder: (context) {
                      return const AlertDialog(
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Сохранение задачи...'),
                          ],
                        ),
                      );
                    },
                  );

                  try {
                    // Дожидаемся завершения сохранения
                    await _database.addNewTask(widget.taskData);

                    // Закрываем индикатор загрузки
                    if (mounted) {
                      Navigator.of(context).pop();
                    }

                    // Показываем успешное сообщение
                    if (mounted) {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Успех'),
                            content: const Text('Задача успешно сохранена!'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context)
                                      .pop(); // Закрываем диалог

                                  // Переход на экран с задачей
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TaskDetailsScreen(
                                          task: widget.taskData),
                                    ),
                                  );
                                },
                                child: const Text('Принять'),
                              ),
                            ],
                          );
                        },
                      );
                    }
                  } catch (e) {
                    // Закрываем индикатор загрузки
                    if (mounted) {
                      Navigator.of(context).pop();
                    }

                    // Показываем сообщение об ошибке
                    if (mounted) {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Ошибка'),
                            content: Text('Не удалось сохранить задачу: $e'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('ОК'),
                              ),
                            ],
                          );
                        },
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Создать задачу'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
