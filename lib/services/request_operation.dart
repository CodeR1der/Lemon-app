import 'dart:io';

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

    // Загружаем файлы в bucket
    if (taskValidate.attachments != null) {
      taskValidate.attachments = await _uploadFiles(taskValidate.attachments!, 'validateattachments');
    }
    if (taskValidate.videoMessage != null) {
      taskValidate.videoMessage = await _uploadFiles(taskValidate.videoMessage!, 'validateattachments');
    }
    if (taskValidate.audioMessage != null) {
      taskValidate.audioMessage = await _uploadFile(taskValidate.audioMessage!, 'validateattachments');
    }

    try {
      await _client.from('task_validate').insert(taskValidate.toJson());
      print('Запрос на проверку задачи успешно добавлен');
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

  Future<void> addCorrection(Correction correction) async {
    correction.id = _uuid.v4();

    // Загружаем файлы в bucket
    if (correction.attachments != null) {
      correction.attachments = await _uploadFiles(correction.attachments!, 'correctionattachments');
    }
    if (correction.audioMessage != null) {
      correction.audioMessage = await _uploadFile(correction.audioMessage!, 'correctionattachments');
    }
    if (correction.videoMessage != null) {
      correction.videoMessage = await _uploadFiles(correction.videoMessage!, 'correctionattachments');
    }

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

  // Вспомогательный метод для загрузки одного файла
  Future<String> _uploadFile(String filePath, String bucketName) async {
    final file = File(filePath);
    final fileName = '${_uuid.v4()}_${file.uri.pathSegments.last}';
    try {
      await _client.storage.from(bucketName).upload(
        fileName,
        file,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );
      return fileName; // Возвращаем имя файла в bucket
    } catch (e) {
      print('Ошибка загрузки файла: $e');
      rethrow;
    }
  }

  // Вспомогательный метод для загрузки списка файлов
  Future<List<String>> _uploadFiles(List<String> filePaths, String bucketName) async {
    final uploadedFiles = <String>[];
    for (final filePath in filePaths) {
      final fileName = await _uploadFile(filePath, bucketName);
      uploadedFiles.add(fileName);
    }
    return uploadedFiles;
  }

  String getValidateAttachment(String? fileName) {
    if (fileName == null) return '';
    return _client.storage.from('validateattachments').getPublicUrl(fileName);
  }

  String getAttachment(String? fileName) {
    if (fileName == null) return '';
    return _client.storage.from('correctionattachments').getPublicUrl(fileName);
  }
}
