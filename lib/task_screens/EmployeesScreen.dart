import 'package:flutter/material.dart';
import 'package:task_tracker/services/task_operations.dart';
import 'package:task_tracker/task_screens/DeadlineScreen.dart';
import '../models/employee.dart';
import '../models/task.dart';
import '../models/task_team.dart';

class EmployeeSelectionScreen extends StatefulWidget {
  final Task taskData;

  const EmployeeSelectionScreen(this.taskData, {super.key});

  @override
  _EmployeeSelectionScreenState createState() => _EmployeeSelectionScreenState();
}

class _EmployeeSelectionScreenState extends State<EmployeeSelectionScreen> {
  late Future<List<Employee>> employeesFuture;
  Employee? selectedPerformer;
  Employee? selectedCommunicator;
  final TaskService _database = TaskService();

  @override
  void initState() {
    super.initState();
    employeesFuture = loadEmployees();
  }

  Future<List<Employee>> loadEmployees() async {
    return _database.getAllEmployees();
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
              return const Center(child: Text('Нет доступных сотрудников'));
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
                        const SnackBar(content: Text('Этот сотрудник уже выбран')),
                      );
                    } else {
                      setState(() {
                        selectedPerformer = employee;
                      });
                    }
                  },
                  employees: employees,
                ),
                const SizedBox(height: 16),
                _buildEmployeeSelectionTile(
                  title: 'Коммуникатор',
                  selectedEmployee: selectedCommunicator,
                  onSelected: (Employee? employee) {
                    if (_isEmployeeAlreadySelected(employee)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Этот сотрудник уже выбран')),
                      );
                    } else {
                      setState(() {
                        selectedCommunicator = employee;
                      });
                    }
                  },
                  employees: employees,
                ),
                const SizedBox(height: 16),
                if (widget.taskData.team.teamMembers.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Текущая команда',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: widget.taskData.team.teamMembers.length,
                        itemBuilder: (context, index) {
                          final member = widget.taskData.team.teamMembers[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(
                                  _database.getAvatarUrl(member.avatarUrl)),
                            ),
                            title: Text(
                              member.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(member.position),
                          );
                        },
                      ),
                    ],
                  ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (selectedPerformer != null &&
                          selectedCommunicator != null) {
                        // Создаем новую команду или обновляем существующую
                        final newTeam = TaskTeam(
                          teamId: widget.taskData.team.teamId,
                          taskId: widget.taskData.id,
                          communicatorId: selectedCommunicator!,
                          creatorId: widget.taskData.team.creatorId,
                          teamMembers: [
                            ...widget.taskData.team.teamMembers,
                            selectedPerformer!,
                            selectedCommunicator!,
                          ],
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
    return employee == selectedPerformer || employee == selectedCommunicator;
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
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: DropdownButton<Employee>(
            value: selectedEmployee,
            hint: const Text('Выберите сотрудника'),
            icon: const Icon(Icons.arrow_drop_down),
            isExpanded: true,
            underline: Container(),
            onChanged: onSelected,
            items: employees.map((employee) {
              return DropdownMenuItem<Employee>(
                value: employee,
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(
                          _database.getAvatarUrl(employee.avatarUrl)),
                      radius: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(employee.name),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}