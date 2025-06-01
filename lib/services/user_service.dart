import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/employee.dart';

class UserService extends GetxService {
  static UserService get to => Get.find();

  final SupabaseClient _supabase;
  final Rx<Employee?> _currentUser = Rx<Employee?>(null);
  final RxBool _isInitialized = RxBool(false); // Новый флаг инициализации

  UserService(this._supabase);

  Employee? get currentUser => _currentUser.value;

  bool get isLoggedIn => _currentUser.value != null;

  bool get isInitialized => _isInitialized.value;

  @override
  void onInit() {
    super.onInit();
    _supabase.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session != null) {
        await initializeUser(session.user.id);
      } else {
        _currentUser.value = null;
        _isInitialized.value =
            true; // Инициализация завершена, даже если пользователь не авторизован
      }
    });
  }

  Future<void> initializeUser(String userId) async {
    try {
      _isInitialized.value = false; // Сбрасываем флаг перед началом
      final currentUser = await _supabase
          .from('employee')
          .select()
          .eq('user_id', userId)
          .single();

      _currentUser.value = Employee.fromJson(currentUser);
    } on PostgrestException catch (error) {
      print('Ошибка при получении данных сотрудника: ${error.message}');
      _currentUser.value = null;
    } catch (error) {
      print('Неизвестная ошибка при инициализации пользователя: $error');
      _currentUser.value = null;
    } finally {
      _isInitialized.value = true; // Инициализация завершена
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required String position,
    String? role,
    String? avatarUrl,
    String? phone,
    String? telegramId,
    String? vkId,
  }) async {
    try {
      if (name.isEmpty ||
          position.isEmpty ) {
        Get.snackbar('Ошибка', 'Заполните все обязательные поля');
        return false;
      }

      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password.trim(),
      );

      if (response.user != null) {
        final existingEmployee = await _supabase
            .from('employee')
            .select()
            .eq('user_id', response.user!.id)
            .maybeSingle();

        if (existingEmployee != null) {
          Get.snackbar(
              'Ошибка', 'Пользователь уже зарегистрирован в таблице employee');
          await _supabase.auth.signOut();
          return false;
        }

        await _supabase.from('employee').insert({
          'user_id': response.user!.id,
          'name': name.trim(),
          'position': position.trim(),
          'phone': phone?.trim(),

        });

        await initializeUser(response.user!.id);
        Get.snackbar('Успех', 'Регистрация успешна! Проверьте email.');
        return true;
      }
      return false;
    } on AuthException catch (error) {
      Get.snackbar('Ошибка авторизации', error.message);
      return false;
    } on PostgrestException catch (error) {
      Get.snackbar('Ошибка базы данных', error.message);
      return false;
    } catch (error) {
      Get.snackbar('Ошибка', 'Неизвестная ошибка: $error');
      return false;
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (response.user != null) {
        final employee = await _supabase
            .from('employee')
            .select()
            .eq('user_id', response.user!.id)
            .maybeSingle();

        if (employee == null) {
          Get.snackbar(
              'Ошибка', 'Данные сотрудника не найдены. Зарегистрируйтесь.');
          await _supabase.auth.signOut();
          return false;
        }

        await initializeUser(response.user!.id);
        return true;
      }
      return false;
    } on AuthException catch (error) {
      Get.snackbar('Ошибка авторизации', error.message);
      return false;
    } catch (error) {
      Get.snackbar('Ошибка', 'Неизвестная ошибка: $error');
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
      _currentUser.value = null;
      _isInitialized.value = true;
      Get.snackbar('Успех', 'Выход выполнен');
    } catch (error) {
      Get.snackbar('Ошибка', 'Ошибка при выходе: $error');
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email.trim());
      Get.snackbar('Успех', 'Письмо для сброса пароля отправлено');
      return true;
    } catch (error) {
      Get.snackbar('Ошибка', 'Ошибка при сбросе пароля: $error');
      return false;
    }
  }
}
