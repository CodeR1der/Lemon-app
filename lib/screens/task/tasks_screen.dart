import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:task_tracker/screens/task/task_details_screen.dart';

import '../../models/employee.dart';
import '../../models/task.dart';
import '../../services/task_categories.dart';
import '../../services/task_operations.dart';
import '../../services/task_provider.dart';
import '../../widgets/common/app_common_widgets.dart';
import '../../widgets/common/refresh_wrapper.dart';
import 'position_tasks_tab.dart';

class TasksScreen extends StatefulWidget {
  final Employee user;

  const TasksScreen({required this.user, super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Task> _allTasks = [];
  List<Task> _filteredTasks = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllTasksForSearch();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _isSearching = query.isNotEmpty;
      _filteredTasks = query.isEmpty
          ? []
          : _allTasks.where((task) =>
      task.taskName.toLowerCase().contains(query) ||
          task.description.toLowerCase().contains(query)).toList();
    });
  }

  Future<void> _refreshData() async {
    try {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      await taskProvider.loadTasksAndCategories(
        taskCategories: TaskCategories(),
        position: widget.user.role,
        employeeId: widget.user.userId,
      );
      await _loadAllTasksForSearch();
    } catch (e) {
      _showErrorSnackBar('Ошибка обновления задач: $e');
    }
  }

  Future<void> _loadAllTasksForSearch() async {
    try {
      List<Task> allTasks = [];
      final roles = widget.user.role == "Коммуникатор"
          ? ["Коммуникатор", "Исполнитель", "Постановщик", "Наблюдатель"]
          : ["Исполнитель", "Постановщик", "Наблюдатель"];

      for (String role in roles) {
        try {
          final tasks = await TaskService().getTasksByPosition(
            position: role,
            employeeId: widget.user.userId,
          );
          allTasks.addAll(tasks);
        } catch (e) {
          debugPrint('Ошибка загрузки задач для роли $role: $e');
        }
      }

      final uniqueTasks = <String, Task>{};
      for (var task in allTasks) {
        uniqueTasks[task.id] = task;
      }

      setState(() {
        _allTasks = uniqueTasks.values.toList();
      });
    } catch (e) {
      debugPrint('Ошибка загрузки задач для поиска: $e');
      _showErrorSnackBar('Не удалось загрузить задачи для поиска');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: 'Повторить',
          onPressed: _refreshData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;

    return DefaultTabController(
      length: user.role == "Коммуникатор" ? 4 : 3,
      child: Scaffold(
        appBar: AppBar(
          title: AppCommonWidgets.filledInputField(
            controller: _searchController,
            hintText: "Поиск",
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.clear, color: Colors.grey),
              onPressed: () => _searchController.clear(),
            )
                : null,
          ),
          bottom: _isSearching
              ? null
              : TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.center,
            tabs: [
              if (user.role == "Коммуникатор")
                const Tab(text: 'Я коммуникатор'),
              const Tab(text: 'Я исполнитель'),
              const Tab(text: 'Я постановщик'),
              const Tab(text: 'Я наблюдатель'),
            ],
          ),
        ),
        body: SafeArea(
          child: _isSearching
              ? _buildSearchResults()
              : TabBarView(
            children: [
              if (user.role == "Коммуникатор")
                _buildTab("Коммуникатор", user.userId),
              _buildTab("Исполнитель", user.userId),
              _buildTab("Постановщик", user.userId),
              _buildTab("Наблюдатель", user.userId),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_filteredTasks.isEmpty) {
      return RefreshWrapper(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - kToolbarHeight - kBottomNavigationBarHeight,
            child: const Center(
              child: Text(
                'Задачи не найдены',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          ),
        ),
      );
    }

    return RefreshWrapper(
      onRefresh: _refreshData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _filteredTasks.length,
        itemBuilder: (context, index) {
          final task = _filteredTasks[index];
          return _buildTaskCard(task);
        },
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          task.taskName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,//
            ),
            const SizedBox(height: 4),
            Text(
              'Проект: ${task.project?.name ?? 'Не указан'}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFEBEDF0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            task.status.toString().split('.').last,
            style: const TextStyle(fontSize: 12),
          ),
        ),
        onTap: () {
          try {
            Get.to(() => TaskDetailsScreen(task: task));
          } catch (e) {
            _showErrorSnackBar('Ошибка перехода к деталям задачи');
          }
        },
      ),
    );
  }

  Widget _buildTab(String position, String employeeId) {
    return RefreshWrapper(
      onRefresh: _refreshData,
      child: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          return PositionTasksTab(
            position: position,
            employeeId: employeeId,
          );
        },
      ),
    );
  }
}
