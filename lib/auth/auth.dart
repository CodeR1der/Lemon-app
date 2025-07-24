import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/user_service.dart';
import '../widgets/navigation_panel.dart';

class AuthWrapper extends StatefulWidget {
  final Widget homeScreen;
  final SupabaseClient supabase;

  const AuthWrapper(
      {required this.homeScreen, required this.supabase, super.key});

  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final userService = UserService.to;
      if (widget.supabase.auth.currentSession != null &&
          !userService.isInitialized.value) {
        await userService
            .initializeUser(widget.supabase.auth.currentSession!.user.id);
      }
    } catch (error) {
      //Get.snackbar('Ошибка', 'Не удалось проверить статус авторизации: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final userService = UserService.to;
      if (!userService.isInitialized.value) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }
      return userService.isLoggedIn.value
          ? widget.homeScreen
          : AuthScreen(supabase: widget.supabase);
    });
  }
}

class AuthScreen extends StatefulWidget {
  final SupabaseClient supabase;

  const AuthScreen({required this.supabase, super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _positionController = TextEditingController();
  final _companyCodeController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isSignUp = false;
  bool _isLoading = false;
  bool _isButtonEnabled = false;
  String? _selectedRole; // 'director' или 'employee'
  bool _showRoleSelection = true; // Показывать ли выбор роли

  Widget _buildRoleSelection() {
    return Column(
      children: [
        const Text(
          'Выберите вашу роль',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 74),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.orange,
              width: 2,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            leading: const Icon(
              Iconsax.user,
              color: Colors.orange,
              size: 32,
            ),
            title: const Text(
              'Я директор',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              setState(() {
                _selectedRole = 'Директор';
                _showRoleSelection = false;
              });
            },
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.orange,
              width: 2,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            leading: const Icon(
              Iconsax.people,
              color: Colors.orange,
              size: 32,
            ),
            title: const Text(
              'Я сотрудник',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              setState(() {
                _selectedRole = 'Исполнитель / Постановщик';
                _showRoleSelection = false;
              });
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_updateButtonState);
    _passwordController.addListener(_updateButtonState);
    _nameController.addListener(_updateButtonState);
    _positionController.addListener(_updateButtonState);
    _phoneController.addListener(_updateButtonState);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _positionController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _updateButtonState() {
    setState(() {
      if (_isSignUp) {
        if (_selectedRole == 'Исполнитель / Постановщик') {
          _isButtonEnabled = _emailController.text.isNotEmpty &&
              _passwordController.text.isNotEmpty &&
              _nameController.text.isNotEmpty &&
              _positionController.text.isNotEmpty &&
              _phoneController.text.isNotEmpty &&
              _companyCodeController.text.isNotEmpty;
        } else {
          _isButtonEnabled = _emailController.text.isNotEmpty &&
              _passwordController.text.isNotEmpty &&
              _nameController.text.isNotEmpty &&
              _phoneController.text.isNotEmpty;
        }
      } else {
        _isButtonEnabled = _emailController.text.isNotEmpty &&
            _passwordController.text.isNotEmpty;
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

    final userService = UserService.to;
    bool success;

    if (_isSignUp) {
      success = await userService.signUp(
        email: _emailController.text,
        password: _passwordController.text,
        name: _nameController.text,
        position: _selectedRole == 'Директор'  ? 'Директор' : _positionController.text,
        role: _selectedRole,
        code: _selectedRole == 'Исполнитель / Постановщик' ? _companyCodeController.text : null,
        phone: _phoneController.text.isEmpty ? null : _phoneController.text,
      );
      if (success) {
        // Переключение на форму входа
        setState(() {
          _isSignUp = false;
          _selectedRole = null;
          _showRoleSelection = false;
          _nameController.clear();
          _positionController.clear();
          _companyCodeController.clear();
          _phoneController.clear();
        });
      }
      setState(() {
        _isLoading = false;
      });
      return;
    } else {
      success = await userService.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
    }

    if (success && userService.isLoggedIn.value) {
      Get.off(() => const BottomNavigationMenu());
    } else if (!_isSignUp) {
      Get.snackbar('Ошибка', 'Вход не удался');
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isSignUp ? 'Регистрация' : 'Вход')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (_isSignUp && _showRoleSelection) _buildRoleSelection(),
              if (!(_isSignUp && _showRoleSelection)) ...[
                _buildRegistrationSection('Email', _emailController),
                _buildRegistrationSection(
                  'Пароль',
                  _passwordController,
                  obscureText: true,
                ),
                if (_isSignUp) ...[
                  _buildRegistrationSection('Имя', _nameController),
                  if (_selectedRole == 'Исполнитель / Постановщик') ...[
                    _buildRegistrationSection('Должность', _positionController),
                    _buildRegistrationSection(
                        'Код для привязки к компании', _companyCodeController),
                  ],
                  _buildPhoneField(),
                ],
                const SizedBox(height: 20),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: _isButtonEnabled ? _handleAuth : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 8),
                      Text(
                        _isSignUp ? 'Зарегистрироваться' : 'Войти',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isSignUp = !_isSignUp;
                      _showRoleSelection = _isSignUp;
                      _selectedRole = null;
                      _updateButtonState();
                    });
                  },
                  child: Text(
                    _isSignUp
                        ? 'Уже есть аккаунт? Войти'
                        : 'Нет аккаунта? Зарегистрироваться',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (_isSignUp)
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _showRoleSelection = true;
                        _selectedRole = null;
                        _updateButtonState();
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.orange, width: 1),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 8),
                        Text(
                          'Изменить роль',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegistrationSection(
      String title,
      TextEditingController controller, {
        bool obscureText = false,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 13),
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
              if (value == null || value.isEmpty) {
                return 'Пожалуйста, заполните поле';
              }
              if (title == 'Email') {
                final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                if (!emailRegex.hasMatch(value)) {
                  return 'Введите действительный email';
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
        const SizedBox(height: 13),
        Text(
          'Номер телефона',
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