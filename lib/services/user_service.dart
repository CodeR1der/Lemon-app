import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/employee.dart';

class UserService extends GetxService {
  static UserService get to => Get.find();
  final SupabaseClient _supabase;
  final Rx<Employee?> _currentUser = Rx<Employee?>(null);
  late RxBool isInitialized;
  late RxBool isLoggedIn;

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

  Future<bool> signUp({
    required String email,
    required String password,
    String? name,
    String? position,
    String? phone,
  }) async {
    try {
      isInitialized.value = false;
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      if (response.user != null) {
        await _supabase.from('employee').insert({
          'user_id': response.user!.id,
          'name': name,
          'position': position,
          'phone': phone,
        });
        await initializeUser(response.user!.id);
        isLoggedIn.value = _currentUser.value != null;
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

  Future<void> initializeUser(String userId) async {
    try {
      isInitialized.value = false;
      final currentUser = await _supabase
          .from('employee')
          .select()
          .eq('user_id', userId)
          .single();
      _currentUser.value = Employee.fromJson(currentUser);
    } catch (error) {
      print('Ошибка при инициализации пользователя: $error');
      _currentUser.value = null;
    } finally {
      isInitialized.value = true;
      isLoggedIn.value = _currentUser.value != null;
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    _currentUser.value = null;
    isLoggedIn.value = false;
  }
}