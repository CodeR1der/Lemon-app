import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/control_point.dart';

class ControlPointService {
  final SupabaseClient _client = Supabase.instance.client;
  final _uuid = Uuid();

  // Добавление контрольной точки
  Future<void> addControlPoint(ControlPoint controlPoint) async {
    if (controlPoint.id == null || controlPoint.id!.isEmpty) {
      controlPoint.id = _uuid.v4();
    }

    // Устанавливаем время создания, если не задано
    if (controlPoint.createdAt == null) {
      controlPoint.createdAt = DateTime.now();
    }

    try {
      await _client.from('control_points').insert(controlPoint.toJson());
      print('Контрольная точка успешно добавлена');
    } on PostgrestException catch (error) {
      print('Ошибка при добавлении контрольной точки: ${error.message}');
      throw Exception(
          'Ошибка при добавлении контрольной точки: ${error.message}');
    }
  }

  // Получение всех контрольных точек для задачи
  Future<List<ControlPoint>> getControlPointsForTask(String taskId) async {
    try {
      final response = await _client
          .from('control_points')
          .select('*')
          .eq('task_id', taskId)
          .order('date', ascending: true);

      return response.map((data) => ControlPoint.fromJson(data)).toList();
    } on PostgrestException catch (error) {
      print('Ошибка при получении контрольных точек: ${error.message}');
      return [];
    }
  }

  // Обновление контрольной точки
  Future<void> updateControlPoint(ControlPoint controlPoint) async {
    if (controlPoint.id == null) {
      throw Exception('ID контрольной точки не может быть null');
    }
    try {
      await _client
          .from('control_points')
          .update(controlPoint.toJson())
          .eq('id', controlPoint.id!);
      print('Контрольная точка успешно обновлена');
    } on PostgrestException catch (error) {
      print('Ошибка при обновлении контрольной точки: ${error.message}');
      throw Exception(
          'Ошибка при обновлении контрольной точки: ${error.message}');
    }
  }

  // Удаление контрольной точки
  Future<void> deleteControlPoint(String controlPointId) async {
    try {
      await _client.from('control_points').delete().eq('id', controlPointId);
      print('Контрольная точка успешно удалена');
    } on PostgrestException catch (error) {
      print('Ошибка при удалении контрольной точки: ${error.message}');
      throw Exception(
          'Ошибка при удалении контрольной точки: ${error.message}');
    }
  }

  // Отметка контрольной точки как выполненной
  Future<void> markControlPointAsCompleted(String controlPointId) async {
    try {
      await _client.from('control_points').update({
        'is_completed': true,
        'completed_at': DateTime.now().toIso8601String(),
      }).eq('id', controlPointId);
      print('Контрольная точка отмечена как выполненная');
    } on PostgrestException catch (error) {
      print('Ошибка при отметке контрольной точки: ${error.message}');
      throw Exception('Ошибка при отметке контрольной точки: ${error.message}');
    }
  }

  // Отметка контрольной точки как невыполненной
  Future<void> markControlPointAsIncomplete(String controlPointId) async {
    try {
      await _client.from('control_points').update({
        'is_completed': false,
        'completed_at': null,
      }).eq('id', controlPointId);
      print('Контрольная точка отмечена как невыполненная');
    } on PostgrestException catch (error) {
      print('Ошибка при отметке контрольной точки: ${error.message}');
      throw Exception('Ошибка при отметке контрольной точки: ${error.message}');
    }
  }

  // Получение статистики контрольных точек для задачи
  Future<Map<String, int>> getControlPointsStats(String taskId) async {
    try {
      final response = await _client
          .from('control_points')
          .select('is_completed')
          .eq('task_id', taskId);

      int total = response.length;
      int completed =
          response.where((point) => point['is_completed'] == true).length;
      int incomplete = total - completed;

      return {
        'total': total,
        'completed': completed,
        'incomplete': incomplete,
      };
    } on PostgrestException catch (error) {
      print(
          'Ошибка при получении статистики контрольных точек: ${error.message}');
      return {'total': 0, 'completed': 0, 'incomplete': 0};
    }
  }

  // Получение просроченных контрольных точек
  Future<List<ControlPoint>> getOverdueControlPoints(String taskId) async {
    try {
      final now = DateTime.now();
      final response = await _client
          .from('control_points')
          .select('*')
          .eq('task_id', taskId)
          .eq('is_completed', false)
          .lt('date', now.toIso8601String())
          .order('date', ascending: true);

      return response.map((data) => ControlPoint.fromJson(data)).toList();
    } on PostgrestException catch (error) {
      print(
          'Ошибка при получении просроченных контрольных точек: ${error.message}');
      return [];
    }
  }

  // Проверка наличия незакрытых контрольных точек для задачи
  Future<bool> hasUnclosedControlPoints(String taskId) async {
    try {
      print(
          'ControlPointService: Проверяем незакрытые контрольные точки для задачи: $taskId');
      final response = await _client
          .from('control_points')
          .select('id')
          .eq('task_id', taskId)
          .eq('is_completed', false)
          .limit(1);

      print(
          'ControlPointService: Найдено незакрытых контрольных точек: ${response.length}');
      return response.isNotEmpty;
    } on PostgrestException catch (error) {
      print(
          'Ошибка при проверке незакрытых контрольных точек: ${error.message}');
      return false;
    }
  }

  // Получение количества незакрытых контрольных точек для задачи
  Future<int> getUnclosedControlPointsCount(String taskId) async {
    try {
      final response = await _client
          .from('control_points')
          .select('id')
          .eq('task_id', taskId)
          .eq('is_completed', false);

      return response.length;
    } on PostgrestException catch (error) {
      print(
          'Ошибка при получении количества незакрытых контрольных точек: ${error.message}');
      return 0;
    }
  }
}
