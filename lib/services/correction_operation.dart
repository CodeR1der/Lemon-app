import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:task_tracker/models/correction.dart';
import 'package:uuid/uuid.dart';

import '../models/task_status.dart';

class CorrectionService {
  final SupabaseClient _client = Supabase.instance.client;
  final _uuid = Uuid();

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
      await _client
          .from('correction')
          .update({'is_done': false})
          .eq('task_id', task_id)
          .eq('status', status.toString().substring(11));
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
