import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task_tracker/models/employee.dart';
import 'package:task_tracker/models/task.dart';
import 'package:task_tracker/models/task_status.dart';
import 'package:task_tracker/screens/task/task_details_screen.dart';
import 'package:task_tracker/services/employee_operations.dart';
import 'package:task_tracker/services/task_operations.dart';
import 'package:task_tracker/services/user_service.dart';
import 'package:task_tracker/widgets/common/app_common_widgets.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TaskService _taskService = TaskService();
  final EmployeeService _employeeService = EmployeeService();

  List<Task> _tasks = [];
  List<Employee> _employees = [];
  List<Task> _filteredTasks = [];
  List<Employee> _filteredEmployees = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  bool _showAllTasks = false;
  bool _showAllEmployees = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    // Загружаем данные при инициализации
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = UserService.to.currentUser!;

      // Загружаем задачи в зависимости от роли пользователя
      List<Task> allTasks = [];
      if (currentUser.role == 'Директор' ||
          currentUser.role == 'Коммуникатор') {
        allTasks = await _taskService.getAllTasks();
      } else {
        allTasks = await _taskService.getTasksByPosition(
          position: currentUser.role,
          employeeId: currentUser.userId,
        );
      }

      // Загружаем всех сотрудников
      final allEmployees = await _employeeService.getAllEmployees();

      setState(() {
        _tasks = allTasks;
        _employees =
            allEmployees.where((e) => e.userId != currentUser.userId).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Ошибка загрузки данных: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      setState(() {
        _filteredTasks = [];
        _filteredEmployees = [];
        _hasSearched = false;
        // Сбрасываем состояния разворачивания при очистке поиска
        _showAllTasks = false;
        _showAllEmployees = false;
      });
      return;
    }

    setState(() {
      _filteredTasks = _tasks.where((task) {
        return task.taskName.toLowerCase().contains(query) ||
            task.description.toLowerCase().contains(query) ||
            task.project?.name.toLowerCase().contains(query) == true;
      }).toList();

      _filteredEmployees = _employees.where((employee) {
        return employee.fullName.toLowerCase().contains(query) ||
            employee.position.toLowerCase().contains(query);
      }).toList();

      _hasSearched = true;
    });
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _filteredTasks = [];
        _filteredEmployees = [];
        _hasSearched = false;
      });
      return;
    }

    // Применяем фильтрацию к уже загруженным данным
    _onSearchChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Поиск'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[200],
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _showAllTasks = false;
                      _showAllEmployees = false;
                    });
                  },
                )
                    : null,
                hintText: 'Поиск по задачам и исполнителям',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              ),
              onChanged: (value) => _performSearch(),
            ),
          ),
          if (_isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (!_hasSearched)
            Expanded(
              child: _buildInitialView(),
            )
          else
            Expanded(
              child: _buildSearchResults(),
            ),
        ],
      ),
    );
  }

  Widget _buildInitialView() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSectionHeader('Все задачи', _tasks.length),
        const SizedBox(height: 8),
        ...(_showAllTasks ? _tasks : _tasks.take(5))
            .map((task) => _buildTaskCard(task)),
        if (_tasks.length > 5) ...[
          const SizedBox(height: 8),
          Center(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _showAllTasks = !_showAllTasks;
                });
              },
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _showAllTasks
                          ? 'Скрыть задачи'
                          : 'Показать еще ${_tasks.length - 5} задач',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _showAllTasks
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        _buildSectionHeader('Все сотрудники', _employees.length),
        const SizedBox(height: 8),
        ...(_showAllEmployees ? _employees : _employees.take(5))
            .map((employee) => _buildEmployeeCard(employee)),
        if (_employees.length > 5) ...[
          const SizedBox(height: 8),
          Center(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _showAllEmployees = !_showAllEmployees;
                });
              },
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _showAllEmployees
                          ? 'Скрыть сотрудников'
                          : 'Показать еще ${_employees.length - 5} сотрудников',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _showAllEmployees
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_filteredTasks.isEmpty && _filteredEmployees.isEmpty) {
      return const Center(
        child: Text(
          'Ничего не найдено',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        if (_filteredTasks.isNotEmpty) ...[
          _buildSectionHeader('Задачи', _filteredTasks.length),
          const SizedBox(height: 8),
          ..._filteredTasks.map((task) => _buildTaskCard(task)),
          const SizedBox(height: 20),
        ],
        if (_filteredEmployees.isNotEmpty) ...[
          _buildSectionHeader('Сотрудники', _filteredEmployees.length),
          const SizedBox(height: 8),
          ..._filteredEmployees.map((employee) => _buildEmployeeCard(employee)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskCard(Task task) {
    return Card(
      color: Colors.white,
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
              overflow: TextOverflow.ellipsis,
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(StatusHelper.getStatusIcon(task.status), size: 16),
              const SizedBox(width: 6),
              Text(StatusHelper.displayName(task.status),
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        onTap: () {
          Get.to(() => TaskDetailsScreen(task: task));
        },
      ),
    );
  }

  Widget _buildEmployeeCard(Employee employee) {
    return AppCommonWidgets.employeeCard(
      employee: employee,
      context: context,
    );
  }
}