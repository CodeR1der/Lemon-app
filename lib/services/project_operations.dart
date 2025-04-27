import 'dart:io';
import 'package:path/path.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/project_description.dart';
import '/models/project.dart';

class ProjectService {
  final SupabaseClient _client = Supabase.instance.client;
  final _uuid = Uuid();

  // Добавление проекта в Supabase
  Future<void> addProject(Project project) async {
    if (project.projectId.isEmpty) {
      project.projectId = _uuid.v4();
    }

    try {
      await _client.from('project').insert(project.toJson());
      print('Проект успешно добавлен');
    } on PostgrestException catch (error) {
      print('Ошибка при добавлении проекта: ${error.message}');
    }
  }

  // Получение списка всех проектов
  Future<List<Project>> getAllProjects() async {
    try {
      final response = await _client
          .from('project')
          .select('''
          project_id,
          name,
          avatar_url,
          observers:project_observers (  
            employee:employee_id (  
              user_id,
              avatar_url,
              name,
              position,
              phone,
              telegram_id,
              vk_id,
              role
            )
          )
        ''');

      List<Project> projectList = (response as List<dynamic>).map((data) {
        return Project.fromJson(data as Map<String, dynamic>);
      }).toList();
      return projectList;
    } on PostgrestException catch (error) {
      print('Ошибка при получении списка проектов: ${error.message}');
      return [];
    }
  }

  // Получение данных проекта по projectId
  Future<Project> getProject(String projectId) async {
      final response = await _client
          .from('project')
          .select()
          .eq('project_id', projectId)
          .single() as Map<String, dynamic>;
      return Project.fromJson(response);

  }

  // Получение данных описания проекта по projectId
  Future<Project_Description?> getProjectDescription(String projectId) async{
    try {
      final response = await _client
          .from('project_description')
          .select()
          .eq('project_id', projectId)
          .single() as Map<String, dynamic>;
      return Project_Description.fromJson(response);
    } on PostgrestException catch (error) {
      print('Ошибка при получении данных описания проекта: ${error.message}');
      return null;
    }
  }
  // Обновление данных проекта
  Future<void> updateProject(Project project) async {
    try {
      await _client
          .from('project')
          .update(project.toJson())
          .eq('project_id', project.projectId);
      print('Данные проекта успешно обновлены');
    } on PostgrestException catch (error) {
      print('Ошибка при обновлении данных проекта: ${error.message}');
    }
  }

  // Удаление проекта
  Future<void> deleteProject(String projectId) async {
    try {
      await _client.from('project').delete().eq('project_id', projectId);
      print('Проект успешно удален');
    } on PostgrestException catch (error) {
      print('Ошибка при удалении проекта: ${error.message}');
    }
  }

  // Загрузка аватара проекта
  Future<String?> uploadAvatar(File imageFile, String projectId) async {
    final String fileName =
        'projects/${projectId}_${basename(imageFile.path)}'; // Уникальное имя файла
    try {
      await _client.storage.from('Avatars').upload(fileName, imageFile);
      print("Аватар проекта успешно загружен");
      return fileName; // Возвращаем имя файла для сохранения в БД
    } on PostgrestException catch (error) {
      print("Ошибка загрузки аватарки проекта: ${error.message}");
    }
    return null;
  }

  // Удаление аватара проекта
  Future<void> deleteAvatar(String fileName) async {
    try {
      await _client.storage.from('Avatars').remove([fileName]);
      print('Аватар проекта успешно удален');
    } on PostgrestException catch (error) {
      print('Ошибка при удалении аватара проекта: ${error.message}');
    }
  }

  // Получение публичного URL для аватара проекта
  String getAvatarUrl(String? fileName) {
    return _client.storage.from('Avatars').getPublicUrl(fileName!);
  }


}
