import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../models/employee.dart';
import '../services/employee_operations.dart';

class EmployeeDetailScreen extends StatefulWidget {
  final Employee employee;
  final EmployeeService _employeeService = EmployeeService();

  EmployeeDetailScreen({Key? key, required this.employee}) : super(key: key);

  @override
  _EmployeeDetailScreenState createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // Две вкладки
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildAvatar() {
    return GestureDetector(
      child: Align(
        alignment: Alignment.centerLeft,
        child: CircleAvatar(
          radius: 50,
          backgroundImage: widget.employee.avatar_url != ''
              ? NetworkImage(
            widget._employeeService
                .getAvatarUrl(widget.employee.avatar_url),
          )
              : null,
          child: widget.employee.avatar_url == ''
              ? Icon(Icons.person, size: 50)
              : null,
        ),
      ),
    );
  }

  Widget _buildBorders(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 0.5,
          width: MediaQuery.of(context).size.width,
          color: Colors.grey.withOpacity(0.5),
        ),
      ],
    );
  }

  Widget _buildProfileSection(String title, String content) {
    bool isLink = title == 'Имя пользователя в Телеграм' ||
        title == 'Адрес страницы в VK';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 13),
        Text(
          title,
          style: TextStyle(
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
            color: isLink ? Colors.blue  : Colors.black,
          ),
        ),
        SizedBox(height: 13),
      ],
    );
  }

  // Универсальный метод для создания ListTile с числом в боксе
  Widget _buildTaskItem({
    required IconData icon,
    required String title,
    required int count,
  }) {
    return ListTile(
      leading: Icon(icon, color: Color(0xFF2688EB)),
      title: Text(title),
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
    );
  }

  // Список задач для S3 Stores Inc
  Widget _buildS3StoresTasks() {
    return ListView(
      children: [
        _buildTaskItem(
          icon: Iconsax.archive_tick_copy,
          title: 'В работе',
          count: 12,
        ),
        _buildTaskItem(
          icon: Iconsax.timer_copy,
          title: 'Подходит время сдачи',
          count: 5,
        ),
        _buildTaskItem(
          icon: Iconsax.calendar_remove_copy,
          title: 'Просроченные задачи',
          count: 2,
        ),
        _buildTaskItem(
          icon: Iconsax.task_square_copy,
          title: 'Поставить в очередь на выполнение',
          count: 0,
        ),
        _buildTaskItem(
          icon: Iconsax.eye_copy,
          title: 'Не прочитал / не понял',
          count: 8,
        ),
        _buildTaskItem(
          icon: Iconsax.search_normal_copy,
          title: 'Завершенные задачи на проверке',
          count: 3,
        ),
        _buildTaskItem(
          icon: Iconsax.microscope_copy,
          title: 'Наблюдатель',
          count: 1,
        ),
        _buildTaskItem(
          icon: Iconsax.folder_open_copy,
          title: 'Архив задач',
          count: 15,
        ),
      ],
    );
  }

  // Список задач для PRT
  Widget _buildPRTTasks() {
    return ListView(
      children: [
        _buildTaskItem(
          icon: Iconsax.archive_tick_copy,
          title: 'В работе',
          count: 7,
        ),
        _buildTaskItem(
          icon: Iconsax.timer_copy,
          title: 'Подходит время сдачи',
          count: 4,
        ),
        _buildTaskItem(
          icon: Iconsax.calendar_remove_copy,
          title: 'Просроченные задачи',
          count: 1,
        ),
        _buildTaskItem(
          icon: Iconsax.task_square_copy,
          title: 'Поставить в очередь на выполнение',
          count: 0,
        ),
        _buildTaskItem(
          icon: Iconsax.eye_copy,
          title: 'Не прочитал / не понял',
          count: 2,
        ),
        _buildTaskItem(
          icon: Iconsax.search_normal_copy,
          title: 'Завершенные задачи на проверке',
          count: 6,
        ),
        _buildTaskItem(
          icon: Iconsax.microscope_copy,
          title: 'Наблюдатель',
          count: 0,
        ),
        _buildTaskItem(
          icon: Iconsax.folder_open_copy,
          title: 'Архив задач',
          count: 9,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(widget.employee.name),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatar(),
                _buildProfileSection('ФИО', widget.employee.name),
                _buildBorders(context),
                _buildProfileSection('Должность', widget.employee.position),
                _buildBorders(context),
                _buildProfileSection(
                    'Контактный телефон', widget.employee.phone?? ''),
                _buildBorders(context),
                _buildProfileSection(
                    'Имя пользователя в Телеграм', widget.employee.telegram_id ?? ''),
                _buildBorders(context),
                _buildProfileSection(
                    'Адрес страницы в VK', widget.employee.vk_id?? ''),
              ],
            ),
          ),
          // Вкладки с задачами
          TabBar(
            controller: _tabController,
            labelColor: Color(0xFF6750A4),
            indicatorColor: Color(0xFF6750A4),
            tabs: const [
              Tab(text: 'S3 Stores Inc'),
              Tab(text: 'PRT'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildS3StoresTasks(),
                _buildPRTTasks(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}