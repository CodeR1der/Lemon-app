import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:task_tracker/services/company_service.dart';
import 'package:task_tracker/services/employee_operations.dart';
import 'package:task_tracker/services/project_operations.dart'; // Для ProjectService
import 'package:task_tracker/services/task_operations.dart'; // Для TaskService
import 'package:task_tracker/widgets/common/app_common.dart';
import 'package:uuid/uuid.dart';

import '../../auth/qr_generator_screen.dart';
import '../../models/employee.dart';
import '../../models/project.dart';
import '../../models/task_status.dart';
import '../../services/user_service.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  _EmployeesScreenState createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  final EmployeeService _employeeService = EmployeeService();
  final TaskService _taskService = TaskService();
  final ProjectService _projectService = ProjectService();
  final UserService _userService = Get.find<UserService>();
  final CompanyService _companyService = CompanyService();
  List<Employee> _employees = [];
  List<Employee> _filteredEmployees = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  Map<String, Map<TaskStatus, int>> _employeeTaskCounts = {};

  // Кэш для проектов
  List<Project>? _cachedCompanyProjects;
  Map<String, List<Project>> _cachedEmployeeProjects = {};
  DateTime? _lastProjectsCacheTime;
  static const Duration _cacheExpiration = Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    _loadEmployees();
    _searchController.addListener(_filterEmployees);
  }

  Future<void> _loadEmployees() async {
    try {
      //
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
          .where((employee) => employee.fullName.toLowerCase().contains(query))
          .toList();
    });
  }

  // Проверка актуальности кэша
  bool _isCacheValid() {
    if (_lastProjectsCacheTime == null) return false;
    return DateTime.now().difference(_lastProjectsCacheTime!) <
        _cacheExpiration;
  }

  // Получение проектов компании с кэшированием
  Future<List<Project>> _getCompanyProjects() async {
    if (_cachedCompanyProjects != null && _isCacheValid()) {
      return _cachedCompanyProjects!;
    }

    try {
      final companyId = _userService.currentUser?.companyId;
      if (companyId == null || companyId.isEmpty) {
        print('Ошибка: companyId не найден');
        return [];
      }

      print('Загружаем проекты для компании: $companyId');
      final projects = await _projectService.getProjectsByCompany(companyId);

      print('Загружено проектов: ${projects.length}');
      _cachedCompanyProjects = projects;
      _lastProjectsCacheTime = DateTime.now();

      return projects;
    } catch (e) {
      print('Ошибка при загрузке проектов компании: $e');
      print('Тип ошибки: ${e.runtimeType}');
      return _cachedCompanyProjects ?? [];
    }
  }

  // Получение проектов сотрудника с кэшированием
  Future<List<Project>> _getEmployeeProjects(String employeeId) async {
    if (_cachedEmployeeProjects.containsKey(employeeId) && _isCacheValid()) {
      return _cachedEmployeeProjects[employeeId]!;
    }

    try {
      print('Загружаем проекты для сотрудника: $employeeId');
      final projects = await _projectService.getProjectsByEmployee(employeeId);

      print('Загружено проектов для сотрудника: ${projects.length}');
      _cachedEmployeeProjects[employeeId] = projects;

      return projects;
    } catch (e) {
      print('Ошибка при загрузке проектов сотрудника: $e');
      print('Тип ошибки: ${e.runtimeType}');
      return _cachedEmployeeProjects[employeeId] ?? [];
    }
  }

  // Очистка кэша проектов
  void _clearProjectsCache() {
    _cachedCompanyProjects = null;
    _cachedEmployeeProjects.clear();
    _lastProjectsCacheTime = null;
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
      Get.snackbar('Успех',
          'Роль сотрудника ${employee.shortName} изменена на $newRole');
    } catch (e) {}
  }

  Widget buildEmployeeIcons(Employee employee) {
    final taskCounts = _employeeTaskCounts[employee.userId] ?? {};

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
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
          _buildIconWithNumber(Iconsax.clock,
              taskCounts[TaskStatus.extraTime] ?? 0), // Доп. время
        ],
      ),
    );
  }

  Widget _buildIconWithNumber(IconData icon, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 8),
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  void _showEmployeeOptions(Employee employee) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              // Title
              const Text(
                'Действия с сотрудником',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Roboto',
                ),
              ),
              const SizedBox(height: 16),
              // Options
              _buildOptionTile(
                title: 'Изменить роль',
                onTap: () {
                  Navigator.pop(context);
                  _showRoleSelectionModal(employee);
                },
              ),
              _buildOptionTile(
                title: 'Назначить на проект',
                onTap: () {
                  Navigator.pop(context);
                  _showProjectAssignmentModal(employee);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionTile({
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: Row(
          children: [
            Text(title, style: AppTextStyles.bodyLarge),
            const Spacer(),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }

  void _showRoleSelectionModal(Employee employee) {
    String? selectedRole = employee.role;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Title
                  const Text(
                    'Назначить роль сотруднику',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Roboto',
                    ),
                  ),
                  const SizedBox(height: 16), //
                  // Role options
                  _buildRoleOption('Коммуникатор', selectedRole, (value) {
                    setModalState(() {
                      selectedRole = value;
                    });
                    if (value != null) {
                      changeRole(employee, value);
                    }
                    Navigator.pop(context);
                  }),
                  _buildRoleOption('Руководитель', selectedRole, (value) {
                    setModalState(() {
                      selectedRole = value;
                    });
                    if (value != null) {
                      changeRole(employee, value);
                    }
                    Navigator.pop(context);
                  }),
                  _buildRoleOption('Исполнитель / Постановщик', selectedRole,
                      (value) {
                    setModalState(() {
                      selectedRole = value;
                    });
                    if (value != null) {
                      changeRole(employee, value);
                    }
                    Navigator.pop(context);
                  }),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRoleOption(
      String role, String? selectedRole, ValueChanged<String?> onChanged) {
    bool isSelected = selectedRole == role;

    return InkWell(
      onTap: () => onChanged(role),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue : Colors.transparent,
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.grey[400]!,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(role, style: AppTextStyles.bodyLarge),
          ],
        ),
      ),
    );
  }

  void _showProjectAssignmentModal(Employee employee) async {
    try {
      // Получаем все проекты компании с кэшированием
      final companyProjects = await _getCompanyProjects();

      // Получаем проекты, в которых уже участвует сотрудник с кэшированием
      final employeeProjects = await _getEmployeeProjects(employee.userId);

      // Создаем список проектов с информацией о том, участвует ли сотрудник
      final projectsWithStatus = companyProjects.map((project) {
        final isInProject =
            employeeProjects.any((ep) => ep.projectId == project.projectId);
        return {
          'project': project,
          'isInProject': isInProject,
        };
      }).toList();

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (context) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return Container(
                padding: const EdgeInsets.all(16.0),
                width: double.infinity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Title
                    const Text(
                      'Назначить на проекты',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Roboto',
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Projects list
                    ...projectsWithStatus.map((projectData) {
                      final project = projectData['project'] as Project;
                      final isInProject = projectData['isInProject'] as bool;

                      return _buildProjectRoleOption(
                        project: project,
                        isInProject: isInProject,
                        onTap: () async {
                          try {
                            if (isInProject) {
                              // Удаляем из проекта
                              final success = await _projectService
                                  .removeEmployeeFromProject(
                                project.projectId,
                                employee.userId,
                              );
                              if (success) {
                                // Очищаем кэш для этого сотрудника
                                _cachedEmployeeProjects.remove(employee.userId);

                                Get.snackbar(
                                  'Успех',
                                  'Сотрудник удален из проекта "${project.name}"',
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                              }
                            } else {
                              // Добавляем в проект
                              final success =
                                  await _projectService.addEmployeeToProject(
                                project.projectId,
                                employee.userId,
                              );
                              if (success) {
                                // Очищаем кэш для этого сотрудника
                                _cachedEmployeeProjects.remove(employee.userId);

                                Get.snackbar(
                                  'Успех',
                                  'Сотрудник добавлен в проект "${project.name}"',
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                              }
                            }

                            // Обновляем состояние
                            setModalState(() {
                              projectData['isInProject'] = !isInProject;
                            });
                          } catch (e) {
                            print('Ошибка при изменении участия в проекте: $e');
                            Get.snackbar(
                              'Ошибка',
                              'Не удалось изменить участие в проекте',
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          }
                        },
                      );
                    }).toList(),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      print('Ошибка при загрузке проектов: $e');
      Get.snackbar(
        'Ошибка',
        'Не удалось загрузить проекты',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Widget _buildProjectRoleOption({
    required Project project,
    required bool isInProject,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isInProject ? Colors.blue : Colors.transparent,
                border: Border.all(
                  color: isInProject ? Colors.blue : Colors.grey[400]!,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: isInProject
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              project.name,
              style: AppTextStyles.bodyLarge,
            ),
          ],
        ),
      ),
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
        final TextEditingController firstNameController =
            TextEditingController();
        final TextEditingController lastNameController =
            TextEditingController();
        final TextEditingController middleNameController =
            TextEditingController();
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
                      const Text(
                        'Создать нового сотрудника',
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontFamily: 'Roboto'),
                      ),
                      const SizedBox(height: 16),
                      AppCommonWidgets.inputField(controller: lastNameController, hintText: 'Фамилия'),
                      AppSpacing.height8,
                      AppCommonWidgets.inputField(controller: firstNameController, hintText: 'Имя'),
                      AppSpacing.height8,
                      AppCommonWidgets.inputField(controller: middleNameController, hintText: 'Отчество'),
                      AppSpacing.height8,
                      AppCommonWidgets.inputField(controller: positionController, hintText: 'Должность'),
                      AppSpacing.height8,
                      AppCommonWidgets.inputPhoneField(phoneController: phoneController, hintText: 'Номер телефона'),

                      const SizedBox(height: 24),
                      AppButtons.primaryButton(
                          text: 'Создать',
                          onPressed: () async {
                            try {
                              if (firstNameController.text.isNotEmpty && lastNameController.text.isNotEmpty && phoneController.text.isNotEmpty &&
                                  positionController.text.isNotEmpty) {
                                final newEmployee = Employee(
                                  userId: const Uuid().v4(),
                                  // Temporary ID
                                  position: positionController.text,
                                  phone: phoneController.text,
                                  telegramId: null,
                                  // Optional field
                                  avatarUrl: 'default.jpg',
                                  vkId: null,
                                  // Optional field
                                  role: 'Исполнитель / Постановщик',
                                  // Default role..
                                  companyId:
                                      _userService.currentUser?.companyId ?? '',
                                  firstName: firstNameController.text,
                                  lastName: lastNameController.text,
                                  middleName: middleNameController.text ?? '',
                                );
                                await _employeeService.addEmployee(newEmployee);
                                Get.snackbar('Успех',
                                    'Сотрудник ${newEmployee.shortName} создан');
                                Navigator.pop(context);
                                _loadEmployees(); // Reload employees to include the new one
                                _clearProjectsCache(); // Очищаем кэш проектов
                              } else {
                                Get.snackbar(
                                    'Ошибка', 'Пожалуйста, заполните все поля');
                              }
                            } catch (e) {
                              print(e);
                            }
                          })
                    ],
                  ),
                );
              },
            ));
      },
    );
  }

  void _showCompanyQRCode() async {
    final companyCode = await _companyService
        .getCompanyCode(UserService.to.currentUser!.companyId);

    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => QRGeneratorScreen(companyId: companyCode!)));

    // final currentUser = _userService.currentUser;
    // if (currentUser == null) {
    //   Get.snackbar('Ошибка', 'Компания не найдена для текущего пользователя');
    //   return;
    // }
    //
    // try {
    //   final companyCode =
    //       await _companyService.getCompanyCode(currentUser.companyId);
    //   showModalBottomSheet(
    //     backgroundColor: Colors.white,
    //     context: context,
    //     shape: const RoundedRectangleBorder(
    //       borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    //     ),
    //     builder: (context) {
    //       return Padding(
    //         padding: const EdgeInsets.all(16.0),
    //         child: Column(
    //           mainAxisSize: MainAxisSize.min,
    //           crossAxisAlignment: CrossAxisAlignment.start,
    //           children: [
    //             const Text(
    //               'Код компании',
    //               style: TextStyle(
    //                 fontSize: 18,
    //                 fontWeight: FontWeight.bold,
    //                 fontFamily: 'Roboto',
    //               ),
    //             ),
    //             const SizedBox(height: 16),
    //             Text(
    //               companyCode ?? 'Код не найден',
    //               style: const TextStyle(fontSize: 16, fontFamily: 'Roboto'),
    //             ),
    //             const SizedBox(height: 16),
    //             Align(
    //               alignment: Alignment.center,
    //               child: ElevatedButton(
    //                 onPressed: () => Navigator.pop(context),
    //                 style: ElevatedButton.styleFrom(
    //                   backgroundColor: Colors.orange,
    //                   foregroundColor: Colors.white,
    //                 ),
    //                 child: const Text('Закрыть'),
    //               ),
    //             ),
    //           ],
    //         ),
    //       );
    //     },
    //   );
    // } catch (e) {
    //   Get.snackbar('Ошибка', 'Не удалось загрузить код компании');
    // }
  }

  @override
  Widget build(BuildContext context) {
    var bottomSheetHeight = 0.0;
    if (_userService.currentUser!.role == 'Директор') {
      bottomSheetHeight = 120.0;
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            AppCommonWidgets.filledInputField(
              controller: _searchController,
              hintText: 'Поиск',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshData, // ✅ обновление свайпом вниз
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: _filteredEmployees.length +
                      (_filteredEmployees.length > 1 ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == 1 && _filteredEmployees.length > 1) {
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: const Divider(
                          thickness: 1,
                          color: Colors.grey,
                        ),
                      );
                    }

                    int employeeIndex = index > 1 ? index - 1 : index;
                    Employee employee = _filteredEmployees[employeeIndex];
                    bool isCurrentUser =
                        employee.userId == _userService.currentUser?.userId;

                    return AppCommonWidgets.employeeTile(
                      employee: employee,
                      context: context,
                      contentPadding:
                      const EdgeInsets.symmetric(vertical: 4.0),
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
                            child: buildEmployeeIcons(employee),
                          ),
                        ],
                      ),
                      trailing: _userService.currentUser?.role ==
                          'Директор' &&
                          !isCurrentUser
                          ? Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: IconButton(
                          icon: const Icon(Icons.more_vert, size: 40),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () =>
                              _showEmployeeOptions(employee),
                        ),
                      )
                          : null,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _userService.currentUser?.role == 'Директор'
          ? SafeArea(
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppButtons.primaryButton(
                  text: 'Создать сотрудника',
                  onPressed: _showAddEmployeeDialog),
              const SizedBox(height: 8),
              AppButtons.secondaryButton(
                  text: 'Показать QR-код компании',
                  onPressed: _showCompanyQRCode),
            ],
          ),
        ),
      )
          : null,
    );
  }

  Future<void> _refreshData() async {
    await _loadEmployees();
    _clearProjectsCache();
  }

}
