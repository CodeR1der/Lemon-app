import 'dart:io';
import 'package:path/path.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '/models/employee.dart';

class EmployeeService {
  final SupabaseClient _client = Supabase.instance.client;
  final _uuid = Uuid();


  // Добавление сотрудника в Supabase
  Future<void> addEmployee(Employee employee) async {
    if (employee.userId.isEmpty) {
      employee.userId = _uuid.v4();
    }

    try {
      await _client.from('employees').insert(employee.toJson());
      print('Сотрудник успешно добавлен');
    } on PostgrestException catch (error) {
      print('Ошибка при добавлении сотрудника: ${error.message}');
    }
  }

  // Получение списка всех сотрудников
  Future<List<Employee>> getAllEmployees() async {
    try {
      final response = await _client.from('employees').select();
      List<Employee> employeeList = (response as List<dynamic>).map((data) {
        return Employee.fromJson(data as Map<String, dynamic>);
      }).toList();
      return employeeList;
    } on PostgrestException catch (error) {
      print('Ошибка при получении списка сотрудников: ${error.message}');
      return [];
    }
  }

  // Получение данных сотрудника по userId
  Future<Employee?> getEmployee(String userId) async {
    try {
      final response = await _client
          .from('employees')
          .select()
          .eq('userId', userId)
          .single() as Map<String, dynamic>;
      return Employee.fromJson(response);
    } on PostgrestException catch (error) {
      print('Ошибка при получении данных сотрудника: ${error.message}');
      return null;
    }
  }

  // Обновление данных сотрудника
  Future<void> updateEmployee(Employee employee) async {
    try {
      await _client
          .from('employees')
          .update(employee.toJson())
          .eq('userId', employee.userId);
      print('Данные сотрудника успешно обновлены');
    } on PostgrestException catch (error) {
      print('Ошибка при обновлении данных сотрудника: ${error.message}');
    }
  }

  // Удаление сотрудника
  Future<void> deleteEmployee(String userId) async {
    try {
      await _client.from('employees').delete().eq('userId', userId);
      print('Сотрудник успешно удален');
    } on PostgrestException catch (error) {
      print('Ошибка при удалении сотрудника: ${error.message}');
    }
  }

  Future<String?> uploadAvatar(File imageFile, String userId) async {
    final fileName =
        '${userId}_${basename(imageFile.path)}'; // Уникальное имя файла
    try {
      await Supabase.instance.client.storage
          .from('avatars')
          .upload(fileName, imageFile);
      print("Аватарка успешно загружена");
      return fileName; // Возвращаем имя файла для сохранения в базе данных
    } on PostgrestException catch (error) {
      print("Ошибка загрузки аватарки: ${error!.message}");
    }
    print("Аватарка успешно загружена");
    return null;
  }

  // Удаление аватара сотрудника
  Future<void> deleteAvatar(String fileName) async {
    try {
      await _client.storage.from('avatars').remove([fileName]);
      print('Аватар успешно удален');
    } on PostgrestException catch (error) {
      print('Ошибка при удалении аватара: ${error.message}');
    }
  }

  // Получение публичного URL для аватара
  String getAvatarUrl(String? fileName) {
    return _client.storage.from('avatars').getPublicUrl(fileName!);
  }
}
