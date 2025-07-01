import 'package:flutter/material.dart';
import 'package:task_tracker/models/task_role.dart';
import 'package:task_tracker/services/task_operations.dart';
import 'package:task_tracker/services/user_service.dart';
import 'package:task_tracker/task_screens/DeadlineScreen.dart';
import 'package:uuid/uuid.dart';

import '../models/employee.dart';
import '../models/task.dart';
import '../models/task_team.dart';

class EmployeeSelectionScreen extends StatefulWidget {
  final Task taskData;

  const EmployeeSelectionScreen(this.taskData, {super.key});

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
    employeesFuture = loadEmployees();
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
              return const Center(child: Text('Нет доступных сотрудников в проекте'));
            }

            final employees = snapshot.data!;

            return Column(
              children: <Widget>[
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
                  employees: employees.where((employee) => employee.userId != UserService.to.currentUser!.userId && employee.role != 'Коммуникатор').toList(),
                ),
                const SizedBox(height: 16),
                _buildEmployeeSelectionTile(
                  title: 'Коммуникатор',
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
                  employees: employees.where((employee) => employee.role == 'Коммуникатор').toList(),
                ),
                const SizedBox(height: 16),
                _buildEmployeeSelectionTile(
                  title: 'Наблюдатель',
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
                  employees: employees,
                ),
                const SizedBox(height: 16),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
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
                            builder: (context) => DeadlineScreen(widget.taskData),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Дальше'),
                  ),
                ),
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
                }).toList(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}