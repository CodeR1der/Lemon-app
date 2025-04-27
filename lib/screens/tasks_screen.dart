import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:task_tracker/models/task_status.dart';
import 'package:task_tracker/screens/projects_screen.dart';
import 'package:task_tracker/screens/tasks_list_screen.dart';
import 'package:task_tracker/services/task_operations.dart';
import '../models/task.dart';
import '../models/employee.dart';
import '../models/task_status.dart';

class TasksScreen extends StatefulWidget {
  final Employee user;

  const TasksScreen({required this.user, Key? key}) : super(key: key);

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with SingleTickerProviderStateMixin {
  late Future<Map<TaskStatus, int>> communicatorTasks;
  late Map<TaskStatus, List<Task>> creatorTasks;
  late Map<TaskStatus, List<Task>> workerTasks;
  late Map<TaskStatus, List<Task>> observerTasks;
  late TabController _tabController;
  final TaskService _database = TaskService();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCommunicatorTasks();
    // Количество вкладок зависит от роли пользователя
    int tabCount = widget.user.role == "Коммуникатор" ? 4 : 3;
    _tabController = TabController(length: tabCount, vsync: this);
  }

  Future<void> _loadCommunicatorTasks() async {
    communicatorTasks =
        _database.fetchCommunicatorTasksCount(widget.user.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            if (widget.user.role == "Коммуникатор") Tab(text: 'Я коммуникатор'),
            Tab(text: 'Я исполнитель'),
            Tab(text: 'Я постановщик'),
            Tab(text: 'Я наблюдатель'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          if (widget.user.role == "Коммуникатор") _buildCommunicatorTab(),
          _buildCommunicatorTab(),
          _buildCommunicatorTab(),
          _buildCommunicatorTab()
        ],
      ),
    );
  }

  Widget _buildCommunicatorTab() {
    return FutureBuilder<Map<TaskStatus, int>>(
      future: communicatorTasks, // Ваш Future<Map<TaskStatus, int>>
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Ошибка загрузки задач'));
        }

        final tasksCount = snapshot.data ?? {};

        return SingleChildScrollView(
          child: Column(
            children: [
              _buildTaskItem(
                icon: Iconsax.d_cube_scan_copy,
                status: StatusHelper.displayName(TaskStatus.newTask),
                count: tasksCount[TaskStatus.newTask] ?? 0,
              ),
              _buildTaskItem(
                icon: Iconsax.box_search_copy,
                status: StatusHelper.displayName(TaskStatus.revision),
                count: tasksCount[TaskStatus.revision] ?? 0,
              ),
              _buildTaskItem(
                icon: Iconsax.task_square_copy,
                status: StatusHelper.displayName(TaskStatus.inOrder),
                count: tasksCount[TaskStatus.inOrder] ?? 0,
              ),
              _buildTaskItem(
                icon: Iconsax.eye_copy,
                status: StatusHelper.displayName(TaskStatus.notRead),
                count: tasksCount[TaskStatus.notRead] ?? 0,
              ),
              _buildTaskItem(
                icon: Iconsax.stickynote_copy,
                status: StatusHelper.displayName(TaskStatus.queue),
                count: tasksCount[TaskStatus.queue] ?? 0,
              ),
              _buildTaskItem(
                icon: Iconsax.arrow_square_copy,
                status: StatusHelper.displayName(TaskStatus.controlPoint),
                count: tasksCount[TaskStatus.controlPoint] ?? 0,
              ),
              _buildTaskItem(
                icon: Iconsax.timer_copy,
                status: StatusHelper.displayName(TaskStatus.needExplanation),
                count: tasksCount[TaskStatus.needExplanation] ?? 0,
              ),
              _buildTaskItem(
                icon: Iconsax.edit_copy,
                status: StatusHelper.displayName(TaskStatus.needTicket),
                count: tasksCount[TaskStatus.needTicket] ?? 0,
              ),
              _buildTaskItem(
                icon: Iconsax.clock_copy,
                status: StatusHelper.displayName(TaskStatus.extraTime),
                count: tasksCount[TaskStatus.extraTime] ?? 0,
              ),
              _buildTaskItem(
                icon: Iconsax.archive_tick_copy,
                status: StatusHelper.displayName(TaskStatus.atWork),
                count: tasksCount[TaskStatus.atWork] ?? 0,
              ),
              _buildTaskItem(
                icon: Iconsax.calendar_remove_copy,
                status: StatusHelper.displayName(TaskStatus.overdue),
                count: tasksCount[TaskStatus.overdue] ?? 0,
              ),
              _buildTaskItem(
                icon: Iconsax.search_normal_copy,
                status: StatusHelper.displayName(
                    TaskStatus.completedUnderReview),
                count: tasksCount[TaskStatus.completedUnderReview] ?? 0,
              ),
              _buildTaskItem(
                icon: Iconsax.calendar_copy,
                status: StatusHelper.displayName(TaskStatus.newTask),
                count: tasksCount[TaskStatus.newTask] ?? 0,
              ),
              _buildTaskItem(
                icon: Iconsax.folder_open_copy,
                status: StatusHelper.displayName(TaskStatus.completed),
                count: tasksCount[TaskStatus.completed] ?? 0,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaskItem({
    required IconData icon,
    required String status,
    required int count,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskListByStatusScreen(
              userId: widget.user.userId,
              status: StatusHelper.toTaskStatus(status),
            ),
          ),
        );
      },
      child: Container(
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(icon, color: Color(0xFF2688EB)),
              title: Text(
                status,
                style: TextStyle(fontSize: 14),
              ),
              trailing: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            Divider(
              height: 1,
              thickness: 0.5,
              color: Colors.grey[300]!.withOpacity(0.5),
              indent: 16,
              endIndent: 16,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
