import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/user_service.dart';
import '../widgets/common/app_buttons.dart';
import '../widgets/common/app_spacing.dart';
import '../widgets/navigation_panel.dart';
import 'auth_service.dart';
import 'otp_verification_screen.dart';

class AuthScreen extends StatefulWidget {
  final SupabaseClient supabase;

  const AuthScreen({required this.supabase, super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _surnameController = TextEditingController();
  final _nameController = TextEditingController();
  final _patronymicController = TextEditingController();
  final _positionController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isOtpSent = false;
  bool _isSignUp = true; // зарегистрироваться либо авторизоваться
  bool _isLoading = false; // загрузка данных в бд
  bool _isButtonEnabled = false; // все ли поля заполнены

  @override
  void initState() {
    super.initState();
    _surnameController.addListener(_updateButtonState);
    _patronymicController.addListener(_updateButtonState);
    _nameController.addListener(_updateButtonState);
    _positionController.addListener(_updateButtonState);
    _phoneController.addListener(_updateButtonState);
  }

  @override
  void dispose() {
    _surnameController.dispose();
    _patronymicController.dispose();
    _nameController.dispose();
    _positionController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _updateButtonState() {
    setState(() {
      if (_isSignUp) {
        _isButtonEnabled = _surnameController.text.isNotEmpty &&
            _nameController.text.isNotEmpty &&
            //_patronymicController.text.isNotEmpty &&
            _phoneController.text.isNotEmpty;
      } else {
        _isButtonEnabled = _phoneController.text.isNotEmpty;
      }
    });
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      AuthService().sendOtp(_phoneController.text);

      // Показываем экран ввода OTP
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            phone: _phoneController.text,
            onVerified: (phone) async {
              // Переходим к экрану завершения регистрации
              UserService.to.signUp(
                  email: 'lemon_${phone.replaceAll(RegExp(r'[-\s]'), '')}@lemon.ru',
                  password: 'lemon_app',
                  name: _nameController.text,
                  phone: _phoneController.text,
                  role: 'Директор',
                  position: 'Директор');

              Navigator.of(context).pop();
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => BottomNavigationMenu()));
            },
          ),
        ),
      );
    } catch (e) {
      Get.snackbar('Ошибка!', 'Ошибка при отправке смс-кода');
      return;
    }

    setState(() {
      _isLoading = false;
    });
    return;
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Отправляем OTP для входа
    await AuthService().sendOtp(_phoneController.text);

    // Показываем экран ввода OTP для входа
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OtpVerificationScreen(
          phone: _phoneController.text,
          onVerified: (phone) async {
            UserService.to.signIn(email: 'lemon_${phone.replaceAll(RegExp(r'[-\s]'), '')}@lemon.ru', password: 'lemon_app');

            Navigator.of(context).pop();

            // Переходим к экрану ввода кода для входа
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => BottomNavigationMenu(),
              ),
            );
          },
        ),
      ),
    );

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSignUp ? 'Регистрация' : 'Вход'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _isSignUp = !_isSignUp;
                _updateButtonState();
              });
            },
            child: Text(_isSignUp ? 'Войти' : 'Регистрация'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: _isSignUp ? _buildRegistrationScreen() : _buildLoginScreen(),
        ),
      ),
    );
  }

  Widget _buildRegistrationScreen() {
    return Column(
      children: [
        _buildRegistrationSection('Фамилия', _surnameController),
        AppSpacing.height16,
        _buildRegistrationSection(
          'Имя',
          _nameController,
        ),
        AppSpacing.height16,
        _buildRegistrationSection('Отчество', _patronymicController,
            isPatronymic: true),
        AppSpacing.height16,
        _buildPhoneField(),
        AppSpacing.height16,
        _isLoading
            ? const CircularProgressIndicator()
            : AppButtons.authButton(
                text: 'Зарегистрироваться',
                onPressed: _isButtonEnabled ? _handleAuth : () {},
                isLoading: false,
              ),
      ],
    );
  }

  Widget _buildLoginScreen() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Text(
          'Вход в приложение',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Введите номер телефона для получения кода',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 32),
        _buildPhoneField(),
        const SizedBox(height: 24),
        _isLoading
            ? const CircularProgressIndicator()
            : AppButtons.authButton(
                text: 'Получить код',
                onPressed: _isButtonEnabled ? _handleLogin : () {},
                isLoading: false,
              ),
      ],
    );
  }

  Widget _buildRegistrationSection(
    String title,
    TextEditingController controller, {
    bool isPatronymic = false,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        SizedBox(
          height: 44,
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            style: const TextStyle(
              fontSize: 18,
              fontFamily: 'Roboto',
              color: Colors.black,
            ),
            decoration: InputDecoration(
              isCollapsed: true,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[400]!, width: 1),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            ),
            validator: (value) {
              if (!isPatronymic) {
                if (value == null || value.isEmpty) {
                  return 'Пожалуйста, заполните поле';
                }
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Телефон',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 44,
          child: TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              prefixText: '+7 ',
              prefixStyle: const TextStyle(
                fontSize: 18,
                fontFamily: 'Roboto',
                color: Colors.black,
              ),
              isCollapsed: true,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[400]!, width: 1),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              hintText: 'XXX XXX-XX-XX',
              hintStyle: const TextStyle(
                fontSize: 18,
                fontFamily: 'Roboto',
                color: Colors.grey,
              ),
            ),
            style: const TextStyle(
              fontSize: 18,
              fontFamily: 'Roboto',
              color: Colors.black,
            ),
            onChanged: (value) {
              _updateButtonState();
            },
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
        ),
      ],
    );
  }
}
