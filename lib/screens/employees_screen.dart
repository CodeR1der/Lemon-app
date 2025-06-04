import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:task_tracker/services/employee_operations.dart';

import '../models/employee.dart';
import '../services/user_service.dart';
import 'employee_details_screen.dart';

class EmployeesScreen extends StatefulWidget {
  @override
  _EmployeesScreenState createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  final EmployeeService _employeeService = EmployeeService();
  final UserService _userService = Get.find<UserService>();
  List<Employee> _employees = [];
  List<Employee> _filteredEmployees = [];
  TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
    _searchController.addListener(_filterEmployees);
  }

  Future<void> _loadEmployees() async {
    try {
      setState(() {
        _isLoading = true;
      });
      List<Employee> employees = await _employeeService.getAllEmployees();
      Employee? currentUser = _userService.currentUser;
      if (currentUser != null) {
        employees = employees.where((employee) => employee.userId != currentUser.userId).toList();
      }
      setState(() {
        _employees = employees;
        _filteredEmployees = employees;
      });
    } catch (e) {
      Get.snackbar('Ошибка', 'Не удалось загрузить сотрудников: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterEmployees() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredEmployees = _employees
          .where((employee) => employee.name.toLowerCase().contains(query))
          .toList();
    });
  }

  void changeRole(Employee employee, String newRole) async {
    try {
      // Создаем копию сотрудника с новой ролью
      final updatedEmployee = employee.copyWith(role: newRole);

      // Обновляем сотрудника в базе данных
      await _employeeService.updateEmployee(updatedEmployee);

      // Обновляем локальные списки
      setState(() {
        int index = _employees.indexWhere((e) => e.userId == employee.userId);
        if (index != -1) {
          _employees[index] = updatedEmployee;
        }
        int filteredIndex = _filteredEmployees.indexWhere((e) => e.userId == employee.userId);
        if (filteredIndex != -1) {
          _filteredEmployees[filteredIndex] = updatedEmployee;
        }
      });

      // Показываем уведомление об успехе
      Get.snackbar('Успех', 'Роль сотрудника ${employee.name} изменена на $newRole');
    } catch (e) {
      Get.snackbar('Ошибка', 'Не удалось изменить роль: $e');
    }
  }

  Widget _buildEmployeeIcons(Employee employee) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _buildIconWithNumber(Iconsax.archive_tick, 12),
        _buildIconWithNumber(Iconsax.timer, 2),
        _buildIconWithNumber(Iconsax.calendar_remove, 5),
        _buildIconWithNumber(Iconsax.task_square, 1),
        _buildIconWithNumber(Iconsax.search_normal, 7),
        _buildIconWithNumber(Iconsax.eye, 7),
      ],
    );
  }

  Widget _buildIconWithNumber(IconData icon, int count) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  void _showEmployeeOptions(Employee employee) {
    String? selectedAction;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                      'Назначить роль сотруднику',
                  style: TextStyle(color: Colors.black, fontSize: 18, fontFamily: 'Roboto'),),
                  RadioListTile<String?>(
                    title: const Text('Коммуникатором'),
                    value: 'Коммуникатор',
                    groupValue: selectedAction,
                    onChanged: (String? value) {
                      setModalState(() {
                        selectedAction = value;
                          if (value != null) {
                            changeRole(employee, value);
                          }
                      });
                      Navigator.pop(context);
                    },
                  ),
                  RadioListTile<String?>(
                    title: const Text('Руководителем'),
                    value: 'Руководитель',
                    groupValue: selectedAction,
                    onChanged: (String? value) {
                      setModalState(() {
                        selectedAction = value;
                        if (value != null) {
                          changeRole(employee, value);
                        }
                      });
                      Navigator.pop(context);
                    },
                  ),
                  RadioListTile<String?>(
                    title: const Text('Исполнитель / Постановщик'),
                    value: 'Исполнитель / Постановщик',
                    groupValue: selectedAction,
                    onChanged: (String? value) {
                      setModalState(() {
                        selectedAction = value;
                        if (value != null) {
                          changeRole(employee, value);
                        }
                      });
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredEmployees.length,
              itemBuilder: (context, index) {
                Employee employee = _filteredEmployees[index];
                return ListTile(
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundImage: employee.avatarUrl != ''
                        ? NetworkImage(
                        _employeeService.getAvatarUrl(employee.avatarUrl))
                        : null,
                    child: employee.avatarUrl == '' ? const Icon(Icons.person) : null,
                  ),
                  title: Text(employee.name,
                      style: Theme.of(context).textTheme.bodyLarge),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee.position,
                        style: const TextStyle(
                          color: Colors.black38,
                          fontSize: 13,
                          fontFamily: 'Roboto',
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildEmployeeIcons(employee),
                    ],
                  ),
                  trailing: _userService.currentUser?.role == 'Директор'
                      ? IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showEmployeeOptions(employee),
                  )
                      : null,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            EmployeeDetailScreen(employee: employee),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}