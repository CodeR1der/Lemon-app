import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:task_tracker/models/employee.dart';
import 'package:task_tracker/services/announcement_provider.dart';
import 'package:task_tracker/services/employee_operations.dart';
import 'package:task_tracker/services/user_service.dart';
import 'package:task_tracker/widgets/common/app_colors.dart';
import 'package:task_tracker/widgets/common/app_common.dart';

import '../../models/announcement.dart';
import '../../services/announcement_operations.dart';
import '../../task_screens/task_description_tab.dart';

class AnnouncementDetailScreen extends StatefulWidget {
  final Announcement announcement;

  const AnnouncementDetailScreen({super.key, required this.announcement});

  @override
  State<AnnouncementDetailScreen> createState() =>
      _AnnouncementDetailScreenState();
}

//
class _AnnouncementDetailScreenState extends State<AnnouncementDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Employee> _employees = [];
  List<AnnouncementLog> _logs = [];
  bool _isLoadingEmployees = true;
  bool _isLoadingLogs = true;
  final AnnouncementService _database = AnnouncementService();
  final currentUser = UserService.to.currentUser!;
  RealtimeChannel? _announcementChannel;
  late Announcement _currentAnnouncement;

  @override
  void initState() {
    super.initState();
    _currentAnnouncement = widget.announcement;
    _tabController = TabController(length: 3, vsync: this);
    _loadEmployees();
    _loadLogs();
    _setupRealtimeSubscription();
  }

  void _setupRealtimeSubscription() {
    final client = Supabase.instance.client;

    print(
        'AnnouncementDetailScreen: Настраиваем Realtime подписку для объявления: ${_currentAnnouncement.id}');

    _announcementChannel = client
        .channel('announcement_detail_${_currentAnnouncement.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'announcement',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: _currentAnnouncement.id,
          ),
          callback: (payload) {
            print(
                'AnnouncementDetailScreen: Получено изменение объявления: ${payload.eventType}');
            _handleAnnouncementChange(payload);
          },
        )
        .subscribe();
  }

  void _handleAnnouncementChange(PostgresChangePayload payload) {
    final eventType = payload.eventType.name;
    final newRecord = payload.newRecord;

    print('AnnouncementDetailScreen: Обработка изменения: $eventType');

    if (eventType == 'UPDATE' && newRecord != null) {
      try {
        // Обновляем данные объявления
        final updatedAnnouncement = Announcement.fromJson(newRecord);
        // Обновляем данные в виджете
        setState(() {
          // Обновляем _currentAnnouncement с новыми данными
          _currentAnnouncement = updatedAnnouncement;
        });
        print(
            'AnnouncementDetailScreen: Объявление обновлено: ${updatedAnnouncement.id}');
      } catch (e) {
        print('AnnouncementDetailScreen: Ошибка при обновлении объявления: $e');
      }
    } else if (eventType == 'DELETE') {
      // Если объявление удалено, возвращаемся назад
      Get.back();
    }
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
      // Получаем выбранных сотрудников из новой таблицы
      final selectedEmployeeIds = await AnnouncementService()
          .getSelectedEmployees(_currentAnnouncement.id);

      if (selectedEmployeeIds.isEmpty) {
        setState(() {
          _employees = [];
          _isLoadingEmployees = false;
        });
        return;
      }

      // Получаем информацию о сотрудниках
      final employees = await EmployeeService().getAllEmployees();
      setState(() {
        _employees = employees
            .where((e) => selectedEmployeeIds.contains(e.userId))
            .toList();
        _isLoadingEmployees = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingEmployees = false;
      });
      Get.snackbar('Ошибка', 'Не удалось загрузить сотрудников');
    }
  }

  Future<void> _loadLogs() async {
    try {
      final logs = await _database.getAnnouncementLogs(_currentAnnouncement.id);
      setState(() {
        _logs = logs;
        _isLoadingLogs = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingLogs = false;
      });
      Get.snackbar('Ошибка', 'Не удалось загрузить логи');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _announcementChannel?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userRole = UserService.to.currentUser!.role;
    final showTabs = userRole == 'Директор' || userRole == 'Коммуникатор';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        actions: [
          // Кнопка закрытия объявления для директоров и коммуникаторов
          if (showTabs && _currentAnnouncement.status == 'active')
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _closeAnnouncement,
              tooltip: 'Закрыть объявление',
            ),
        ],
        bottom: showTabs
            ? TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Текст объявления'),
                  Tab(text: 'Прочитано'),
                  Tab(text: 'Логи'),
                ],
              )
            : null,
      ),
      body: SafeArea(
        top: false,
        child: showTabs
            ? TabBarView(
                controller: _tabController,
                children: [
                  _buildAnnouncementTab(),
                  _buildEmployeesTab(),
                  _buildLogsTab(),
                ],
              )
            : _buildAnnouncementTab(),
      ),
    );
  }

  Widget _buildAnnouncementTab() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Статус объявления
                if (_currentAnnouncement.status == 'closed') ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.close, color: Colors.red.shade700, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Объявление закрыто',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  _currentAnnouncement.title,
                  style: AppTextStyles.titleAnnouncement,
                ),
                AppSpacing.height24,
                Text(
                  _currentAnnouncement.fullText,
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 20),
                Text(
                  'Дата: ${_currentAnnouncement.date.toLocal().toString().split(' ')[0]}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 20),
                if (_currentAnnouncement.attachments.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text('Фотографии', style: AppTextStyles.titleSmall),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F9F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _currentAnnouncement.attachments.length.toString(),
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
                  _currentAnnouncement.attachments
                          .where((file) => _isImage(file))
                          .isNotEmpty
                      ? GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8.0,
                            mainAxisSpacing: 8.0,
                          ),
                          itemCount: _currentAnnouncement.attachments
                              .where((file) => _isImage(file))
                              .length,
                          itemBuilder: (context, index) {
                            final photo = _currentAnnouncement.attachments
                                .where((file) => _isImage(file))
                                .toList()[index];
                            return GestureDetector(
                              onTap: () => _openPhotoGallery(
                                context,
                                index,
                                _currentAnnouncement.attachments
                                    .where((file) => _isImage(file))
                                    .toList(),
                              ),
                              child: Hero(
                                tag: 'photo_$index',
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Container(
                                    color: Colors.white,
                                    child: Image.network(
                                      _database.getTaskAttachment(photo),
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                        color: Colors.grey.shade200,
                                        child: const Icon(Icons.broken_image,
                                            size: 32),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                      : const Text(''),
                ],
              ],
            ),
          ),
        ),
        if (UserService.to.currentUser!.role != 'Директор' &&
            _currentAnnouncement.status == 'active')
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: AppButtons.primaryButton(
                onPressed: () async {
                  try {
                    await AnnouncementService.markAsRead(
                        UserService.to.currentUser!.userId,
                        _currentAnnouncement);
                    Get.snackbar(
                        'Успех', 'Объявление отмечено как прочитанное');
                    setState(() {}); // Обновляем UI
                  } catch (e) {}
                },
                text: 'Прочитал',
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

    final userRole = UserService.to.currentUser!.role;
    final canMarkAsRead =
        userRole == 'Коммуникатор' && widget.announcement.status == 'active';

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _employees.length,
      itemBuilder: (context, index) {
        final employee = _employees[index];
        final hasRead = _currentAnnouncement.readBy.contains(employee.userId);
        // Все сотрудники в _employees уже являются выбранными для этого объявления
        final isSelected = true;

        return AppCommonWidgets.employeeTile(
          employee: employee,
          context: context,
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(employee.position),
              if (!isSelected)
                Text(
                  'Не выбран для объявления',
                  style: TextStyle(
                    color: Colors.red.shade600,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (canMarkAsRead && !hasRead && isSelected) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.edit, size: 16),
                  onPressed: () => _markEmployeeAsRead(employee),
                  tooltip: 'Отметить как прочитанное',
                ),
              ],
              Icon(
                hasRead ? Icons.check_circle : Icons.radio_button_unchecked,
                color: hasRead ? Colors.green : Colors.grey,
              ),
            ],
          ),
          showNavigation: false,
        );
      },
    );
  }

  Widget _buildLogsTab() {
    if (_isLoadingLogs) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _logs.length,
      itemBuilder: (context, index) {
        final log = _logs[index];

        String actionText = '';
        IconData actionIcon = Icons.info;
        Color actionColor = Colors.blue;

        switch (log.action) {
          case 'created':
            actionText = 'Создал объявление';
            actionIcon = Icons.add;
            actionColor = Colors.green;
            break;
          case 'read':
            actionText = 'Прочитал объявление';
            actionIcon = Icons.check;
            actionColor = Colors.blue;
            break;
          case 'marked_read':
            actionText =
                'Отметил как прочитанное для ${log.targetUserName ?? 'сотрудника'}';
            actionIcon = Icons.edit;
            actionColor = Colors.orange;
            break;
          case 'closed':
            actionText = 'Закрыл объявление';
            actionIcon = Icons.close;
            actionColor = Colors.red;
            break;
        }

        return Card(
          color: AppColors.counterGrey,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: actionColor.withOpacity(0.1),
              child: Icon(actionIcon, color: actionColor, size: 20),
            ),
            title: Text(actionText),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${log.userName} (${log.userRole})'),
                Text(
                  '${log.timestamp.day}.${log.timestamp.month}.${log.timestamp.year} ${log.timestamp.hour}:${log.timestamp.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _markEmployeeAsRead(Employee employee) async {
    try {
      final currentUser = UserService.to.currentUser!;
      await AnnouncementService.markAsReadForEmployee(
        employee.userId,
        employee.name,
        _currentAnnouncement,
        currentUser.userId,
        currentUser.name,
        currentUser.role,
      );
      Get.snackbar('Успех', '${employee.name} отмечен как прочитавший');
      // UI обновится автоматически через Realtime
    } catch (e) {
      print('Ошибка Не удалось отметить как прочитанное: $e');
    }
  }

  Future<void> _closeAnnouncement() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Закрыть объявление'),
        content: const Text('Вы уверены, что хотите закрыть это объявление?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context, true);
              try {
                // Используем AnnouncementProvider для закрытия объявления
                final announcementProvider =
                    Provider.of<AnnouncementProvider>(context, listen: false);
                await announcementProvider
                    .closeAnnouncement(_currentAnnouncement);
                Get.snackbar('Успех', 'Объявление закрыто');
                // UI обновится автоматически через Realtime
              } catch (e) {
                print('Ошибка Не удалось закрыть объявление: $e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Закрыть', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
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
