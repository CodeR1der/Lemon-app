import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task_tracker/models/employee.dart';
import 'package:task_tracker/services/employee_operations.dart';
import 'package:task_tracker/services/user_service.dart';

import '../models/announcement.dart';
import '../services/announcement_operations.dart';
import '../task_screens/TaskDescriptionTab.dart';

class AnnouncementDetailScreen extends StatefulWidget {
  final Announcement announcement;

  const AnnouncementDetailScreen({super.key, required this.announcement});

  @override
  State<AnnouncementDetailScreen> createState() => _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState extends State<AnnouncementDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Employee> _employees = [];
  bool _isLoadingEmployees = true;
  final AnnouncementService _database = AnnouncementService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadEmployees();
  }
  bool _isImage(String fileName) {
    return fileName.endsWith('.jpg') ||
        fileName.endsWith('.jpeg') ||
        fileName.endsWith('.png');
  }

  bool _isVideo(String fileName) {
    return fileName.endsWith('.mp4') || fileName.endsWith('.mov');
  }

  Future<void> _loadEmployees() async {
    try {
      final employees = await EmployeeService().getAllEmployees();
      setState(() {
        _employees = employees.where((e) => e.userId != UserService.to.currentUser!.userId).toList();
        _isLoadingEmployees = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingEmployees = false;
      });
      Get.snackbar('Ошибка', 'Не удалось загрузить сотрудников: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userRole = UserService.to.currentUser!.role;
    final showTabs = userRole == 'Директор';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: Text(widget.announcement.title),
        bottom: showTabs
            ? TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Текст объявления'),
            Tab(text: 'Прочитано'),
          ],
        )
            : null,
      ),
      body: showTabs
          ? TabBarView(
        controller: _tabController,
        children: [
          _buildAnnouncementTab(),
          _buildEmployeesTab(),
        ],
      )
          : _buildAnnouncementTab(),
    );
  }

  Widget _buildAnnouncementTab() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.announcement.fullText,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                Text(
                  'Дата: ${widget.announcement.date.toLocal().toString().split(' ')[0]}', // Обновлено с date на announcementDate
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 20),
                if (widget.announcement.attachments.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Фотографии
                      Text('Фотографии',
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Color(0xFFF9F9F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          widget.announcement.attachments.length.toString(),
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  widget.announcement.attachments.where((file) => _isImage(file)).isNotEmpty
                      ? GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 8.0,
                    ),
                    itemCount:
                    widget.announcement.attachments.where((file) => _isImage(file)).length,
                    itemBuilder: (context, index) {
                      final photo = widget.announcement.attachments
                          .where((file) => _isImage(file))
                          .toList()[index];
                      return GestureDetector(
                        onTap: () => _openPhotoGallery(
                          context,
                          index,
                          widget.announcement.attachments
                              .where((file) => _isImage(file))
                              .toList(),
                        ),
                        child: Hero(
                          tag: 'photo_$index',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Container(
                              color: Colors.white, // Белый фон для изображения
                              child: Image.network(
                                _database.getTaskAttachment(photo),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      color: Colors.grey.shade200,
                                      child:
                                      const Icon(Icons.broken_image, size: 32),
                                    ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  )
                      : Text(''),
                ],

              ],
            ),
          ),
        ),
        if (UserService.to.currentUser!.role != 'Директор')
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity, // Кнопка на всю ширину
              child: ElevatedButton(
                onPressed: () {
                  // Отмечаем как прочитанное
                  AnnouncementService.markAsRead(
                      UserService.to.currentUser!.userId, widget.announcement);
                  Get.back();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Прочитал',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmployeesTab() {
    if (_isLoadingEmployees) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _employees.length,
      itemBuilder: (context, index) {
        final employee = _employees[index];
        final hasRead = widget.announcement.readBy.contains(employee.userId);

        return ListTile(
          leading: CircleAvatar(
            radius: 20,
            backgroundImage: employee.avatarUrl != null && employee.avatarUrl!.isNotEmpty
                ? NetworkImage(employee.avatarUrl!)
                : null,
            child: employee.avatarUrl == null || employee.avatarUrl!.isEmpty
                ? const Icon(Icons.person)
                : null,
          ),
          title: Text(employee.name),
          subtitle: Text(employee.position),
          trailing: Icon(
            hasRead ? Icons.check_circle : Icons.radio_button_unchecked,
            color: hasRead ? Colors.green : Colors.grey,
          ),
        );
      },
    );
  }
  void _openPhotoGallery(
      BuildContext context, int initialIndex, List<String> files) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoGalleryScreen(
          photos: files.map(_database.getTaskAttachment).toList(),
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  void _openVideoGallery(
      BuildContext context, int initialIndex, List<String> videoUrls) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoGalleryScreen(
          videoUrls: videoUrls.map(_database.getTaskAttachment).toList(),
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}

