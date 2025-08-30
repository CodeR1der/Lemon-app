import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:task_tracker/models/announcement.dart';
import 'package:task_tracker/services/announcement_operations.dart';
import 'package:task_tracker/services/user_service.dart';

class AnnouncementProvider with ChangeNotifier {
  final Map<String, Announcement> _announcements = {};
  String? _error;
  bool _isLoading = false;

  // Realtime подписки
  RealtimeChannel? _announcementChannel;
  String? _currentCompanyId;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Announcement? getAnnouncement(String announcementId) =>
      _announcements[announcementId];

  List<Announcement> getAnnouncements({String? companyId}) {
    if (companyId != null) {
      return _announcements.values
          .where((announcement) => announcement.companyId == companyId)
          .toList();
    }
    return _announcements.values.toList();
  }

  List<Announcement> getAnnouncementsForUser({
    required String companyId,
    required String userId,
    required String userRole,
  }) {
    final allAnnouncements = getAnnouncements(companyId: companyId);

    // Директоры и коммуникаторы видят все объявления
    if (userRole == 'Директор' || userRole == 'Коммуникатор') {
      return allAnnouncements;
    }

    // Обычные сотрудники видят только объявления, предназначенные для них
    return allAnnouncements
        .where(
            (announcement) => announcement.selectedEmployees.contains(userId))
        .toList();
  }

  Future<void> loadAnnouncements({required String companyId}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Загружаем объявления из базы данных
      final announcements =
          await AnnouncementService().getAnnouncements(companyId);

      // Обновляем локальный кэш
      _announcements.clear();
      for (var announcement in announcements) {
        _announcements[announcement.id] = announcement;
      }

      // Настраиваем Realtime подписки
      _setupRealtimeSubscriptions(companyId: companyId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _currentCompanyId = companyId;
      notifyListeners();
    }
  }

  // Методы для управления Realtime подписками
  void _setupRealtimeSubscriptions({String? companyId}) {
    // Отписываемся от предыдущих подписок
    disposeRealtimeSubscriptions();

    _currentCompanyId = companyId;

    if (companyId != null) {
      final client = Supabase.instance.client;

      // Подписываемся на изменения объявлений
      _announcementChannel = client
          .channel('announcements_$companyId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'announcement',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'company_id',
              value: companyId,
            ),
            callback: (payload) {
              print(
                  'AnnouncementProvider: Получено изменение объявления: $payload');
              _handleAnnouncementChange(payload);
            },
          )
          .subscribe();
    }
  }

  void disposeRealtimeSubscriptions() {
    _announcementChannel?.unsubscribe();
    _announcementChannel = null;
  }

  void _handleAnnouncementChange(PostgresChangePayload payload) {
    final eventType = payload.eventType.name;
    final record = payload.newRecord;
    final oldRecord = payload.oldRecord;

    print('AnnouncementProvider: Обработка изменения объявления: $eventType');

    switch (eventType) {
      case 'INSERT':
        if (record != null) {
          _addAnnouncement(record);
        }
        break;
      case 'UPDATE':
        if (record != null) {
          _updateAnnouncement(record);
        }
        break;
      case 'DELETE':
        if (oldRecord != null) {
          _removeAnnouncement(oldRecord['id'] as String);
        }
        break;
    }

    // Уведомляем слушателей
    notifyListeners();
  }

  void _addAnnouncement(Map<String, dynamic> announcementData) {
    try {
      final announcement = Announcement.fromJson(announcementData);
      _announcements[announcement.id] = announcement;
      print(
          'AnnouncementProvider: Добавлено новое объявление: ${announcement.id}');
    } catch (e) {
      print('AnnouncementProvider: Ошибка при добавлении объявления: $e');
    }
  }

  void _updateAnnouncement(Map<String, dynamic> announcementData) {
    try {
      final announcement = Announcement.fromJson(announcementData);
      _announcements[announcement.id] = announcement;
      print('AnnouncementProvider: Обновлено объявление: ${announcement.id}');
    } catch (e) {
      print('AnnouncementProvider: Ошибка при обновлении объявления: $e');
    }
  }

  void _removeAnnouncement(String announcementId) {
    _announcements.remove(announcementId);
    print('AnnouncementProvider: Удалено объявление: $announcementId');
  }

  Future<void> createAnnouncement(Announcement announcement) async {
    try {
      _isLoading = true;
      notifyListeners();

      await AnnouncementService().createAnnouncement(announcement);

      // Создаем лог создания объявления
      final currentUser = UserService.to.currentUser!;
      await AnnouncementService.addLog(
        announcement.id,
        'created',
        currentUser.userId,
        currentUser.fullName,
        currentUser.role,
        announcement.companyId,
      );

      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      loadAnnouncements(companyId: _currentCompanyId!);
      notifyListeners();
    }
  }

  Future<void> closeAnnouncement(Announcement announcement) async {
    try {
      _isLoading = true;
      notifyListeners();

      final currentUser = UserService.to.currentUser!;
      await AnnouncementService.closeAnnouncement(
        announcement,
        currentUser.userId,
        currentUser.fullName,
        currentUser.role,
      );

      // Обновляем локальное состояние
      if (_announcements.containsKey(announcement.id)) {
        final updatedAnnouncement = _announcements[announcement.id]!;
        updatedAnnouncement.status = 'closed';
        _announcements[announcement.id] = updatedAnnouncement;
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      loadAnnouncements(companyId: _currentCompanyId!);
      notifyListeners();
    }
  }

  Future<void> markAsRead(String userId, Announcement announcement) async {
    try {
      await AnnouncementService.markAsRead(userId, announcement);
      // Обновляем локальное состояние
      if (_announcements.containsKey(announcement.id)) {
        final updatedAnnouncement = _announcements[announcement.id]!;
        if (!updatedAnnouncement.readBy.contains(userId)) {
          updatedAnnouncement.readBy.add(userId);
          _announcements[announcement.id] = updatedAnnouncement;
          notifyListeners();
        }
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  @override
  void dispose() {
    disposeRealtimeSubscriptions();
    super.dispose();
  }
}
