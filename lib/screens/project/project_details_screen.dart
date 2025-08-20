import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:task_tracker/models/project_description.dart';
import 'package:task_tracker/screens/task/position_tasks_tab.dart';
import 'package:task_tracker/services/employee_operations.dart';
import 'package:task_tracker/services/project_operations.dart';
import 'package:task_tracker/task_screens/task_title_screen.dart';
import 'package:task_tracker/widgets/common/app_buttons.dart';
import 'package:task_tracker/widgets/common/app_common_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/employee.dart';
import '../../models/project.dart';
import '../../models/task.dart';
import '../../models/task_status.dart';
import '../../services/task_operations.dart';
import '../../services/user_service.dart';
import '../../widgets/common/app_text_styles.dart';

class ProjectDetailsScreen extends StatefulWidget {
  final Project project;

  const ProjectDetailsScreen({Key? key, required this.project})
      : super(key: key);

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen>
    with SingleTickerProviderStateMixin {
  static const _primaryColor = Color(0xFF6750A4);
  List<Employee> _allEmployees = [];
  List<Employee> _projectEmployees = [];
  List<Employee> _tempSelectedEmployees = [];
  bool _isLoadingEmployees = false;

  late final TabController _tabController;
  late final TaskService _taskService;
  late final EmployeeService _employeeService;
  late final Future<ProjectDescription?> _projectDescription;

  List<Employee> _communicators = [];
  List<Employee> _otherEmployees = [];
  List<Task> _taskList = [];
  Map<String, Map<TaskStatus, int>> _employeeTaskCounts = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _taskService = TaskService();
    _employeeService = EmployeeService();
    _projectDescription = ProjectService().getProjectDescription(
        widget.project.projectDescription!.projectDescriptionId);
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadTasks();
    await _loadTeam();
    await _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    if (!mounted) return;

    setState(() => _isLoadingEmployees = true);
    try {
      final employees = await EmployeeService().getAllEmployees();
      // Загружаем количество задач для каждого сотрудника
      for (var employee in employees) {
        final taskCounts =
            await _taskService.getTasksAsExecutor(employee.userId);
        _employeeTaskCounts[employee.userId] = taskCounts;
      }
      if (mounted) {
        setState(() {
          _allEmployees = employees;
          _isLoadingEmployees = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingEmployees = false);
      }
    }
  }

  Future<void> _loadTasks() async {
    final tasks =
        await _taskService.getTasksByProjectId(widget.project.projectId);
    if (mounted) {
      setState(() => _taskList = tasks);
    }
  }

  Future<void> _loadTeam() async {
    try {
      final employees =
          await ProjectService().getProjectTeam(widget.project.projectId);
      if (mounted) {
        setState(() {
          _communicators = employees
              .where((e) =>
                  e.role == 'Коммуникатор' ||
                  _taskList.any(
                      (task) => task.team.communicatorId.userId == e.userId))
              .toList();

          _otherEmployees = employees
              .where((e) =>
                  e.role != 'Коммуникатор' &&
                  !_communicators.any((c) => c.userId == e.userId))
              .toList();

          // Обновляем список сотрудников проекта
          _projectEmployees = [..._communicators, ..._otherEmployees];
          _tempSelectedEmployees =
              List.from(_projectEmployees); // Копируем для редактирования
        });
      }
    } catch (e) {
      print('Ошибка при загрузке команды: $e');
      if (mounted) {
        setState(() {
          _communicators = [];
          _otherEmployees = [];
          _projectEmployees = [];
          _tempSelectedEmployees = [];
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(widget.project.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.orange),
            onPressed: () {
              Get.to(() => TaskTitleScreen(project: widget.project));
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //     builder: (context) =>
              //         TaskTitleScreen(project: widget.project),
              //   ),
              // );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: _primaryColor,
          indicatorColor: _primaryColor,
          labelPadding: EdgeInsets.zero,
          tabs: const [
            Tab(text: 'Задачи'),
            Tab(text: 'Команда проекта'),
            Tab(text: 'Описание'),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildFutureTab(widget.project.projectId),
            _buildTeamTab(),
            _buildDescriptionTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildFutureTab(String projectId) {
    return PositionTasksTab(
      projectId: projectId,
    );
  }

  Widget _buildTeamTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: CustomScrollView(
          slivers: [
            if (_communicators.isNotEmpty)
              _buildTeamSection('Коммуникатор', _communicators),
            if (_otherEmployees.isNotEmpty)
              _buildTeamSection('Команда проекта', _otherEmployees),
            SliverPadding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom),
            ),
          ],
        ),
        bottomSheet: UserService.to.currentUser!.role == 'Директор' ||
                UserService.to.currentUser!.role == 'Коммуникатор'
            ? AppButtons.secondaryButton(
                text: 'Добавить сотрудников',
                icon: Iconsax.user_cirlce_add,
                onPressed: _showEmployeesModalSheet)
            : null,
      ),
    );
  }

  void _showEmployeesModalSheet() {
    final itemHeight = 50.0; // Высота одного элемента списка
    final headerHeight = 100.0; // Высота заголовка и handle bar
    final paddingBottom = 16.0; // Отступ снизу
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final contentHeight = _isLoadingEmployees
            ? 200.0 // Высота для индикатора загрузки
            : headerHeight +
                (_allEmployees.length * itemHeight) +
                paddingBottom;

        final actualHeight = contentHeight;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              color: Colors.white,
              height: actualHeight,
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Title
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Прикрепить сотрудника',
                      style: AppTextStyles.titleLarge,
                    ),
                  ),
                  // Employee list
                  Expanded(
                    child: _isLoadingEmployees
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _allEmployees.length,
                            itemBuilder: (context, index) {
                              final employee = _allEmployees[index];
                              final isInProject =
                                  _tempSelectedEmployees.firstWhereOrNull(
                                          (e) => e.userId == employee.userId) !=
                                      null;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        setModalState(() {
                                          if (isInProject) {
                                            _tempSelectedEmployees
                                                .remove(employee);
                                          } else {
                                            _tempSelectedEmployees
                                                .add(employee);
                                          }
                                        });
                                      },
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: isInProject
                                              ? Colors.blue
                                              : Colors.white,
                                          border: Border.all(
                                            color: isInProject
                                                ? Colors.blue
                                                : Colors.grey[400]!,
                                            width: 2,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: isInProject
                                            ? const Icon(
                                                Icons.check,
                                                color: Colors.white,
                                                size: 16,
                                              )
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Avatar
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundImage:
                                          employee.avatarUrl != null &&
                                                  employee.avatarUrl!.isNotEmpty
                                              ? NetworkImage(
                                                  _employeeService.getAvatarUrl(
                                                      employee.avatarUrl!))
                                              : null,
                                      child: employee.avatarUrl == null ||
                                              employee.avatarUrl!.isEmpty
                                          ? Text(
                                              employee.name?.isNotEmpty == true
                                                  ? employee.name![0]
                                                      .toUpperCase()
                                                  : 'N',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    // Employee details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            employee.name ?? 'Без имени',
                                            style: AppTextStyles.bodySmall,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            employee.position ??
                                                'Без должности',
                                            style: AppTextStyles.caption,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) async {
      await ProjectService().updateProjectTeam(
        widget.project.projectId,
        _tempSelectedEmployees.map((e) => e.userId).toList(),
      );
      setState(() {
        _projectEmployees = List.from(_tempSelectedEmployees);
        _communicators = _projectEmployees
            .where((e) =>
                e.role == 'Коммуникатор' ||
                _taskList
                    .any((task) => task.team.communicatorId.userId == e.userId))
            .toList();
        _otherEmployees = _projectEmployees
            .where((e) =>
                e.role != 'Коммуникатор' &&
                !_communicators.any((c) => c.userId == e.userId))
            .toList();
      });
    });
  }

  Widget _buildDescriptionTab() {
    return FutureBuilder<ProjectDescription?>(
      future: _projectDescription,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
              child: Text('Ошибка загрузки данных',
                  style: Theme.of(context).textTheme.bodyMedium));
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return Center(
              child: Text('Данные не найдены',
                  style: Theme.of(context).textTheme.bodyMedium));
        }

        final projectDescription = snapshot.data!;
        return _buildProjectDescription(projectDescription);
      },
    );
  }

  Widget _buildProjectDescription(ProjectDescription description) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDescriptionSection("Проект", widget.project.name),
          _buildDescriptionSection("Описание проекта", description.description),
          _buildDescriptionSection("Цели проекта", description.goals),
          _buildLinkSection("Ссылка на проект", description.projectLink),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(content, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildLinkSection(String title, String link) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _launchUrl(link),
          child: Row(
            children: [
              const Icon(Iconsax.chrome_copy, size: 24, color: Colors.blue),
              const SizedBox(width: 12),
              Text(
                link,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSocialNetworksSection(Map<String, String> socialNetworks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Социальные сети", style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...['facebook', 'twitter', 'instagram', 'linkedin'].map((network) =>
            _buildSocialNetworkLink(
                network[0].toUpperCase() + network.substring(1),
                socialNetworks[network])),
      ],
    );
  }

  Widget _buildSocialNetworkLink(String networkName, String? link) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: InkWell(
        onTap: link != null ? () => _launchUrl(link) : null,
        child: Text(
          "$networkName: ${link ?? 'Не указано'}",
          style: TextStyle(
            fontSize: 16,
            color: link != null ? Colors.blue : Colors.grey,
            decoration:
                link != null ? TextDecoration.underline : TextDecoration.none,
          ),
        ),
      ),
    );
  }

  SliverList _buildTeamSection(String title, List<Employee> employees) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 0),
              child:
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
            );
          }
          return _buildEmployeeItem(employees[index - 1]);
        },
        childCount: employees.length + 1,
      ),
    );
  } //

  Widget _buildEmployeeItem(Employee employee) {
    return AppCommonWidgets.employeeTile(
      employee: employee,
      context: context,
      avatarRadius: 24,
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
          const SizedBox(height: 2),
          SizedBox(
            height: 16,
            child: buildEmployeeIcons(employee),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  Widget buildEmployeeIcons(Employee employee) {
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
}
