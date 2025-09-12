import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:task_tracker/models/announcement.dart';
import 'package:task_tracker/screens/project/project_details_screen.dart';
import 'package:task_tracker/screens/task/tasks_list_screen.dart';
import 'package:task_tracker/services/announcement_operations.dart';
import 'package:task_tracker/services/announcement_provider.dart';
import 'package:task_tracker/services/employee_operations.dart';
import 'package:task_tracker/services/navigation_service.dart';
import 'package:task_tracker/services/project_operations.dart';
import 'package:task_tracker/services/user_service.dart';

import '../models/employee.dart';
import '../models/project.dart';
import '../models/task_category.dart';
import '../models/task_role.dart';
import '../models/task_status.dart';
import '../services/task_categories.dart';
import '../services/task_provider.dart';
import '../widgets/common/app_common.dart';
import 'announcement/announcement_screen.dart';
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
        Get.offNamed(
            '/auth'); // Предполагается, что AuthScreen имеет routeName '/auth'
        return;
      }

      // Загружаем категории задач
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      await taskProvider.loadTasksAndCategories(
        taskCategories: TaskCategories(),
        position: 'Исполнитель',
        employeeId: UserService.to.currentUser!.userId,
      );

      // Загружаем объявления через AnnouncementProvider
      final announcementProvider =
          Provider.of<AnnouncementProvider>(context, listen: false);
      await announcementProvider.loadAnnouncements(
          companyId: UserService.to.currentUser!.companyId);

      // Загружаем проекты
      final List<ProjectInformation> projectsWithCounts = [];
      final currentUser = UserService.to.currentUser!;
      final projects =
          await EmployeeService().getAllProjects(currentUser.userId);

      for (final project in projects) {
        final workersCount =
            await ProjectService().getAllWorkersCount(project.projectId);
        projectsWithCounts.add(ProjectInformation(project, workersCount));
      }
      _projects.assignAll(projectsWithCounts);

      // Загружаем сотрудников
      final employees = await EmployeeService().getAllEmployees();
      _employees.assignAll(employees
          .where((e) => e.userId != UserService.to.currentUser!.userId));
    } catch (e) {
    } finally {
      _isLoading.value = false;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _buildShimmerSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSpacing.height16,
          _buildShimmerUserInfo(),
          AppSpacing.height16,
          _buildShimmerSearchBox(),
          AppSpacing.height16,
          _buildShimmerButton(),
          AppSpacing.height16,
          if (UserService.to.currentUser!.role == 'Директор' ||
              UserService.to.currentUser!.role == 'Коммуникатор') ...[
            _buildShimmerAnnouncement()
          ],
          AppSpacing.height16,
          _buildShimmerSection(title: 'Мои задачи', itemCount: 4),
          AppSpacing.height16,
          _buildShimmerSection(
              title: 'Сотрудники', itemCount: 3, isHorizontal: true),
          AppSpacing.height16,
          _buildShimmerSection(
              title: 'Проекты', itemCount: 2, isHorizontal: true),
        ],
      ),
    );
  }

  Widget _buildShimmerUserInfo() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 150, height: 20, color: Colors.white),
              const SizedBox(height: 4),
              Container(width: 100, height: 16, color: Colors.white),
            ],
          ),
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerSearchBox() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildShimmerButton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildShimmerAnnouncement() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 100, height: 20, color: Colors.white),
            const SizedBox(height: 12),
            Container(height: 60, color: Colors.white),
            const SizedBox(height: 12),
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerSection(
      {required String title, int itemCount = 3, bool isHorizontal = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            width: 120,
            height: 24,
            color: Colors.white,
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: isHorizontal ? (title == 'Сотрудники' ? 180 : 140) : null,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            scrollDirection: isHorizontal ? Axis.horizontal : Axis.vertical,
            itemCount: itemCount,
            separatorBuilder: (context, index) =>
                isHorizontal ? const SizedBox(width: 10) : const Divider(),
            itemBuilder: (context, index) {
              return isHorizontal
                  ? _buildShimmerHorizontalItem()
                  : _buildShimmerListItem();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerHorizontalItem() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(left: 16),
        child: Column(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 12),
            Container(width: 80, height: 12, color: Colors.white),
            const SizedBox(height: 6),
            Container(width: 60, height: 10, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerListItem() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 120, height: 16, color: Colors.white),
                  const SizedBox(height: 4),
                  Container(width: 80, height: 14, color: Colors.white),
                ],
              ),
            ),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!UserService.to.isInitialized.value || _isLoading.value) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: _buildShimmerSkeleton(),
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
                    AppSpacing.height16,
                    _buildUserInfo(),
                    AppSpacing.height16,
                    _buildSearchBox(),
                    AppSpacing.height16,
                    _buildAddTaskButton(),
                    AppSpacing.height16,
                    if (UserService.to.currentUser!.role == 'Директор' ||
                        UserService.to.currentUser!.role == 'Коммуникатор') ...[
                      _buildAddAnnouncementButton(),
                      AppSpacing.height16,
                    ],
                    _buildAnnouncementSection(),
                    _buildTasksSection(),
                    AppSpacing.height16,
                    _buildEmployeesSection(),
                    AppSpacing.height16,
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
              user.fullName.split(' ').take(2).join(' '),
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
            ),
            Text(
              user.position,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
        // IconButton(
        //   icon: Stack(
        //     children: [
        //       const Icon(Icons.notifications),
        //       Positioned(
        //         right: 0,
        //         top: 0,
        //         child: Container(
        //           padding: const EdgeInsets.all(2),
        //           decoration: BoxDecoration(
        //             color: Colors.red,
        //             borderRadius: BorderRadius.circular(10),
        //           ),
        //           constraints: const BoxConstraints(
        //             minWidth: 16,
        //             minHeight: 16,
        //           ),
        //           child: const Text(
        //             '3', // TODO: Замените на реальное количество уведомлений
        //             style: TextStyle(
        //               color: Colors.white,
        //               fontSize: 10,
        //             ),
        //             textAlign: TextAlign.center,
        //           ),
        //         ),
        //       ),
        //     ],
        //   ),
        //   onPressed: () {
        //     // TODO: Реализуйте переход на экран уведомлений
        //     // Get.toNamed('/notifications');
        //   },
        // ),
      ],
    );
  }

  Widget _buildSearchBox() {
    return AppCommonWidgets.filledInputField(
      controller: TextEditingController(),
      hintText: 'Поиск по задачам и исполнителям',
      prefixIcon: const Icon(Icons.search, color: Colors.grey),
      enabled: false,
      onTap: () {
        Get.toNamed('/search');
      },
    ); //
  }

  Widget _buildAddTaskButton() {
    return AppButtons.primaryButton(
      text: 'Поставить задачу',
      icon: Iconsax.add_circle,
      onPressed: () async {
        await NavigationService.navigateToCreateTaskFromHome();
      },
    );
  }

  Widget _buildAddAnnouncementButton() {
    return AppButtons.secondaryButton(
      text: 'Написать объявление',
      onPressed: () async {
        final result = await Get.toNamed('/create_announcement');
        if (result == true) {
          // Объявление было создано, обновляем данные
          final announcementProvider =
              Provider.of<AnnouncementProvider>(context, listen: false);
          await announcementProvider.loadAnnouncements(
              companyId: UserService.to.currentUser!.companyId);
        }
      },
    );
  }

  Widget _buildAnnouncementSection() {
    return Consumer<AnnouncementProvider>(
      builder: (context, announcementProvider, child) {
        final currentUser = UserService.to.currentUser!;
        final announcements = announcementProvider.getAnnouncementsForUser(
          companyId: currentUser.companyId,
          userId: currentUser.userId,
          userRole: currentUser.role,
        );

        if (announcements.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          children: [
            _buildAnnouncementCard(announcements.last),
            AppSpacing.height16,
          ],
        );
      },
    );
  }

  Widget _buildAnnouncementCard(Announcement announcement) {
    final userRole = UserService.to.currentUser!.role;
    final showReadCount = userRole == 'Директор' || userRole == 'Коммуникатор';

    return GestureDetector(
      onTap: () {
        // Проверяем доступ к объявлению перед переходом
        final currentUser = UserService.to.currentUser!;
        final hasAccess = currentUser.role == 'Директор' ||
            currentUser.role == 'Коммуникатор' ||
            announcement.selectedEmployees.contains(currentUser.userId);

        if (hasAccess) {
          Get.toNamed('/announcement_detail', arguments: announcement);
        } else {
          Get.snackbar(
            'Ошибка доступа',
            'У вас нет доступа к этому объявлению',
            snackPosition: SnackPosition.TOP,
          );
        }
      },
      child: AppCommonWidgets.card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                      announcement.status == 'closed'
                          ? Icons.close
                          : Iconsax.flash_1,
                      size: 18,
                      color: announcement.status == 'closed'
                          ? Colors.grey
                          : Colors.red),
                  const SizedBox(width: 8),
                  Text(
                    announcement.status == 'closed'
                        ? 'ОБЪЯВЛЕНИЕ ЗАКРЫТО'
                        : 'ОБЪЯВЛЕНИЕ',
                    style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        color: announcement.status == 'closed'
                            ? Colors.grey
                            : Colors.red),
                  ),
                ],
              ),
              Text(announcement.title, style: AppTextStyles.bodyMedium),
              const SizedBox(height: 16),
              Text('Cтатус объявления', style: AppTextStyles.titleSmall),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 6.0),
                    decoration: AppContainerStyles.counterContainerDecoration,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Iconsax.eye, size: 18, color: Colors.black),
                        const SizedBox(width: 8),
                        FutureBuilder<List<String>>(
                          future: AnnouncementService()
                              .getSelectedEmployees(announcement.id),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Text(
                                'Прочитали ${announcement.readBy.length} из ${snapshot.data!.length}',
                                style: AppTextStyles.bodySmall,
                              );
                            }
                            return Text(
                              'Прочитали ${announcement.readBy.length} из ...',
                              style: AppTextStyles.bodySmall,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                  width: double.infinity,
                  child: AppButtons.secondaryButton(
                    text: UserService.to.currentUser!.role == 'Директор'
                        ? 'Посмотреть'
                        : 'Прочитать',
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AnnouncementDetailScreen(
                              announcement: announcement,
                            ),
                          ));
                    },
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTasksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Задачи', style: AppTextStyles.titleMedium),
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
              separatorBuilder: (context, index) =>
                  const Divider(color: Color(0xffbd7d8d9)),
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
    final icon = TaskCategories.getCategoryIcon(
        category.status); // Используем существующий метод

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 0.0),
      leading: Icon(icon, color: Colors.blue),
      title: Text(
        category.title,
        style: const TextStyle(fontSize: 16.0),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8.0),
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
    } catch (e) {}
  }

  Widget _buildEmployeesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 0.0),
          title: const Text('Сотрудники', style: AppTextStyles.titleMedium),
          trailing: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Text(
              _employees.length.toString(),
              style: const TextStyle(
                fontSize: 14.0,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        _employees.isEmpty
            ? AppCommonWidgets.emptyState('Нет сотрудников')
            : SizedBox(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _employees.length,
                  separatorBuilder: (context, index) => AppSpacing.width12,
                  itemBuilder: (context, index) =>
                      _buildEmployeeCell(_employees[index]),
                ),
              ),
      ],
    );
  }

  Widget _buildEmployeeCell(Employee employee) {
    return AppCommonWidgets.employeeCell(
      employee: employee,
      context: context,
    );
  }

  Widget _buildProjectsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 0.0),
          title: const Text('Проекты', style: AppTextStyles.titleMedium),
          trailing: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Text(
              _projects.length.toString(),
              style: const TextStyle(
                fontSize: 14.0,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        _projects.isEmpty
            ? AppCommonWidgets.emptyState('Нет проектов')
            : SizedBox(
                height: 150,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _projects.length,
                  separatorBuilder: (context, index) => AppSpacing.width6,
                  itemBuilder: (context, index) =>
                      _buildProjectCell(_projects[index]),
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
      child: Container(
        //padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
        width: 150,
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        decoration: AppContainerStyles.smallCardDecoration,
        child: AppCommonWidgets.card(
          padding: AppSpacing.paddingAll16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppCommonWidgets.avatar(
                radius: 17,
                imageUrl: project.project.avatarUrl,
                fallbackIcon: Icons.account_box,
              ),
              AppSpacing.height16,
              Text(
                project.project.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              AppSpacing.height4,
              Row(
                children: [
                  const Icon(Iconsax.profile_2user,
                      size: 16, color: Colors.grey),
                  AppSpacing.width6,
                  Text(
                    project.employees.toString(),
                    style: AppTextStyles.titleSmall,
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
