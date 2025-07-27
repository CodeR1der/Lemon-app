import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/employee.dart';
import '../models/task.dart';
import '../services/employee_operations.dart';
import '../services/task_operations.dart';
import '../services/user_service.dart';

class TaskTeamTab extends StatefulWidget {
  final Task task;
  final TaskService _database = TaskService();

  TaskTeamTab({super.key, required this.task});

  @override
  _TaskTeamTab createState() => _TaskTeamTab();
}

class _TaskTeamTab extends State<TaskTeamTab> {
  List<Employee> _allEmployees = [];
  final List<Employee> _selectedEmployees = [UserService.to.currentUser!];
  bool _isLoadingEmployees = false;
  final EmployeeService _employeeService = EmployeeService();

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    setState(() => _isLoadingEmployees = true);
    try {
      final employees = await _employeeService.getAllEmployees();
      setState(() {
        _allEmployees = employees;
        _isLoadingEmployees = false;
      });
    } catch (e) {
      Get.snackbar('Ошибка', e.toString());
      setState(() => _isLoadingEmployees = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final team = widget.task.team;
    final hasTeamMembers = team.teamMembers.isNotEmpty;

    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Постановщик (creator)
            if (hasTeamMembers)
              _buildTeamMemberSection(
                context: context,
                title: 'Постановщик',
                employees: [team.creatorId],
              ),

            // Коммуникатор
            if (hasTeamMembers)
              _buildTeamMemberSection(
                context: context,
                title: 'Коммуникатор',
                employees: [team.communicatorId],
              ),

            // Исполнители (все кроме creator и communicator)
            if (hasTeamMembers)
              _buildTeamMemberSection(
                context: context,
                title: 'Исполнители',
                employees: team.teamMembers
                    .where((member) =>
                        member.userId != team.creatorId.userId &&
                        member.userId != team.communicatorId.userId)
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamMemberSection({
    required BuildContext context,
    required String title,
    required List<Employee> employees,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        for (var employee in employees)
          ListTile(
            contentPadding: EdgeInsets.zero,
            // Убраны внутренние отступы ListTile
            leading: CircleAvatar(
              backgroundImage: NetworkImage(
                  EmployeeService().getAvatarUrl(employee.avatarUrl!)),
              radius: 20,
            ),
            title: Text(
              employee.name,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            subtitle: Text(
              employee.position,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          ),
      ],
    );
  }

  void _showEmployeesModalSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              color: Colors.white,
              height: MediaQuery.of(context).size.height * 0.6,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Выберите сотрудников',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _isLoadingEmployees
                      ? const Center(child: CircularProgressIndicator())
                      : Expanded(
                          child: ListView.builder(
                            itemCount: _allEmployees.length,
                            itemBuilder: (context, index) {
                              final employee = _allEmployees[index];
                              final isSelected =
                                  _selectedEmployees.contains(employee);
                              return CheckboxListTile(
                                title: Text(employee.name ?? 'Без имени'),
                                subtitle: Text(employee.role ?? 'Без роли'),
                                value: isSelected,
                                onChanged: (bool? value) {
                                  setModalState(() {
                                    setState(() {
                                      if (value == true) {
                                        _selectedEmployees.add(employee);
                                      } else {
                                        _selectedEmployees.remove(employee);
                                      }
                                    });
                                  });
                                },
                                secondary: CircleAvatar(
                                  child: Text(employee.name[0] ?? 'N'),
                                ),
                              );
                            },
                          ),
                        ),
                  const SizedBox(height: 16),
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 30, horizontal: 16),
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Готово'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
