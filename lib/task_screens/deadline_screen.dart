import 'package:flutter/material.dart';
import 'package:task_tracker/models/priority.dart';
import 'package:task_tracker/services/project_operations.dart';
import 'package:task_tracker/services/task_operations.dart';
import 'package:task_tracker/task_screens/task_title_screen.dart';
import 'package:task_tracker/widgets/common/app_buttons.dart';
import 'package:task_tracker/widgets/common/app_spacing.dart';
import 'package:task_tracker/widgets/common/app_text_styles.dart';

import '../models/employee.dart';
import '../models/task.dart';
import '../screens/task/task_details_screen.dart';
import '../widgets/common/app_common_widgets.dart';
import 'select_period_screen.dart';

class DeadlineScreen extends StatefulWidget {
  final Task taskData;

  const DeadlineScreen(this.taskData, {super.key});

  @override
  _DeadlinescreenState createState() => _DeadlinescreenState();
}

class _DeadlinescreenState extends State<DeadlineScreen> {
  DateTime selectedStartDate = DateTime.now();
  DateTime selectedEndDate = DateTime.now().add(const Duration(days: 1));
  Priority selectedPriority = Priority.low;
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Приоритет',
          style: AppTextStyles.titleSmall,
        ),
        AppSpacing.height8,
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Priority>(
              value: selectedPriority,
              hint: const Text('Выберите приоритет'),
              icon: const Icon(Icons.keyboard_arrow_down,
                  size: 20, color: Colors.grey),
              isExpanded: true,
              underline: Container(),
              onChanged: (Priority? newValue) {
                setState(() {
                  selectedPriority = newValue!;
                });
              },
              dropdownColor: Colors.white,
              style: AppTextStyles.bodyLarge,
              borderRadius: BorderRadius.circular(12),
              items: Priority.values.map((Priority priority) {
                return DropdownMenuItem<Priority>(
                  value: priority,
                  child: Text(priority.displayName),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Создание задачи'),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Период выполнения
              Text(
                'Период выполнения',
                style: AppTextStyles.titleSmall,
              ),
              AppSpacing.height8,
              GestureDetector(
                onTap: _selectPeriod,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today,
                          color: Colors.grey[600], size: 20),
                      AppSpacing.width12,
                      Expanded(
                        child: Text(
                          '${selectedStartDate.toLocal().toString().split(' ')[0]} - ${selectedEndDate.toLocal().toString().split(' ')[0]}',
                          style: AppTextStyles.bodyLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(Icons.keyboard_arrow_right,
                          color: Colors.grey[600], size: 20),
                    ],
                  ),
                ),
              ),
              AppSpacing.height24,
              _buildPriorityDropdown(),
              const Spacer(),
              SizedBox(
                  width: double.infinity,
                  child: AppButtons.primaryButton(
                      text: 'Создать задачу',
                      onPressed: () async {
                        // Сохраняем данные в объекте задачи
                        widget.taskData.startDate = selectedStartDate;
                        widget.taskData.endDate = selectedEndDate;
                        widget.taskData.priority = selectedPriority;

                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) {
                            return const AlertDialog(
                              backgroundColor: Colors.white,
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
                          if (!widget.taskData.project!.team.contains(
                              widget.taskData.team.teamMembers.first)) {
                            _addEmployeeToProjectIfNeeded(
                                widget.taskData.team.teamMembers.first);
                          }

                          // Дожидаемся завершения сохранения
                          await _database.addNewTask(widget.taskData);

                          // Закрываем индикатор загрузки
                          if (mounted) {
                            Navigator.of(context).pop();
                          }

                          // Показываем успешное сообщение
                          if (mounted) {
                            AppCommonWidgets.showSuccessAlert(
                                onClose: () {
                                  Navigator.of(context).pop();

                                  Navigator.popUntil(
                                      context,
                                      ModalRoute.withName(
                                          TaskTitleScreen.routeName));
                                  Navigator.pop(context);

                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TaskDetailsScreen(
                                            task: widget.taskData),
                                      ));
                                },
                                title: 'Задача поставлена',
                                context: context,
                                message:
                                    'Вы можете ознакомиться с задачей которую поставили');
                            // showDialog(
                            //   context: context,
                            //   builder: (BuildContext context) {
                            //     return AlertDialog(
                            //       backgroundColor: AppColors.alertGreen,
                            //       title: const Text('Задача поставлена'),
                            //       content: const Text('Задача успешно сохранена!'),
                            //       actions: [
                            //         TextButton(
                            //           onPressed: () {
                            //             Navigator.of(context).pop();
                            //
                            //             Navigator.popUntil(
                            //                 context,
                            //                 ModalRoute.withName(
                            //                     TaskTitleScreen.routeName));
                            //             Navigator.pop(context);
                            //
                            //             Navigator.push(
                            //                 context,
                            //                 MaterialPageRoute(
                            //                   builder: (context) =>
                            //                       TaskDetailsScreen(
                            //                           task: widget.taskData),
                            //                 ));
                            //           },
                            //           child: const Text('Принять'),
                            //         ),
                            //       ],
                            //     );
                            //   },
                            // );
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
                                  content:
                                      Text('Не удалось сохранить задачу: $e'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: const Text('ОК'),
                                    ),
                                  ],
                                );
                              },
                            );
                          }
                        }
                      })),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }

  /// Добавляет сотрудника в команду проекта, если его там нет
  Future<void> _addEmployeeToProjectIfNeeded(Employee employee) async {
    try {
      final isInProject = await ProjectService().isEmployeeInProject(
          widget.taskData.project!.projectId, employee.userId);

      if (!isInProject) {
        final added = await ProjectService().addEmployeeToProject(
            widget.taskData.project!.projectId, employee.userId);

        if (added) {
          print('Сотрудник ${employee.name} добавлен в команду проекта');
          // Показываем уведомление пользователю об успешном добавлении
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Сотрудник ${employee.name} добавлен в команду проекта'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Ошибка при добавлении сотрудника в проект: $e');
      // Показываем уведомление пользователю
      if (mounted) {}
    }
  }
}
