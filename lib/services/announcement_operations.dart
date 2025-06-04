import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/announcement.dart';

class AnnouncementService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _tableName = 'announcement';
  final _uuid = Uuid();

  // Создание нового объявления
  Future<void> createAnnouncement(Announcement announcement) async {
    if (announcement.id.isEmpty) {
      announcement.id = _uuid.v4();
    }
    try {
      await _supabase
          .from(_tableName)
          .insert(announcement.toJson());
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

  // Пометка объявления как прочитанного (static метод)
  static Future<void> markAsRead(String userId, Announcement announcement) async {
    try {
      if (announcement.readBy.contains(userId)) {
        return; // Уже прочитано
      }

      final updatedReadBy = [...announcement.readBy, userId];
      final supabase = Supabase.instance.client;

      final response = await supabase
          .from('announcement')
          .update({'read_by': updatedReadBy})
          .eq('id', announcement.id);

      if (response.error != null) {
        throw Exception('Ошибка обновления: ${response.error!.message}');
      }

      // Обновляем локальный объект
      announcement.readBy.add(userId);
    } catch (e) {
      throw Exception('Не удалось пометить объявление как прочитанное: $e');
    }
  }

  String getTaskAttachment(String? fileName) {
    return _supabase.storage.from('annoucementattachments').getPublicUrl(fileName!);
  }
  // Обновление объявления
  Future<void> updateAnnouncement(Announcement announcement) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .update(announcement.toJson())
          .eq('id', announcement.id);

      if (response.error != null) {
        throw Exception('Ошибка обновления объявления: ${response.error!.message}');
      }
    } catch (e) {
      throw Exception('Не удалось обновить объявление: $e');
    }
  }
}