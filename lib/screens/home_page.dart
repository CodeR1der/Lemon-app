import 'package:flutter/material.dart';
import 'package:task_tracker/screens/project_details_screen.dart';
import 'package:task_tracker/screens/tasks_list_screen.dart';
import 'package:task_tracker/services/employee_operations.dart';
import 'package:task_tracker/services/project_operations.dart';
import 'package:task_tracker/services/user_service.dart';

import '../models/employee.dart';
import '../models/project.dart';
import '../models/task_category.dart';
import '../models/task_status.dart';
import '../services/task_categories.dart';
import '../task_screens/taskTitleScreen.dart';
import 'employee_details_screen.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/homePage';
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ProjectInformation> _projects = [];
  List<Employee> _employees = [];
  late final Future<List<TaskCategory>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _loadProjects();
    _loadEmployees();
    _categoriesFuture = TaskCategories().getCategories(
      'Исполнитель',
      UserService.to.currentUser!.userId,
    );
  }

  Future<void> _loadProjects() async {
    try {
      final List<ProjectInformation> projectsWithCounts = [];
      final currentUser = UserService.to.currentUser!;
      final projects =
          await EmployeeService().getAllProjects(currentUser.userId);

      for (final project in projects) {
        final workersCount =
            await ProjectService().getAllWorkersCount(project.projectId);
        projectsWithCounts.add(ProjectInformation(project, workersCount));
      }

      setState(() {
        _projects = projectsWithCounts;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки данных: ${e.toString()}')),
      );
    }
  }

  Future<void> _loadEmployees() async {
    try {
      final employees = await EmployeeService().getAllEmployees();

      setState(() {
        _employees = employees;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки данных: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildUserInfo(),
            const SizedBox(height: 20),
            _buildSearchBox(),
            const SizedBox(height: 20),
            _buildAddTaskButton(),
            const SizedBox(height: 20),
            _buildAnnouncementCard(),
            const SizedBox(height: 20),
            _buildTasksSection(),
            const SizedBox(height: 20),
            _buildEmployeesSection(),
            const SizedBox(height: 20),
            _buildProjectsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    var user = UserService.to.currentUser!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.name.split(' ').take(2).join(' '),
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
            ),
            Text(
              'Программист',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
        IconButton(
          icon: Stack(
            children: [
              const Icon(Icons.notifications),
              Positioned(
                // Красный кружок с количеством уведомлений
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: const Text(
                    '3', // Замените на реальное количество уведомлений
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          onPressed: () {
            // Переход на экран уведомлений
            // Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationsScreen()));
          },
        ),
      ],
    );
  }

  Widget _buildSearchBox() {
    return TextField(
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[200],
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        hintText: 'Поиск',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
    );
  }

  Widget _buildAddTaskButton() {
    return SizedBox(
      width: double.infinity, // занимает всю доступную ширину
      child: ElevatedButton(
        onPressed: () {
          Navigator.pushNamed(context, TaskTitleScreen.routeName);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 4,
          shadowColor: Colors.blue.withOpacity(0.3),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center, // центрируем содержимое
          mainAxisSize: MainAxisSize.max,
          children: [
            Icon(Icons.add, size: 20),
            SizedBox(width: 8),
            Text(
              'Поставить задачу',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок с иконкой
            const Row(
              children: [
                Icon(Icons.announcement, size: 20, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'ОБЪЯВЛЕНИЕ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Текст объявления
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Текст название объявления',
                style: TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 12),

            // Кнопка "Прочитать"
            SizedBox(
              width: double.infinity, // занимает всю доступную ширину
              child: OutlinedButton(
                onPressed: () {
                  // действие
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black,
                  // цвет текста и иконки
                  side: const BorderSide(color: Colors.orange, width: 1),
                  // цвет и толщина границы
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12), // закругление углов
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Прочитать',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Мои задачи',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<TaskCategory>>(
          future: TaskCategories().getCategories(
            'Исполнитель',
            UserService.to.currentUser!.userId,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Ошибка: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('Нет задач'));
            }

            final categories = snapshot.data!;

            return Column(
              children: categories
                  .map((category) => _buildTaskCategoryItem(category))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTaskCategoryItem(TaskCategory category) {
    final icon = StatusHelper.getStatusIcon(
        category.status); // Используем существующий метод

    return Column(
      children: [
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          leading: Icon(icon, color: Colors.blue),
          title: Text(
            category.title,
            style: const TextStyle(fontSize: 16),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              category.count.toString(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          onTap: () => () async {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) =>
                  const Center(child: CircularProgressIndicator()),
            );

            try {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TaskListByStatusScreen(
                    position: 'Исполнитель',
                    userId: UserService.to.currentUser!.userId,
                    status: category.status,
                  ),
                ),
              );
            } catch (e) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Ошибка: ${e.toString()}')),
              );
            }
          },
        ),
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildEmployeesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Сотрудники',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _employees.length.toString(),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 180, // Фиксированная высота для скроллируемой области
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _employees.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              return _buildEmployeeCell(_employees[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmployeeCell(Employee employee) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EmployeeDetailScreen(employee: employee),
          ),
        );
      },
      child: SizedBox(
        width: 120,
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              // Фиксированный контейнер для аватарки
              SizedBox(
                height: 68, // Радиус 34 * 2
                child: CircleAvatar(
                  radius: 34,
                  backgroundImage: (employee.avatarUrl != null &&
                          employee.avatarUrl!.isNotEmpty)
                      ? NetworkImage(
                          ProjectService().getAvatarUrl(employee.avatarUrl!) ??
                              '',
                        )
                      : null,
                  child: (employee.avatarUrl == null ||
                          employee.avatarUrl!.isEmpty)
                      ? const Icon(Icons.account_box, size: 34)
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              // Фиксированная высота для имени (2 строки)
              SizedBox(
                height: 32, // Примерная высота для 2 строк текста
                child: Text(
                  employee.name.split(' ').take(2).join(' '),
                  style: const TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              // Фиксированная высота для должности
              SizedBox(
                height: 20, // Примерная высота для 1 строки текста
                child: Text(
                  employee.position,
                  style: const TextStyle(fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Проекты',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _projects.length.toString(),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 140, // Фиксированная высота для скроллируемой области
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _projects.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              return _buildProjectCell(_projects[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProjectCell(ProjectInformation project) {
    return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ProjectDetailsScreen(project: project.project),
            ),
          );
        },
        child: SizedBox(
          width: 150, // Фиксированная ширина каждой ячейки
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                CircleAvatar(
                  radius: 17,
                  backgroundImage: (project.project.avatarUrl != null &&
                          project.project.avatarUrl!.isNotEmpty)
                      ? NetworkImage(
                          ProjectService()
                                  .getAvatarUrl(project.project.avatarUrl!) ??
                              '',
                        )
                      : null,
                  child: (project.project.avatarUrl == null ||
                          project.project.avatarUrl!.isEmpty)
                      ? const Icon(Icons.account_box, size: 17)
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  project.project.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.account_circle_sharp, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      project.employees.toString(),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ));
  }
}

class ProjectInformation {
  final Project project;
  final int employees;

  ProjectInformation(this.project, this.employees);
}
