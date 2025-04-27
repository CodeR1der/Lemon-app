import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:task_tracker/task_screens/taskTitleScreen.dart';
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
  late ScrollController _scrollController;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(initialScrollOffset: 0.0);
    _tabController = TabController(length: 2, vsync: this);
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
          backgroundImage: widget.employee.avatarUrl != ''
              ? NetworkImage(
            widget._employeeService
                .getAvatarUrl(widget.employee.avatarUrl),
          )
              : null,
          child: widget.employee.avatarUrl == ''
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
            color: isLink ? Colors.blue : Colors.black,
          ),
        ),
        SizedBox(height: 13),
      ],
    );
  }

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

  Widget _buildS3StoresTasks() {

    final List<Map<String, dynamic>> tasks = [
      {
        'icon': Iconsax.archive_tick_copy,
        'title': 'В работе',
        'count': 12,
      },
      {
        'icon': Iconsax.timer_copy,
        'title': 'Подходит время сдачи',
        'count': 5,
      },
      {
        'icon': Iconsax.calendar_remove_copy,
        'title': 'Просроченные задачи',
        'count': 2,
      },
      {
        'icon': Iconsax.task_square_copy,
        'title': 'Поставить в очередь на выполнение',
        'count': 0,
      },
      {
        'icon': Iconsax.eye_copy,
        'title': 'Не прочитал / не понял',
        'count': 8,
      },
      {
        'icon': Iconsax.search_normal_copy,
        'title': 'Завершенные задачи на проверке',
        'count': 3,
      },
      {
        'icon': Iconsax.microscope_copy,
        'title': 'Наблюдатель',
        'count': 1,
      },
      {
        'icon': Iconsax.folder_open_copy,
        'title': 'Архив задач',
        'count': 15,
      },
    ];

    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return _buildTaskItem(
          icon: task['icon'],
          title: task['title'],
          count: task['count'],
        );
      },
    );
  }

  Widget _buildPRTTasks() {
    return ListView(
      padding: EdgeInsets.zero,
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
      body: Stack(
        children: [
          NestedScrollView(
            floatHeaderSlivers: true,
            headerSliverBuilder: (BuildContext context, bool boxIsScrolled) {
              return <Widget>[
                SliverAppBar(
                  pinned: true,
                  floating: true,
                  forceElevated: boxIsScrolled,
                  backgroundColor: Colors.white,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(widget.employee.name.split(' ').take(2).join(' ')),
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
                        _buildBorders(context),
                        _buildProfileSection('Должность', widget.employee.position),
                        _buildBorders(context),
                        _buildProfileSection('Контактный телефон', widget.employee.phone ?? ''),
                        _buildBorders(context),
                        _buildProfileSection('Имя пользователя в Телеграм', widget.employee.telegramId ?? ''),
                        _buildBorders(context),
                        _buildProfileSection('Адрес страницы в VK', widget.employee.vkId ?? ''),
                      ],
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      controller: _tabController,
                      labelColor: Color(0xFF6750A4),
                      indicatorColor: Color(0xFF6750A4),
                      tabs: const [
                        Tab(text: 'S3 Stores Inc'),
                        Tab(text: 'PRT'),
                      ],
                    ),
                  ),
                  pinned: true,
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: <Widget>[
                _buildS3StoresTasks(),
                _buildPRTTasks(),
              ],
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
                    builder: (context) => TaskTitleScreen(employee: widget.employee),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFF9700), // Цвет кнопки
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_circle,
                    color: Colors.white, // Цвет иконки
                    size: 24, // Размер иконки
                  ),
                  SizedBox(width: 8), // Отступ между иконкой и текстом
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
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
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