// auth_service.dart
import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Генерация OTP (4 цифры)
  String _generateOtp() => (100000 + Random().nextInt(900000)).toString();

  // Отправка OTP на телефон
  Future<void> sendOtp(String phone) async {
    final otp = '000000'; //_generateOtp();
    final expiresAt =
        DateTime.now().add(Duration(minutes: 5)).toIso8601String();

    // Сохраняем OTP в Supabase
    await _supabase.from('users').upsert({
      'phone': phone,
      'otp_code': otp,
      'otp_expires_at': expiresAt,
      'otp_attempts': 0, // Счетчик попыток
    }, onConflict: 'phone');

    // 📤 Здесь будет интеграция с SMS-сервисом (Twilio и др.)
    print('OTP для $phone: $otp');
  }

  // Проверка OTP
  Future<bool> verifyOtp(String phone, String otp) async {
    final response = await _supabase
        .from('users')
        .select()
        .eq('phone', phone)
        .eq('otp_code', otp)
        .gt('otp_expires_at', DateTime.now().toIso8601String())
        .maybeSingle();

    if (response != null) {
      // Успешная проверка → очищаем OTP
      await _supabase.from('users').update({
        'otp_code': null,
        'otp_expires_at': null,
        'otp_attempts': 0,
        'is_verificated' : true,
      }).eq('phone', phone);

      return true;
    } else {
      // Увеличиваем счетчик неудачных попыток
      await _supabase
          .from('users')
          .update({'otp_attempts': 1})
          .eq('phone', phone)
          .select();
      return false;
    }
  }

  Future<bool> isOtpAttemptsExceeded(String phone) async {
    final response = await _supabase
        .from('users')
        .select('otp_attempts')
        .eq('phone', phone)
        .single();

    return (response['otp_attempts'] ?? 0) >= 3; // Лимит 3 попытки
  }

  Future<bool> isPhoneExist(String phone, bool isAuth) async {
    final response = await _supabase
        .from('users')
        .select('is_verificated')
        .eq('phone', phone)
        .maybeSingle();

    if (response == null) {
      if (!isAuth) {
        return true;
      }
      return false;
    }

    if ((response['is_verificated'] == true && isAuth) || (response['is_verificated'] == false && !isAuth)) {
      return true;
    }

    return false;
  }
}
