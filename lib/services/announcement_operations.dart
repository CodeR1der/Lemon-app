import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/announcement.dart';
import '../services/user_service.dart';

class AnnouncementService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _tableName = 'announcement';
  static const String _logTableName = 'announcement_log';
  final _uuid = Uuid();

  // Создание нового объявления
  Future<void> createAnnouncement(Announcement announcement) async {
    if (announcement.id.isEmpty) {
      announcement.id = _uuid.v4();
    }
    try {
      await _supabase.from(_tableName).insert(announcement.toJson());
      print('Объявление успешно добавлено');
    } on PostgrestException catch (error) {
      print('Ошибка при добавлении объявления: ${error.message}');
    }
  }

  // Получение всех объявлений для компании
  Future<List<Announcement>> getAnnouncements(String companyId) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('company_id', companyId)
          .order('created_at', ascending: false);

      if (response.isEmpty) {
        return [];
      }

      return (response as List<dynamic>)
          .map((json) => Announcement.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Не удалось получить объявления: $e');
    }
  }

  // Получение логов для конкретного объявления
  Future<List<AnnouncementLog>> getAnnouncementLogs(
      String announcementId) async {
    try {
      final response = await _supabase
          .from(_logTableName)
          .select()
          .eq('announcement_id', announcementId)
          .order('timestamp', ascending: false);

      if (response.isEmpty) {
        return [];
      }

      return (response as List<dynamic>)
          .map((json) => AnnouncementLog.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Не удалось получить логи объявления: $e');
    }
  }

  // Пометка объявления как прочитанного (static метод)
  static Future<void> markAsRead(
      String userId, Announcement announcement) async {
    try {
      if (announcement.readBy.contains(userId)) {
        return; // Уже прочитано
      }

      final updatedReadBy = [...announcement.readBy, userId];
      final supabase = Supabase.instance.client;

      final response = await supabase
          .from('announcement')
          .update({'read_by': updatedReadBy}).eq('id', announcement.id);

      if (response.error != null) {
        throw Exception('Ошибка обновления: ${response.error!.message}');
      }

      // Обновляем локальный объект
      announcement.readBy.add(userId);

      // Получаем информацию о пользователе
      final currentUser = UserService.to.currentUser;
      if (currentUser != null) {
        // Добавляем лог
        await _addLogEntry(
            announcement.id,
            'read',
            userId,
            currentUser.name,
            currentUser.role,
            announcement.companyId
        );
      }
    } catch (e) {
      throw Exception('Не удалось пометить объявление как прочитанное: $e');
    }
  }

  // Пометка объявления как прочитанного для другого сотрудника (для коммуникаторов)
  static Future<void> markAsReadForEmployee(
      String targetUserId,
      String targetUserName,
      Announcement announcement,
      String currentUserId,
      String currentUserName,
      String currentUserRole,
      ) async {
    try {
      if (announcement.readBy.contains(targetUserId)) {
        return; // Уже прочитано
      }

      final updatedReadBy = [...announcement.readBy, targetUserId];
      final supabase = Supabase.instance.client;

      final response = await supabase
          .from('announcement')
          .update({'read_by': updatedReadBy}).eq('id', announcement.id);

      if (response.error != null) {
        throw Exception('Ошибка обновления: ${response.error!.message}');
      }

      // Обновляем локальный объект
      announcement.readBy.add(targetUserId);

      // Добавляем лог
      await _addLogEntry(
        announcement.id,
        'marked_read',
        currentUserId,
        currentUserName,
        currentUserRole,
        announcement.companyId,
        targetUserId: targetUserId,
        targetUserName: targetUserName,
      );
    } catch (e) {
      throw Exception('Не удалось пометить объявление как прочитанное: $e');
    }
  }

  // Закрытие объявления
  static Future<void> closeAnnouncement(
      Announcement announcement,
      String currentUserId,
      String currentUserName,
      String currentUserRole,
      ) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from('announcement')
          .update({'status': 'closed'}).eq('id', announcement.id);

      // Обновляем локальный объект
      announcement.status = 'closed';

      // Добавляем лог
      await _addLogEntry(announcement.id, 'closed', currentUserId,
          currentUserName, currentUserRole, announcement.companyId);
    } catch (e) {
      throw Exception('Не удалось закрыть объявление: $e');
    }
  }

  // Добавление лога действия в отдельную таблицу
  static Future<void> _addLogEntry(
      String announcementId,
      String action,
      String userId,
      String userName,
      String userRole,
      String companyId, {
        String? targetUserId,
        String? targetUserName,
      }) async {
    try {
      final newLog = AnnouncementLog(
        id: const Uuid().v4(),
        action: action,
        userId: userId,
        userName: userName,
        userRole: userRole,
        timestamp: DateTime.now(),
        targetUserId: targetUserId,
        targetUserName: targetUserName,
        announcementId: announcementId,
        companyId: companyId,
      );

      final supabase = Supabase.instance.client;

      await supabase.from('announcement_log').insert(newLog.toJson());

    } catch (e) {
      throw Exception('Не удалось добавить лог: $e');
    }
  }

  // Добавление лога действия (публичный метод)
  static Future<void> addLog(
      String announcementId,
      String action,
      String currentUserId,
      String currentUserName,
      String currentUserRole,
      String companyId, {
        String? targetUserId,
        String? targetUserName,
      }) async {
    await _addLogEntry(
      announcementId,
      action,
      currentUserId,
      currentUserName,
      currentUserRole,
      companyId,
      targetUserId: targetUserId,
      targetUserName: targetUserName,
    );
  }

  String getTaskAttachment(String? fileName) {
    return _supabase.storage
        .from('annoucementattachments')
        .getPublicUrl(fileName!);
  }

  // Обновление объявления
  Future<void> updateAnnouncement(Announcement announcement) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .update(announcement.toJson())
          .eq('id', announcement.id);

      if (response.error != null) {
        throw Exception(
            'Ошибка обновления объявления: ${response.error!.message}');
      }
    } catch (e) {
      throw Exception('Не удалось обновить объявление: $e');
    }
  }
}