import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:task_tracker/screens/project_details_screen.dart';
import 'package:task_tracker/screens/tasks_list_screen.dart';
import 'package:task_tracker/services/employee_operations.dart';
import 'package:task_tracker/services/project_operations.dart';
import 'package:task_tracker/services/user_service.dart';

import '../models/employee.dart';
import '../models/project.dart';
import '../models/task_category.dart';
import '../models/task_role.dart';
import '../models/task_status.dart';
import '../services/task_categories.dart';
import '../services/task_provider.dart';
import '../task_screens/taskTitleScreen.dart';
import 'employee_details_screen.dart';
import 'employee_queue_screen.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/homePage';
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final RxList<ProjectInformation> _projects = <ProjectInformation>[].obs;
  final RxList<Employee> _employees = <Employee>[].obs;
  final RxBool _isLoading = true.obs;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Ждем завершения инициализации пользователя
      if (!UserService.to.isInitialized.value) {
        await Future.doWhile(() async {
          await Future.delayed(const Duration(milliseconds: 100));
          return !UserService.to.isInitialized.value;
        });
      }

      // Проверяем авторизацию
      if (!UserService.to.isLoggedIn.value) {
        Get.offNamed('/auth'); // Предполагается, что AuthScreen имеет routeName '/auth'
        return;
      }

      // Загружаем категории задач
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      await taskProvider.loadTasksAndCategories(
        taskCategories: TaskCategories(),
        position: 'Исполнитель',
        employeeId: UserService.to.currentUser!.userId,
      );

      // Загружаем проекты
      final List<ProjectInformation> projectsWithCounts = [];
      final currentUser = UserService.to.currentUser!;
      final projects = await EmployeeService().getAllProjects(currentUser.userId);

      for (final project in projects) {
        final workersCount = await ProjectService().getAllWorkersCount(project.projectId);
        projectsWithCounts.add(ProjectInformation(project, workersCount));
      }
      _projects.assignAll(projectsWithCounts);

      // Загружаем сотрудников
      final employees = await EmployeeService().getAllEmployees();
      _employees.assignAll(employees);
    } catch (e) {
      _errorMessage = 'Ошибка загрузки данных: $e';
      Get.snackbar('Ошибка', _errorMessage!);
    } finally {
      _isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!UserService.to.isInitialized.value || _isLoading.value) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      if (!UserService.to.isLoggedIn.value) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.offNamed('/auth');
        });
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      return Scaffold(
        backgroundColor: Colors.white,
        body: _errorMessage != null
            ? Center(child: Text(_errorMessage!))
            : SingleChildScrollView(
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
    });
  }

  Widget _buildUserInfo() {
    final user = UserService.to.currentUser!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.name.split(' ').take(2).join(' '),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
            ),
            Text(
              user.position, // Используем position из Employee вместо хардкода
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
        IconButton(
          icon: Stack(
            children: [
              const Icon(Icons.notifications),
              Positioned(
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
                    '3', // TODO: Замените на реальное количество уведомлений
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
            // TODO: Реализуйте переход на экран уведомлений
            // Get.toNamed('/notifications');
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
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
      onChanged: (value) {
        // TODO: Реализуйте логику поиска
      },
    );
  }

  Widget _buildAddTaskButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Get.toNamed(TaskTitleScreen.routeName);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 4,
          shadowColor: Colors.blue.withOpacity(0.3),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Текст название объявления', // TODO: Замените на реальные данные
                style: TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  // TODO: Реализуйте действие для кнопки
                  Get.snackbar('Объявление', 'Действие для объявления');
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Colors.orange, width: 1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                ),
                child: const Text(
                  'Прочитать',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
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
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Мои задачи',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8.0),
        Consumer<TaskProvider>(
          builder: (context, taskProvider, child) {
            final categories = taskProvider.getCategories(
              RoleHelper.convertToString(TaskRole.executor),
              UserService.to.currentUser!.userId,
            );

            if (categories.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(1.0),
              itemCount: categories.length,
              separatorBuilder: (context, index) => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Divider(),
              ),
              itemBuilder: (context, index) {
                final category = categories[index];
                return _buildTaskCategoryItem(category);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildTaskCategoryItem(TaskCategory category) {
    final icon = StatusHelper.getStatusIcon(
        category.status); // Используем существующий метод

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      leading: Icon(icon, color: Colors.blue),
      title: Text(
        category.title,
        style: const TextStyle(fontSize: 16.0),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Text(
          category.count.toString(),
          style: const TextStyle(
            fontSize: 14.0,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      onTap: () => _handleCategoryTap(category),
    );
  }

  void _handleCategoryTap(TaskCategory category) async {
    try {
      if (category.status == TaskStatus.queue) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QueueScreen(
              position: RoleHelper.convertToString(TaskRole.executor),
              userId: UserService.to.currentUser!.userId,
            ),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskListByStatusScreen(
              position: RoleHelper.convertToString(TaskRole.executor),
              userId: UserService.to.currentUser!.userId,
              status: category.status,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки задач: ${e.toString()}')),
      );
    }
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _employees.length.toString(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _employees.isEmpty
            ? const Center(child: Text('Нет сотрудников'))
            : SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _employees.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) => _buildEmployeeCell(_employees[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildEmployeeCell(Employee employee) {
    return GestureDetector(
      onTap: () {
        Get.to(() => EmployeeDetailScreen(employee: employee));
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
              SizedBox(
                height: 68,
                child: CircleAvatar(
                  radius: 34,
                  backgroundImage: (employee.avatarUrl != null && employee.avatarUrl!.isNotEmpty)
                      ? NetworkImage(ProjectService().getAvatarUrl(employee.avatarUrl!) ?? '')
                      : null,
                  child: (employee.avatarUrl == null || employee.avatarUrl!.isEmpty)
                      ? const Icon(Icons.account_box, size: 34)
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 32,
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
              SizedBox(
                height: 20,
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _projects.length.toString(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _projects.isEmpty
            ? const Center(child: Text('Нет проектов'))
            : SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _projects.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) => _buildProjectCell(_projects[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildProjectCell(ProjectInformation project) {
    return GestureDetector(
      onTap: () {
        Get.to(() => ProjectDetailsScreen(project: project.project));
      },
      child: SizedBox(
        width: 150,
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
                backgroundImage: (project.project.avatarUrl != null && project.project.avatarUrl!.isNotEmpty)
                    ? NetworkImage(ProjectService().getAvatarUrl(project.project.avatarUrl!) ?? '')
                    : null,
                child: (project.project.avatarUrl == null || project.project.avatarUrl!.isEmpty)
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
      ),
    );
  }
}

class ProjectInformation {
  final Project project;
  final int employees;

  ProjectInformation(this.project, this.employees);
}