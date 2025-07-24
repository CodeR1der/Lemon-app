import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:task_tracker/services/company_service.dart';
import 'package:task_tracker/services/employee_operations.dart';
import 'package:task_tracker/services/task_operations.dart'; // Для TaskService

import '../models/employee.dart';
import '../models/task_status.dart';
import '../services/user_service.dart';
import 'employee_details_screen.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  _EmployeesScreenState createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  final EmployeeService _employeeService = EmployeeService();
  final TaskService _taskService = TaskService();
  final UserService _userService = Get.find<UserService>();
  final CompanyService _companyService = CompanyService();
  List<Employee> _employees = [];
  List<Employee> _filteredEmployees = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  final Map<String, Map<TaskStatus, int>> _employeeTaskCounts = {};

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

      // Загружаем количество задач для каждого сотрудника
      for (var employee in employees) {
        final taskCounts = await _taskService.getTasksAsExecutor(employee.userId);
        _employeeTaskCounts[employee.userId] = taskCounts;
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
      final updatedEmployee = employee.copyWith(role: newRole);
      await _employeeService.updateEmployee(updatedEmployee);
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
      Get.snackbar('Успех', 'Роль сотрудника ${employee.name} изменена на $newRole');
    } catch (e) {
      Get.snackbar('Ошибка', 'Не удалось изменить роль: $e');
    }
  }

  Widget _buildEmployeeIcons(Employee employee) {
    final taskCounts = _employeeTaskCounts[employee.userId] ?? {};

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _buildIconWithNumber(Iconsax.archive_tick, taskCounts[TaskStatus.atWork] ?? 0), // Сейчас в работе
        _buildIconWithNumber(Iconsax.task_square, taskCounts[TaskStatus.queue] ?? 0), // В очереди
        _buildIconWithNumber(Iconsax.calendar_remove, taskCounts[TaskStatus.overdue] ?? 0), // Просроченные
        _buildIconWithNumber(Iconsax.edit, taskCounts[TaskStatus.needTicket] ?? 0), //Нужно письмо решение
        _buildIconWithNumber(Iconsax.eye, taskCounts[TaskStatus.notRead] ?? 0), // Не прочитано
        _buildIconWithNumber(Iconsax.search_normal, taskCounts[TaskStatus.completedUnderReview] ?? 0), // На проверке
        _buildIconWithNumber(Iconsax.clock, taskCounts[TaskStatus.extraTime] ?? 0), // Доп. время
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
                  const Text(
                    'Назначить роль сотруднику',
                    style: TextStyle(color: Colors.black, fontSize: 18, fontFamily: 'Roboto'),
                  ),
                  RadioListTile<String?>(
                    title: const Text('Коммуникатор'),
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
                    title: const Text('Руководитель'),
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

  void _showCompanyCode() async {
    final currentUser = _userService.currentUser;
    if (currentUser == null) {
      Get.snackbar('Ошибка', 'Компания не найдена для текущего пользователя');
      return;
    }

    try {
      final companyCode = await _companyService.getCompanyCode(currentUser.companyId);
      showModalBottomSheet(
        backgroundColor: Colors.white,
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Код компании',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto',
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  companyCode ?? 'Код не найден',
                  style: const TextStyle(fontSize: 16, fontFamily: 'Roboto'),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.center,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Закрыть'),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      Get.snackbar('Ошибка', 'Не удалось загрузить код компании: $e');
    }
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
                  contentPadding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0), // Уменьшаем внутренние отступы
                  leading: CircleAvatar(
                    radius: 20, // Уменьшаем радиус с 24 до 20
                    backgroundImage: employee.avatarUrl != ''
                        ? NetworkImage(_employeeService.getAvatarUrl(employee.avatarUrl))
                        : null,
                    child: employee.avatarUrl == '' ? const Icon(Icons.person, size: 20) : null,
                  ),
                  title: Text(
                    employee.name,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 16), // Немного уменьшаем шрифт
                    maxLines: 1, // Ограничиваем до одной строки
                    overflow: TextOverflow.ellipsis, // Обрезаем длинные имена
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee.position,
                        style: const TextStyle(
                          color: Colors.black38,
                          fontSize: 12, // Уменьшаем размер шрифта
                          fontFamily: 'Roboto',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2), // Уменьшаем отступ
                      SizedBox(
                        height: 16, // Ограничиваем высоту строки иконок
                        child: _buildEmployeeIcons(employee),
                      ),
                    ],
                  ),
                  trailing: _userService.currentUser?.role == 'Директор'
                      ? IconButton(
                    icon: const Icon(Icons.more_vert, size: 40),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _showEmployeeOptions(employee),
                  )
                      : null,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EmployeeDetailScreen(employee: employee),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _userService.currentUser?.role == 'Директор'
          ? BottomAppBar(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ElevatedButton(
            onPressed: _showCompanyCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('Показать код компании'),
          ),
        ),
      )
          : null,
    );
  }
}