// services/user_service.dart
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/employee.dart';

class UserService extends GetxService {
  static UserService get to => Get.find();

  final Rx<Employee?> _currentUser = Rx<Employee?>(null);

  Employee? get currentUser => _currentUser.value;
  bool get isLoggedIn => _currentUser.value != null;

  Future<void> initializeUser(String userId) async {
    try {
      final currentUser = await Supabase.instance.client
          .from('employee')
          .select()
          .eq('user_id', userId)
          .single();

      if (currentUser != null) {
        _currentUser.value = Employee.fromJson(currentUser);
      } else {
        print('Пользователь с ID $userId не найден');
      }
    } on PostgrestException catch (error) {
      print('Ошибка при получении данных сотрудника: ${error.message}');
    }
  }

  void logout() {
    _currentUser.value = null;
  }
}