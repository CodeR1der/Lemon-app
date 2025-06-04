import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/employee.dart';

class UserService extends GetxService {
  static UserService get to => Get.find();
  final SupabaseClient _supabase;
  final Rx<Employee?> _currentUser = Rx<Employee?>(null);
  late RxBool isInitialized;
  late RxBool isLoggedIn;
  final Map<String, String> _userNamesCache = {}; // Кэш для имен пользователей
  final Map<String, Map<String, String?>> _userDataCache = {}; // Кэш для данных пользователя
  UserService(this._supabase) {
    isInitialized = false.obs;
    isLoggedIn = false.obs;
    _updateAuthState();
  }

  Employee? get currentUser => _currentUser.value;

  Future<void> _updateAuthState() async {
    try {
      isInitialized.value = false;
      if (_supabase.auth.currentSession != null) {
        await initializeUser(_supabase.auth.currentSession!.user.id);
      }
    } catch (error) {
      Get.snackbar('Ошибка', 'Не удалось проверить статус авторизации: $error');
      _currentUser.value = null;
    } finally {
      isInitialized.value = true;
    }
    isLoggedIn.value = _currentUser.value != null;
  }

  // Генерация уникального 6-значного кода
  Future<String> _generateUniqueCode() async {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();

    while (true) {
      final code = String.fromCharCodes(
        Iterable.generate(
            6, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
      );
      final exists = await _supabase
          .from('company')
          .select('code')
          .eq('code', code)
          .maybeSingle();
      if (exists == null) return code;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    String? name,
    String? position,
    String? role,
    String? code,
    String? phone,
  }) async {
    try {
      isInitialized.value = false;

      String? companyId;

      if (role != 'Директор' && role != 'Исполнитель / Постановщик') {
        throw Exception('Недопустимая роль: $role');
      }

      if (role == 'Директор') {
        final companyCode = await _generateUniqueCode();
        final companyResponse = await _supabase
            .from('company')
            .insert({
          'code': companyCode,
        })
            .select('id')
            .single();
        companyId = companyResponse['id'];
      } else if (role == 'Исполнитель / Постановщик') {
        if (code == null || !RegExp(r'^[A-Z0-9]{6}$').hasMatch(code)) {
          throw Exception(
              'Код компании должен состоять из 6 заглавных букв или цифр');
        }
        final company = await _supabase
            .from('company')
            .select('id')
            .eq('code', code.toUpperCase())
            .single();
        if (company.isEmpty) {
          throw Exception('Компания с кодом $code не найдена');
        }
        companyId = company['id'];
      }

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'company_id': companyId, 'role': role},
      );

      if (response.user != null) {
        // Добавление пользователя в таблицу employee через RPC
        await _supabase.rpc('insert_employee', params: {
          'p_user_id': response.user!.id,
          'p_company_id': companyId,
          'p_name': name,
          'p_position': position,
          'p_role': role,
          'p_phone': '+7 $phone',
        });

        // Уведомление о необходимости подтвердить email
        Get.snackbar(
          'Успех',
          'Регистрация прошла успешно. Пожалуйста, подтвердите ваш email и войдите.',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        return true;
      }
      return false;
    } catch (e) {
      Get.snackbar('Ошибка', 'Регистрация не удалась: $e');
      return false;
    } finally {
      isInitialized.value = true;
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    try {
      isInitialized.value = false;
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user != null) {
        if (response.user!.emailConfirmedAt == null) {
          Get.snackbar(
            'Ошибка',
            'Пожалуйста, подтвердите ваш email перед входом.',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          await _supabase.auth.signOut();
          return false;
        }
        await initializeUser(response.user!.id);
        isLoggedIn.value = _currentUser.value != null;
        return true;
      }
      return false;
    } catch (e) {
      Get.snackbar('Ошибка', 'Вход не удался: $e');
      return false;
    } finally {
      isInitialized.value = true;
    }
  }

  Future<Map<String, String?>> getUserData(String userId) async {
    // Проверяем, есть ли данные в кэше
    if (_userDataCache.containsKey(userId)) {
      return _userDataCache[userId]!;
    }

    try {
      // Запрашиваем данные из таблицы employee
      final response = await Supabase.instance.client
          .from('employee')
          .select('name, avatar_url')
          .eq('user_id', userId)
          .single();

      if (response.isNotEmpty) {
        final name = response['name'] as String?;
        final avatarUrl = response['avatar_url'] as String?;
        final userData = {'name': name, 'avatar_url': avatarUrl};
        _userDataCache[userId] = userData; // Сохраняем в кэш
        return userData;
      }
      return {'name': null, 'avatar_url': null};
    } catch (e) {
      print('Error fetching user data for userId $userId: $e');
      return {'name': null, 'avatar_url': null};
    }
  }

  // Метод для получения имени пользователя по userId
  Future<String?> getUserName(String userId) async {
    // Проверяем, есть ли имя в кэше
    if (_userNamesCache.containsKey(userId)) {
      return _userNamesCache[userId];
    }

    try {
      // Запрашиваем данные из таблицы employee
      final response = await Supabase.instance.client
          .from('employee')
          .select('name')
          .eq('user_id', userId)
          .single();

      if (response.isNotEmpty) {
        final name = response['name'] as String?;
        if (name != null) {
          // Сохраняем в кэш
          _userNamesCache[userId] = name;
          return name;
        }
      }
      return null; // Если имя не найдено
    } catch (e) {
      print('Error fetching user name for userId $userId: $e');
      return null;
    }
  }
  Future<void> initializeUser(String userId) async {
    try {
      isInitialized.value = false;
      final userData = await _supabase
          .from('employee')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (userData == null) {
        Get.snackbar('Ошибка', 'Данные сотрудника не найдены для user_id: $userId');
        _currentUser.value = null;
        return;
      }

      _currentUser.value = Employee.fromJson(userData);
    } catch (error) {
      Get.snackbar('Ошибка', 'Не удалось инициализировать пользователя: $error');
      _currentUser.value = null;
    } finally {
      isInitialized.value = true;
      isLoggedIn.value = _currentUser.value != null;
      _supabase.auth.refreshSession();
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    _currentUser.value = null;
    isLoggedIn.value = false;
  }
}