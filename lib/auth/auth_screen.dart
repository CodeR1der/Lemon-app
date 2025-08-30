import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:task_tracker/widgets/common/app_common.dart';

import '../services/user_service.dart';
import '../widgets/navigation_panel.dart';
import 'auth_service.dart';
import 'otp_verification_screen.dart';

class AuthScreen extends StatefulWidget {
  final SupabaseClient supabase;
  bool isSignUp = true;
  bool? isEmployee = false;
  String? companyCode;

  AuthScreen({
    required this.supabase,
    required this.isSignUp,
    this.isEmployee,
    this.companyCode,
    super.key,
  });

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _lastNameController = TextEditingController(); // Фамилия
  final _firstNameController = TextEditingController(); // Имя
  final _middleNameController = TextEditingController(); // Отчество
  final _positionController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isOtpSent = false;
  bool _isLoading = false; // загрузка данных в бд
  bool _isButtonEnabled = false; // все ли поля заполнены

  @override
  void initState() {
    super.initState();
    _lastNameController.addListener(_updateButtonState);
    _firstNameController.addListener(_updateButtonState);
    _middleNameController.addListener(_updateButtonState);
    _positionController.addListener(_updateButtonState);
    _phoneController.addListener(_updateButtonState);
  }

  @override
  void dispose() {
    _lastNameController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _positionController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _updateButtonState() {
    setState(() {
      if (widget.isSignUp) {
        _isButtonEnabled = _lastNameController.text.isNotEmpty &&
            _firstNameController.text.isNotEmpty &&
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
      if (await AuthService().isPhoneExist(_phoneController.text, false) ==
          false) {
        throw ArgumentError('Данный номер уже зарегистрирован!');
      }

      AuthService().sendOtp(_phoneController.text);

      // Показываем экран ввода OTP
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            phone: _phoneController.text,
            onVerified: (phone) async {
              final role = widget.isEmployee == true
                  ? 'Исполнитель / Постановщик'
                  : 'Директор';
              final position = widget.isEmployee == true
                  ? _positionController.text
                  : 'Директор';

              // Переходим к экрану завершения регистрации
              UserService.to.signUp(
                email: 'lemon_${phone.replaceAll(RegExp(r'[-\s]'), '')}@lemon.ru',
                password: 'lemon_app',
                firstName: _firstNameController.text,
                lastName: _lastNameController.text,
                middleName: _middleNameController.text.isNotEmpty
                    ? _middleNameController.text
                    : null,
                phone: _phoneController.text,
                role: role,
                code: widget.companyCode,
                position: position,
              );

              Get.offAll(() => const BottomNavigationMenu());
            },
          ),
        ),
      );
    } on ArgumentError catch (e) {
      Get.snackbar('Ошибка!', e.message);
    } catch (e) {
      Get.snackbar('Ошибка!', 'Ошибка при отправке смс-кода');
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

    try {
      if (await AuthService().isPhoneExist(_phoneController.text, true) ==
          false) {
        throw ArgumentError('Аккаунт не зарегистрирован!');
      }

      // Отправляем OTP для входа
      await AuthService().sendOtp(_phoneController.text);

      // Показываем экран ввода OTP для входа
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            phone: _phoneController.text,
            onVerified: (phone) async {
              UserService.to.signIn(
                email: 'lemon_${phone.replaceAll(RegExp(r'[-\s]'), '')}@lemon.ru',
                password: 'lemon_app',
              );

              Get.offAll(() => const BottomNavigationMenu());
            },
          ),
        ),
      );
    } on ArgumentError catch (e) {
      Get.snackbar('Ошибка!', e.message);
    } catch (e) {
      Get.snackbar('Ошибка!', 'Ошибка при отправке смс-кода');
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isSignUp ? 'Регистрация' : 'Вход'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                widget.isSignUp = !widget.isSignUp;
                _updateButtonState();
              });
            },
            child: Text(widget.isSignUp ? 'Войти' : 'Регистрация'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: widget.isSignUp
              ? _buildRegistrationScreen()
              : _buildLoginScreen(),
        ),
      ),
    );
  }

  Widget _buildRegistrationScreen() {
    return Column(
      children: [
        AppSpacing.height24,
        _buildRegistrationSection('Фамилия', _lastNameController),
        AppSpacing.height16,
        _buildRegistrationSection('Имя', _firstNameController),
        AppSpacing.height16,
        _buildRegistrationSection('Отчество', _middleNameController,
            isOptional: true),
        if (widget.isEmployee == true) ...[
          AppSpacing.height16,
          _buildRegistrationSection('Должность', _positionController),
        ],
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
        AppSpacing.height24,
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
        bool isOptional = false,
        bool obscureText = false,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.titleSmall),
        const SizedBox(height: 6),
        SizedBox(
          height: 44,
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            style: AppTextStyles.bodySmall,
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
              if (!isOptional) {
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
        const Text(
          'Телефон',
          style: AppTextStyles.titleSmall,
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 44,
          child: TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              prefixText: '+7 ',
              prefixStyle: AppTextStyles.bodySmall,
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
              hintStyle: AppTextStyles.titleSmall,
            ),
            style: AppTextStyles.bodySmall,
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