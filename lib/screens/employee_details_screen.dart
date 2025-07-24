import 'package:flutter/material.dart';
import 'package:task_tracker/screens/position_tasks_tab.dart';
import 'package:task_tracker/task_screens/taskTitleScreen.dart';

import '../models/employee.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../models/task_category.dart';
import '../services/employee_operations.dart';
import '../services/task_categories.dart';

class EmployeeDetailScreen extends StatefulWidget {
  final Employee employee;
  final EmployeeService _employeeService = EmployeeService();

  EmployeeDetailScreen({super.key, required this.employee});

  @override
  _EmployeeDetailScreenState createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen>
    with SingleTickerProviderStateMixin {
  final EmployeeService _employeeService = EmployeeService();
  late final ScrollController _scrollController;
  late final TabController _tabController;
  List<Project> _projects = [];
  Map<String, List<Task>> _projectTasks = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    try {
      final projects = await _employeeService.getEmployeeProjects(widget.employee.userId);
      final tasksMap = <String, List<Task>>{};

      // Загружаем задачи для каждого проекта
      for (final project in projects) {
        final tasks = await _employeeService.getEmployeeTasksByProject(
          widget.employee.userId,
          project.projectId,
        );
        tasksMap[project.projectId] = tasks;
      }

      setState(() {
        _projects = projects;
        _projectTasks = tasksMap;
        _tabController = TabController(length: _projects.length, vsync: this);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки проектов: $e')),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildAvatar() {
    return GestureDetector(
      child: Align(
        alignment: Alignment.centerLeft,
        child: CircleAvatar(
          radius: 50,
          backgroundImage: widget.employee.avatarUrl!.isNotEmpty
              ? NetworkImage(
            widget._employeeService.getAvatarUrl(widget.employee.avatarUrl),
          ) as ImageProvider
              : null,
          child: widget.employee.avatarUrl!.isEmpty
              ? const Icon(Icons.person, size: 50)
              : null,
        ),
      ),
    );
  }

  Widget _buildProfileSection(String title, String content) {
    final bool isLink = title == 'Имя пользователя в Телеграм' ||
        title == 'Адрес страницы в VK';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 13),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.grey,
            fontFamily: 'Roboto',
          ),
        ),
        Text(
          content.isNotEmpty ? content : "Не указан",
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Roboto',
            color: isLink ? Colors.blue : Colors.black,
            decoration: isLink ? TextDecoration.underline : null,
          ),
        ),
        const SizedBox(height: 13),
      ],
    );
  }

  Widget _buildProjectTab(String projectName, int taskCount) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(projectName),
        ],
      ),
    );
  }

  Widget _buildFutureTab(String position, String employeeId) {
    return FutureBuilder<List<TaskCategory>>(
      future: TaskCategories().getCategories(position, employeeId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Ошибка: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Нет данных'));
        }

        return PositionTasksTab(
          position: position,
          employeeId: employeeId,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final shortName = widget.employee.name.split(' ').take(2).join(' ');

    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          NestedScrollView(
            controller: _scrollController,
            floatHeaderSlivers: true,
            headerSliverBuilder: (BuildContext context, bool boxIsScrolled) {
              return [
                SliverAppBar(
                  pinned: true,
                  floating: true,
                  forceElevated: boxIsScrolled,
                  backgroundColor: Colors.white,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(shortName),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAvatar(),
                        _buildProfileSection('ФИО', widget.employee.name),
                        const Divider(),
                        _buildProfileSection(
                            'Должность', widget.employee.position),
                        const Divider(),
                        _buildProfileSection(
                            'Контактный телефон', widget.employee.phone ?? ''),
                        const Divider(),
                        _buildProfileSection('Имя пользователя в Теле-грам',
                            widget.employee.telegramId ?? ''),
                        const Divider(),
                        _buildProfileSection(
                            'Адрес страницы в VK', widget.employee.vkId ?? ''),
                      ],
                    ),
                  ),
                ),
                if (_projects.isNotEmpty)
                  SliverPersistentHeader(
                    delegate: _SliverAppBarDelegate(
                      TabBar(
                        controller: _tabController,
                        isScrollable: _projects.length > 2,
                        labelColor: const Color(0xFF6750A4),
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: const Color(0xFF6750A4),
                        tabs: _projects.map((project) {
                          final taskCount = _projectTasks[project.projectId]?.length ?? 0;
                          return _buildProjectTab(project.name, taskCount);
                        }).toList(),
                      ),
                    ),
                    pinned: true,
                  ),
              ];
            },
            body: _projects.isEmpty
                ? const Center(child: Text('Сотрудник не участвует в проектах'))
                : TabBarView(
              controller: _tabController,
              children: _projects.map((project) {
                return _buildFutureTab('Исполнитель', widget.employee.userId);
              }).toList(),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        TaskTitleScreen(employee: widget.employee),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9700),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle, color: Colors.white, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Поставить задачу',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}