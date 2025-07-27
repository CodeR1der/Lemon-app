import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:task_tracker/services/company_service.dart';
import 'package:task_tracker/services/employee_operations.dart';
import 'package:task_tracker/services/task_operations.dart'; // Для TaskService
import 'package:uuid/uuid.dart';

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
  Map<String, Map<TaskStatus, int>> _employeeTaskCounts = {};

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
        // Находим текущего пользователя
        Employee? currentUserEmployee = employees.firstWhere(
          (employee) => employee.userId == currentUser.userId,
          orElse: () => currentUser,
        );

        // Разделяем на текущего пользователя и остальных
        List<Employee> otherEmployees = employees
            .where((employee) => employee.userId != currentUser.userId)
            .toList();

        // Сначала текущий пользователь, потом остальные
        employees = [currentUserEmployee, ...otherEmployees];
      }

      // Загружаем количество задач для каждого сотрудника
      for (var employee in employees) {
        final taskCounts =
            await _taskService.getTasksAsExecutor(employee.userId);
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
        int filteredIndex =
            _filteredEmployees.indexWhere((e) => e.userId == employee.userId);
        if (filteredIndex != -1) {
          _filteredEmployees[filteredIndex] = updatedEmployee;
        }
      });
      Get.snackbar(
          'Успех', 'Роль сотрудника ${employee.name} изменена на $newRole');
    } catch (e) {
      Get.snackbar('Ошибка', 'Не удалось изменить роль: $e');
    }
  }

  Widget _buildEmployeeIcons(Employee employee) {
    final taskCounts = _employeeTaskCounts[employee.userId] ?? {};

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _buildIconWithNumber(Iconsax.archive_tick,
            taskCounts[TaskStatus.atWork] ?? 0), // Сейчас в работе
        _buildIconWithNumber(Iconsax.task_square,
            taskCounts[TaskStatus.queue] ?? 0), // В очереди
        _buildIconWithNumber(Iconsax.calendar_remove,
            taskCounts[TaskStatus.overdue] ?? 0), // Просроченные
        _buildIconWithNumber(Iconsax.edit,
            taskCounts[TaskStatus.needTicket] ?? 0), //Нужно письмо решение
        _buildIconWithNumber(
            Iconsax.eye, taskCounts[TaskStatus.notRead] ?? 0), // Не прочитано
        _buildIconWithNumber(Iconsax.search_normal,
            taskCounts[TaskStatus.completedUnderReview] ?? 0), // На проверке
        _buildIconWithNumber(
            Iconsax.clock, taskCounts[TaskStatus.extraTime] ?? 0), // Доп. время
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
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontFamily: 'Roboto'),
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

  void _showAddEmployeeDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final TextEditingController nameController = TextEditingController();
        final TextEditingController positionController =
            TextEditingController();
        final TextEditingController phoneController = TextEditingController();

        return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Создать нового сотрудника',
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontFamily: 'Roboto'),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        textCapitalization: TextCapitalization.words,
                        controller: nameController,
                        decoration: InputDecoration(
                          hintText: 'ФИО',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: positionController,
                        decoration: InputDecoration(
                          hintText: 'Должность',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: phoneController,
                        decoration: InputDecoration(
                          hintText: 'Номер телефона',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            if (nameController.text.isNotEmpty &&
                                positionController.text.isNotEmpty) {
                              final newEmployee = Employee(
                                userId: const Uuid().v4(),
                                // Temporary ID
                                name: nameController.text,
                                position: positionController.text,
                                phone: phoneController.text,
                                telegramId: null,
                                // Optional field
                                avatarUrl: 'users/default.jpg',
                                vkId: null,
                                // Optional field
                                role: 'Исполнитель / Постановщик',
                                // Default role
                                companyId:
                                    _userService.currentUser?.companyId ?? '',
                              );
                              await _employeeService.addEmployee(newEmployee);
                              Get.snackbar('Успех',
                                  'Сотрудник ${newEmployee.name} создан');
                              Navigator.pop(context);
                              _loadEmployees(); // Reload employees to include the new one
                            } else {
                              Get.snackbar(
                                  'Ошибка', 'Пожалуйста, заполните все поля');
                            }
                          } catch (e) {
                            Get.snackbar(
                                'Ошибка', 'Не удалось создать сотрудника: $e');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: const Text('Создать'),
                      ),
                    ],
                  ),
                );
              },
            ));
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
      final companyCode =
          await _companyService.getCompanyCode(currentUser.companyId);
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
                Text(
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
                  style: TextStyle(fontSize: 16, fontFamily: 'Roboto'),
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
    const bottomSheetHeight = 0.0;
    if (_userService.currentUser!.role == 'Директор') const bottomSheetHeight = 120.0;
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.only(bottom: bottomSheetHeight),
              child: Column(
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
                      padding: EdgeInsets.zero,
                      itemCount: _filteredEmployees.length +
                          (_filteredEmployees.length > 1
                              ? 1
                              : 0), // +1 для разделителя
                      itemBuilder: (context, index) {
                        // Если это позиция для разделителя (после первого элемента)
                        if (index == 1 && _filteredEmployees.length > 1) {
                          return Container(
                            margin: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 16.0),
                            child: const Divider(
                              thickness: 1,
                              color: Colors.grey,
                            ),
                          );
                        }

                        // Корректируем индекс для получения сотрудника
                        int employeeIndex = index > 1 ? index - 1 : index;
                        Employee employee = _filteredEmployees[employeeIndex];
                        bool isCurrentUser =
                            employee.userId == _userService.currentUser?.userId;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 4.0, horizontal: 8.0),
                          leading: CircleAvatar(
                            radius: 20,
                            backgroundImage: employee.avatarUrl != ''
                                ? NetworkImage(_employeeService
                                    .getAvatarUrl(employee.avatarUrl))
                                : null,
                            child: employee.avatarUrl == ''
                                ? const Icon(Icons.person, size: 20)
                                : null,
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  employee.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(fontSize: 16),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                employee.position,
                                style: const TextStyle(
                                  color: Colors.black38,
                                  fontSize: 12,
                                  fontFamily: 'Roboto',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              SizedBox(
                                height: 16,
                                child: _buildEmployeeIcons(employee),
                              ),
                            ],
                          ),
                          trailing: _userService.currentUser?.role ==
                                      'Директор' &&
                                  !isCurrentUser
                              ? IconButton(
                                  icon: const Icon(Icons.more_vert, size: 40),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () =>
                                      _showEmployeeOptions(employee),
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
            ),
      bottomSheet: _userService.currentUser?.role == 'Директор'
          ? SafeArea(
              child: Container(
                color: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: _showAddEmployeeDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        side: const BorderSide(color: Colors.orange, width: 1),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: const Text('Создать сотрудника'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _showCompanyCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: const Text('Показать код компании'),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}
