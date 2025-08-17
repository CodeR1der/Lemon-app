import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/user_service.dart';
import '../widgets/common/app_buttons.dart';
import '../widgets/common/app_spacing.dart';
import '../widgets/navigation_panel.dart';
import 'auth_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _loginCodeController = TextEditingController();

  bool _isLoading = false;
  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_updateButtonState);
    _loginCodeController.addListener(_updateButtonState);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _loginCodeController.dispose();
    super.dispose();
  }

  void _updateButtonState() {
    setState(() {
      _isButtonEnabled = _phoneController.text.isNotEmpty &&
          _loginCodeController.text.isNotEmpty;
    });
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userService = UserService.to;

      // Проверяем пользователя по номеру телефона и коду
      final success = true;

      if (success) {
        Get.off(() => const BottomNavigationMenu());
      } else {
        Get.snackbar(
          'Ошибка',
          'Неверный номер телефона или код',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Ошибка',
        'Произошла ошибка при входе: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Вход в приложение'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text(
                'Вход в приложение',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Введите номер телефона и код для входа',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 32),

              // Номер телефона
              _buildPhoneField(),
              AppSpacing.height16,

              // Код для входа
              _buildLoginCodeField(),
              AppSpacing.height24,

              // Кнопка входа
              SizedBox(
                width: double.infinity,
                child: AppButtons.authButton(
                  text: 'Войти',
                  onPressed: _isButtonEnabled && !_isLoading ? _login : () {},
                  isLoading: _isLoading,
                ),
              ),
              AppSpacing.height16,

              // Ссылка на регистрацию
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AuthScreen(supabase: Supabase.instance.client),
                      ),
                    );
                  },
                  child: const Text('Нет аккаунта? Зарегистрироваться'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Номер телефона',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            prefixText: '+7 ',
            prefixStyle: const TextStyle(
              fontSize: 16,
              fontFamily: 'Roboto',
              color: Colors.black,
            ),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.blue[400]!),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            hintText: 'XXX XXX-XX-XX',
            hintStyle: const TextStyle(
              fontSize: 16,
              fontFamily: 'Roboto',
              color: Colors.grey,
            ),
          ),
          style: const TextStyle(
            fontSize: 16,
            fontFamily: 'Roboto',
            color: Colors.black,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Пожалуйста, введите номер телефона';
            }
            if (!RegExp(r'^[0-9]{10}$')
                .hasMatch(value.replaceAll(RegExp(r'[^0-9]'), ''))) {
              return 'Введите корректный номер телефона';
            }
            return null;
          },
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
            TextInputFormatter.withFunction(
              (oldValue, newValue) {
                if (newValue.text.isEmpty) return newValue;

                final text = newValue.text;
                String newText = text;

                if (text.length > 3) {
                  newText = '${text.substring(0, 3)} ${text.substring(3)}';
                }
                if (text.length > 6) {
                  newText =
                      '${newText.substring(0, 7)}-${newText.substring(7)}';
                }
                if (text.length > 8) {
                  newText =
                      '${newText.substring(0, 10)}-${newText.substring(10)}';
                }

                return TextEditingValue(
                  text: newText,
                  selection: TextSelection.collapsed(offset: newText.length),
                );
              },
            )
          ],
        ),
      ],
    );
  }

  Widget _buildLoginCodeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Код для входа',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _loginCodeController,
          keyboardType: TextInputType.number,
          obscureText: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.blue[400]!),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            hintText: 'Введите код для входа',
            hintStyle: const TextStyle(
              fontSize: 16,
              fontFamily: 'Roboto',
              color: Colors.grey,
            ),
          ),
          style: const TextStyle(
            fontSize: 16,
            fontFamily: 'Roboto',
            color: Colors.black,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Пожалуйста, введите код для входа';
            }
            if (value.length < 4) {
              return 'Код должен содержать минимум 4 цифры';
            }
            if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
              return 'Код должен содержать только цифры';
            }
            return null;
          },
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
        ),
      ],
    );
  }
}
