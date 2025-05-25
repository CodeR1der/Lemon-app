import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:task_tracker/models/correction.dart';
import 'package:task_tracker/models/task_validate.dart';
import 'package:uuid/uuid.dart';

import '../models/task_status.dart';

class RequestService {
  final SupabaseClient _client = Supabase.instance.client;
  final _uuid = Uuid();

  Future<void> addTaskValidate(TaskValidate taskValidate) async {
    taskValidate.id = _uuid.v4();

    try {
      await _client.from('task_validate').insert(taskValidate.toJson());
      print('Запрос на проверку задачи успешно добавлена');
    } on PostgrestException catch (error) {
      print('Ошибка при добавлении запроса на проверку: ${error.message}');
    }
  }

  Future<TaskValidate?> getValidate(
      String task_id, TaskStatus status) async {
    try {
      final validateResponse =
      await _client.from('task_validate').select('*').eq('task_id', task_id);

      return validateResponse
          .map((data) => TaskValidate.fromJson(data)).first;
    } on PostgrestException catch (error) {
      print('Ошибка при получении корректировки: ${error.message}');
      return null;
    }
  }

  Future<void> updateValidate(TaskValidate validate) async {
    try {
      await _client
          .from('task_validate')
          .update({'is_done': validate.isDone}).eq('id', validate.id!);
      print('Корректировка успешно добавлена');
    } on PostgrestException catch (error) {
      print('Ошибка при добавлении корректировки: ${error.message}');
    }
  }

  String getValidateAttachment(String? fileName) {
    return _client.storage.from('ValidateAttachments').getPublicUrl(fileName!);
  }


  Future<void> addCorrection(Correction correction) async {
    correction.id = _uuid.v4();

    try {
      await _client.from('correction').insert(correction.toJson());
      print('Корректировка успешно добавлена');
    } on PostgrestException catch (error) {
      print('Ошибка при добавлении корректировки: ${error.message}');
    }
  }

  Future<List<Correction>> getCorrection(
      String task_id, TaskStatus status) async {
    try {
      final statusString = status.toString().substring(11);
      final correctionResponse =
          await _client.from('correction').select('*').eq('task_id', task_id);
      //.eq('status', statusString);

      return correctionResponse
          .map((data) => Correction.fromJson(data))
          .toList();
    } on PostgrestException catch (error) {
      print('Ошибка при получении корректировки: ${error.message}');
      return [];
    }
  }

  Future<void> updateCorrection(Correction correction) async {
    try {
      await _client
          .from('correction')
          .update({'is_done': correction.isDone}).eq('id', correction.id!);
      print('Корректировка успешно добавлена');
    } on PostgrestException catch (error) {
      print('Ошибка при добавлении корректировки: ${error.message}');
    }
  }

  Future<void> updateCorrectionByStatus(
      String task_id, TaskStatus status) async {
    try {
      final latestCorrection = await _client
          .from('correction')
          .select('date')
          .eq('task_id', task_id)
          .eq('status', status.toString().substring(11))
          .order('date', ascending: false)
          .limit(1)
          .single();

      final latestDate = DateTime.parse(latestCorrection['date'] as String);

      final response = await _client
          .from('correction')
          .update({'is_done': false})
          .eq('task_id', task_id)
          .eq('status', status.toString().substring(11))
          .eq('date', latestDate.toIso8601String());
    } on PostgrestException catch (error) {
      print('Ошибка при добавлении корректировки: ${error.message}');
    }
  }

  String getAttachment(String? fileName) {
    return _client.storage
        .from('CorrectionAttachments')
        .getPublicUrl(fileName!);
  }
}
