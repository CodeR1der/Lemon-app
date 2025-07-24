import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_tracker/models/correction.dart';
import 'package:task_tracker/models/task_status.dart';
import 'package:task_tracker/services/employee_operations.dart';
import 'package:task_tracker/services/task_operations.dart';

import '../models/employee.dart';
import '../models/task.dart';
import '../services/request_operation.dart';
import '../services/task_provider.dart';
import '../services/user_service.dart';

class ChangeExecuterScreen extends StatefulWidget {
  final Task task;
  final Correction correction;

  const ChangeExecuterScreen(
      {super.key, required this.task, required this.correction});

  @override
  _ChangeExecuterScreen createState() => _ChangeExecuterScreen();
}

class _ChangeExecuterScreen extends State<ChangeExecuterScreen> {
  late Future<List<Employee>> employeesFuture;
  Employee? selectedPerformer;

  @override
  void initState() {
    super.initState();
    employeesFuture = loadEmployees();
  }

  Future<List<Employee>> loadEmployees() async {
    return EmployeeService().getAllEmployees();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Заменить исполнителя'),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FutureBuilder<List<Employee>>(
            future: employeesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return const Center(child: Text('Ошибка загрузки сотрудников'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('Нет доступных сотрудников'));
              }

              final employees = snapshot.data!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEmployeeSelectionTile(
                    title: 'Исполнитель',
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
                    employees: employees,
                  ),
                  const Spacer(),
                  Consumer<TaskProvider>(
                    builder: (context, taskProvider, child) => SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (selectedPerformer != null) {
                            // Создаем новую команду или обновляем существующую
                            RequestService().updateCorrection(
                                widget.correction..isDone = true);
                            TaskService().updateExecuter(
                                widget.task, selectedPerformer!);
                            widget.task.team.teamMembers.first =
                                selectedPerformer!;
                            taskProvider.updateTaskStatus(
                                widget.task, TaskStatus.inOrder);
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Заменить исполнителя'),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  bool _isEmployeeAlreadySelected(Employee? employee) {
    if (employee == null) return false;
    return employee == selectedPerformer ||
        employee == UserService.to.currentUser!;
  }

  Widget _buildEmployeeSelectionTile({
    required String title,
    required Employee? selectedEmployee,
    required ValueChanged<Employee?> onSelected,
    required List<Employee> employees,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey, width: 1),
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
              hint: const Text('Выберите сотрудника'),
              icon: const Icon(Icons.arrow_drop_down),
              isExpanded: true,
              dropdownColor: Colors.white,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
              borderRadius: BorderRadius.circular(12),
              onChanged: onSelected,
              items: [
                const DropdownMenuItem<Employee?>(
                  value: null,
                  child: Text('Выберите сотрудника'),
                ),
                ...employees.map((employee) {
                  const SizedBox(height: 4);
                  return DropdownMenuItem<Employee?>(
                    value: employee,
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: NetworkImage(EmployeeService()
                              .getAvatarUrl(employee.avatarUrl)),
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
                }).toList(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
