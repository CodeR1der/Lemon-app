import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:task_tracker/models/project_description.dart';
import 'package:task_tracker/screens/position_tasks_tab.dart';
import 'package:task_tracker/services/employee_operations.dart';
import 'package:task_tracker/services/project_operations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/employee.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../models/task_category.dart';
import '../services/task_categories.dart';
import '../services/task_operations.dart';
import 'employee_details_screen.dart';

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

  late final TabController _tabController;
  late final TaskService _taskService;
  late final EmployeeService _employeeService;
  late final Future<ProjectDescription?> _projectDescription;

  List<Employee> _communicators = [];
  List<Employee> _otherEmployees = [];
  List<Task> _taskList = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _taskService = TaskService();
    _employeeService = EmployeeService();
    _projectDescription =
        ProjectService().getProjectDescription(widget.project.projectDescription!.projectDescriptionId);
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadTasks();
    await _loadTeam();
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
      final employees = await ProjectService().getProjectTeam(widget.project.projectId);

      if (mounted) {
        setState(() {
          // Коммуникаторы - сотрудники с ролью "Коммуникатор" или те, кто указан как коммуникатор в задачах
          _communicators = employees.where((e) =>
          e.role == 'Коммуникатор' ||
              _taskList.any((task) => task.team.communicatorId.userId == e.userId)
          ).toList();

          // Остальные участники (исключая коммуникаторов)
          _otherEmployees = employees.where((e) =>
          e.role != 'Коммуникатор' &&
              !_communicators.any((c) => c.userId == e.userId)
          ).toList();
        });
      }
    } catch (e) {
      print('Ошибка при загрузке команды: $e');
      if (mounted) {
        setState(() {
          _communicators = [];
          _otherEmployees = [];
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
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(widget.project.name),
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
      body: TabBarView(
        controller: _tabController,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: _buildFutureTab(widget.project.projectId),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: _buildTeamTab(),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: _buildDescriptionTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildFutureTab(String projectId) {
    return FutureBuilder<List<TaskCategory>>(
      future: TaskCategories().getCategoriesProject( projectId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Ошибка: ${snapshot.error}'));
        } else if (!snapshot.hasData) {
          return const Center(child: Text('Нет данных'));
        }

        return PositionTasksTab(
          projectId: projectId,
        );
      },
    );
  }

  Widget _buildTeamTab() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          if (_communicators.isNotEmpty)
            _buildTeamSection('Коммуникатор', _communicators),
          if (_otherEmployees.isNotEmpty)
            _buildTeamSection('Команда проекта', _otherEmployees),
          // Добавляем отступ снизу для безопасной зоны
          SliverPadding(
            padding:
                EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
          ),
        ],
      ),
    );
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
          // Добавляем отступ снизу для безопасной зоны
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
              padding: const EdgeInsets.only(
                  left: 16.0, right: 16.0, top: 16, bottom: 4),
              child:
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
            );
          }
          return _buildEmployeeItem(employees[index - 1]);
        },
        childCount: employees.length + 1,
      ),
    );
  }



  Widget _buildEmployeeItem(Employee employee) {
    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: employee.avatarUrl!.isNotEmpty
            ? NetworkImage(_employeeService.getAvatarUrl(employee.avatarUrl))
            : null,
        child: employee.avatarUrl!.isEmpty ? const Icon(Icons.person) : null,
      ),
      title: Text(employee.name, style: Theme.of(context).textTheme.bodySmall),
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
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EmployeeDetailScreen(employee: employee),
          ),
        );
      },
    );
  }

  Future<void> _launchUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }
}

