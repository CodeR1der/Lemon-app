import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:task_tracker/services/task_operations.dart';
import 'package:task_tracker/services/user_service.dart';
import 'package:task_tracker/task_screens/deadline_screen.dart';
import 'package:task_tracker/widgets/common/app_common.dart';
import 'package:uuid/uuid.dart';

import '../models/employee.dart';
import '../models/task.dart';
import '../models/task_team.dart';
import '../widgets/common/app_colors.dart';

class EmployeeSelectionScreen extends StatefulWidget {
  final Task taskData;
  final Employee?
      preSelectedEmployee; // Добавляем предварительно выбранного сотрудника

  const EmployeeSelectionScreen(this.taskData,
      {super.key, this.preSelectedEmployee});

  @override
  _EmployeeSelectionScreenState createState() =>
      _EmployeeSelectionScreenState();
}

class _EmployeeSelectionScreenState extends State<EmployeeSelectionScreen> {
  late Future<List<Employee>> employeesFuture;
  Employee? selectedPerformer;
  Employee? selectedCommunicator;
  Employee? selectedObserver;
  final TaskService _database = TaskService();

  @override
  void initState() {
    super.initState();
    // Если есть предварительно выбранный сотрудник, устанавливаем его как исполнителя
    if (widget.taskData.team.teamMembers.isNotEmpty) {
      selectedPerformer = widget.taskData.team.teamMembers.first;
    }

    employeesFuture = loadEmployees().then((employees) {
      if (selectedPerformer != null &&
          !employees.any((e) => e.userId == selectedPerformer!.userId)) {
        return [...employees, selectedPerformer!];
      }
      return employees;
    });
  }

  Future<List<Employee>> loadEmployees() async {
    // Загружаем только сотрудников из команды проекта
    return widget.taskData.project!.team;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Выбор сотрудников'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<Employee>>(
          future: employeesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return const Center(child: Text('Ошибка загрузки сотрудников'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                  child: Text('Нет доступных сотрудников в проекте'));
            }

            final employees = snapshot.data!;

            return Column(
              children: <Widget>[
                _buildEmployeeSelectionTile(
                  title: 'Исполнитель',
                  hintText: 'Выберите исполнителя',
                  selectedEmployee: selectedPerformer,
                  onSelected: (Employee? employee) {
                    if (_isEmployeeAlreadySelected(employee)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Этот сотрудник уже выбран')),
                      );
                    } else {
                      setState(() {
                        selectedPerformer = employee;
                      });
                    }
                  },
                  employees: employees
                      .where((employee) =>
                          employee.userId !=
                              UserService.to.currentUser!.userId &&
                          employee.role != 'Коммуникатор')
                      .toList(),
                  isSelected: widget.taskData.team.teamMembers.isNotEmpty,
                ),
                const SizedBox(height: 16),
                _buildEmployeeSelectionTile(
                  title: 'Коммуникатор',
                  hintText: 'Выберите коммуникатора',
                  selectedEmployee: selectedCommunicator,
                  onSelected: (Employee? employee) {
                    if (_isEmployeeAlreadySelected(employee)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Этот сотрудник уже выбран')),
                      );
                    } else {
                      setState(() {
                        selectedCommunicator = employee;
                      });
                    }
                  },
                  employees: employees
                      .where((employee) => employee.role == 'Коммуникатор')
                      .toList(),
                ),
                const SizedBox(height: 16),
                _buildEmployeeSelectionTile(
                  title: 'Наблюдатель',
                  hintText: 'Выберите наблюдателя',
                  selectedEmployee: selectedObserver,
                  onSelected: (Employee? employee) {
                    if (_isEmployeeAlreadySelected(employee)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Этот сотрудник уже выбран')),
                      );
                    } else {
                      setState(() {
                        selectedObserver = employee;
                      });
                    }
                  },
                  employees: employees
                      .where((employee) =>
                          employee.userId !=
                              UserService.to.currentUser!.userId &&
                          employee.role != 'Коммуникатор' &&
                          !_isEmployeeAlreadySelected(employee))
                      .toList(),
                ),
                const SizedBox(height: 16),
                const Spacer(),
                SizedBox(
                    width: double.infinity,
                    child: AppButtons.primaryButton(
                        text: 'Дальше',
                        onPressed: () {
                          if (selectedPerformer != null &&
                              selectedCommunicator != null) {
                            final newTeam = TaskTeam(
                              teamId: const Uuid().v4(),
                              taskId: widget.taskData.id,
                              communicatorId: selectedCommunicator!,
                              creatorId: UserService.to.currentUser!,
                              observerId: selectedObserver,
                              teamMembers: [selectedPerformer!],
                            );

                            widget.taskData.team = newTeam;

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    DeadlineScreen(widget.taskData),
                              ),
                            );
                          }
                        })),
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            );
          },
        ),
      ),
    );
  }

  bool _isEmployeeAlreadySelected(Employee? employee) {
    if (employee == null) return false;
    return employee == selectedPerformer ||
        employee == selectedCommunicator ||
        employee == selectedObserver ||
        employee == UserService.to.currentUser!;
  }

  Widget _buildEmployeeSelectionTile({
    required String title,
    required String hintText,
    required Employee? selectedEmployee,
    required ValueChanged<Employee?> onSelected,
    required List<Employee> employees,
    bool? isSelected,
  }) {
    final bool isDisabled = isSelected ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.titleSmall,
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.dropDownGrey, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.15),
                spreadRadius: 1,
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Employee?>(
              value: selectedEmployee,
              icon: const Icon(CupertinoIcons.chevron_down,
                  size: 20, color: AppColors.dropDownGrey),
              isExpanded: true,
              enableFeedback: false,
              dropdownColor: Colors.white,
              style: AppTextStyles.bodyLarge,
              borderRadius: BorderRadius.circular(12),
              onChanged: isDisabled ? null : onSelected,
              items: [
                DropdownMenuItem<Employee?>(
                  value: null,
                  child: Text(
                    hintText,
                    style: AppTextStyles.dropDownHint,
                  ),
                ),
                ...employees.map((employee) {
                  return DropdownMenuItem<Employee?>(
                    value: employee,
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: NetworkImage(
                              _database.getAvatarUrl(employee.avatarUrl)),
                          radius: 16,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            employee.name,
                            style: const TextStyle(fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
