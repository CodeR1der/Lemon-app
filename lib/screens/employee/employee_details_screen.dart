import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:task_tracker/screens/task/position_tasks_tab.dart';
import 'package:task_tracker/widgets/common/app_buttons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/employee.dart';
import '../../models/project.dart';
import '../../models/task.dart';
import '../../models/task_category.dart';
import '../../services/employee_operations.dart';
import '../../services/navigation_service.dart';
import '../../services/task_categories.dart';
import '../../services/user_service.dart';

class EmployeeDetailScreen extends StatefulWidget {
  final Employee employee;

  const EmployeeDetailScreen({super.key, required this.employee});

  @override
  _EmployeeDetailScreenState createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen>
    with SingleTickerProviderStateMixin {
  final EmployeeService _employeeService = EmployeeService();
  late final ScrollController _scrollController;
  TabController? _tabController;

  // State variables
  List<Project> _projects = [];
  Map<String, List<Task>> _projectTasks = {};
  bool _isLoading = true;
  String? _errorMessage;

  // Constants
  static const double _avatarRadius = 50.0;
  static const double _sectionSpacing = 13.0;
  static const double _padding = 16.0;
  static const Color _primaryColor = Color(0xFF6750A4);
  static const Color _accentColor = Color(0xFFFF9700);

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _loadProjects();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final projects =
          await _employeeService.getEmployeeProjects(widget.employee.userId);

      if (!mounted) return;

      final tasksMap = await _loadProjectTasks(projects);

      if (mounted) {
        setState(() {
          _projects = projects;
          _projectTasks = tasksMap;
          _tabController = TabController(length: projects.length, vsync: this);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Ошибка загрузки проектов: $e';
        });
      }
    }
  }

  Future<Map<String, List<Task>>> _loadProjectTasks(
      List<Project> projects) async {
    final tasksMap = <String, List<Task>>{};

    for (final project in projects) {
      if (!mounted) break;

      try {
        final tasks = await _employeeService.getEmployeeTasksByProject(
          widget.employee.userId,
          project.projectId,
        );
        tasksMap[project.projectId] = tasks;
      } catch (e) {
        // Log error but continue loading other projects
        print('Error loading tasks for project ${project.projectId}: $e');
        tasksMap[project.projectId] = [];
      }
    }

    return tasksMap;
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            _buildNestedScrollView(widget.employee.shortName),
            if (_shouldShowCreateTaskButton) _buildCreateTaskButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildNestedScrollView(String shortName) {
    return NestedScrollView(
      controller: _scrollController,
      floatHeaderSlivers: true,
      headerSliverBuilder: (BuildContext context, bool boxIsScrolled) {
        return [
          _buildSliverAppBar(shortName, boxIsScrolled),
          _buildProfileInfoSliver(),
          if (_projects.isNotEmpty && _tabController != null)
            _buildTabBarSliver(),
        ];
      },
      body: _buildBody(),
    );
  }

  Widget _buildSliverAppBar(String shortName, bool boxIsScrolled) {
    //
    return SliverAppBar(
      pinned: true,
      floating: true,
      forceElevated: boxIsScrolled,
      backgroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(shortName),
      ),
    );
  }

  Widget _buildProfileInfoSliver() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(_padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAvatar(),
            _buildProfileSection('ФИО', widget.employee.fullName),
            const Divider(),
            _buildProfileSection('Роль', widget.employee.role),
            const Divider(),
            _buildProfileSection('Должность', widget.employee.position),
            const Divider(),
            _buildProfileSection(
                'Контактный телефон', widget.employee.phone ?? ''),
            const Divider(),
            _buildProfileSection('Имя пользователя в Телеграм',
                widget.employee.telegramId ?? ''),
            const Divider(),
            _buildProfileSection(
                'Адрес страницы в VK', widget.employee.vkId ?? ''),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBarSliver() {
    return SliverPersistentHeader(
      delegate: _SliverAppBarDelegate(
        TabBar(
          tabAlignment: TabAlignment.center,
          controller: _tabController!,
          isScrollable: true,
          labelColor: _primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: _primaryColor,
          tabs: _projects.map((project) {
            final taskCount = _projectTasks[project.projectId]?.length ?? 0;
            return _buildProjectTab(project.name, taskCount);
          }).toList(),
        ),
      ),
      pinned: true,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProjects,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (_projects.isEmpty) {
      return const Center(child: Text('Сотрудник не участвует в проектах'));
    }

    if (_tabController == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return TabBarView(
      controller: _tabController!,
      children: _projects.map((project) {
        return _buildProjectTabView();
      }).toList(),
    );
  }

  Widget _buildAvatar() {
    return GestureDetector(
      child: Align(
        alignment: Alignment.centerLeft,
        child: CircleAvatar(
          radius: _avatarRadius,
          backgroundImage: _getAvatarImage(),
          child: _getAvatarChild(),
        ),
      ),
    );
  }

  ImageProvider? _getAvatarImage() {
    if (widget.employee.avatarUrl?.isNotEmpty == true) {
      return NetworkImage(
          _employeeService.getAvatarUrl(widget.employee.avatarUrl!));
    }
    return null;
  }

  Widget? _getAvatarChild() {
    if (widget.employee.avatarUrl?.isEmpty != false) {
      return const Icon(Icons.person, size: 50);
    }
    return null;
  }

  Widget _buildProfileSection(String title, String content) {
    final bool isLink = _isLinkField(title);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: _sectionSpacing),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.grey,
            fontFamily: 'Roboto',
          ),
        ),
        GestureDetector(
          onTap: () => _handleLink(title, content),
          onLongPress: () => _copyLink(title, content),
          child: Text(
            content.isNotEmpty ? content : "Не указан",
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Roboto',
              color: isLink ? Colors.blue : Colors.black,
              decoration: isLink ? TextDecoration.underline : null,
            ),
          ),
        ),
        const SizedBox(height: _sectionSpacing),
      ],
    );
  }

  bool _isLinkField(String title) {
    return title == 'Имя пользователя в Телеграм' ||
        title == 'Адрес страницы в VK';
  }

  Future<void> _handleLink(String title, String value) async {
    //
    if (value.isEmpty || value == "Не указан") return;

    final url = _buildUrl(title, value);
    if (url.isNotEmpty) {
      try {
        final Uri uri = Uri.parse(url);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        _showSnackBar('Неверный формат ссылки');
      }
    }
  }

  void _copyLink(String title, String value) {
    if (value.isEmpty || value == "Не указан") return;

    final textToCopy = _buildUrl(title, value);
    if (textToCopy.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: textToCopy));
      _showSnackBar('Ссылка скопирована в буфер обмена');
    }
  }

  String _buildUrl(String title, String value) {
    switch (title) {
      case 'Имя пользователя в Телеграм':
        final username = value.startsWith('@') ? value.substring(1) : value;
        return 'https://t.me/$username';
      case 'Адрес страницы в VK':
        if (value.startsWith('http')) {
          return value;
        }
        return 'https://vk.com/$value';
      default:
        return '';
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildProjectTab(String projectName, int taskCount) {
    return Tab(
      child: Container(
        constraints: const BoxConstraints(minWidth: 120),
        child: Text(
          projectName,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildProjectTabView() {
    return FutureBuilder<List<TaskCategory>>(
      future:
          TaskCategories().getCategories('Исполнитель', widget.employee.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Ошибка загрузки данных',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.inbox_outlined,
                      color: Colors.grey, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Нет данных для отображения',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          );
        }

        return SizedBox(
          child: PositionTasksTab(
            position: 'Исполнитель',
            employeeId: widget.employee.userId,
          ),
        );
      },
    );
  }

  Widget _buildCreateTaskButton() {
    return Positioned(
        left: _padding,
        right: _padding,
        bottom: _padding,
        child: AppButtons.primaryButton(
            text: 'Поставить задачу',
            icon: Iconsax.add_circle,
            onPressed: _navigateToCreateTask));
  }

  void _navigateToCreateTask() async {
    await NavigationService.navigateToCreateTaskForEmployee(widget.employee);
  }


  bool get _shouldShowCreateTaskButton {
    final currentUser = UserService.to.currentUser;
    return currentUser != null &&
        widget.employee.userId != currentUser.userId &&
        widget.employee.role != "Коммуникатор";
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
