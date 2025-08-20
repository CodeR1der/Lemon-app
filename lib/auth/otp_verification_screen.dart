// otp_verification_screen.dart
import 'package:flutter/material.dart';
import 'package:otp_pin_field/otp_pin_field.dart';
import 'package:task_tracker/auth/auth_service.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phone;
  final Function(String) onVerified;

  const OtpVerificationScreen({
    required this.phone,
    required this.onVerified,
    super.key,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpPinFieldController = GlobalKey<OtpPinFieldState>();
  late String _enteredOtp = "";

  Future<void> _verifyOtp(String code) async {
    final authService = AuthService();
    final isVerified = await authService.verifyOtp(widget.phone, code);

    if (isVerified) {
      // Вызываем callback с подтвержденным номером телефона
      widget.onVerified(widget.phone);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Неверный код')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Подтверждение телефона'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              'Сейчас вам в SMS придёт код, чтобы подтвердить ваш номер телефона - введите его',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Roboto', fontSize: 22, fontWeight: FontWeight.w400),
            ),

            // OTP поле с otp_pin_field
            Expanded(
              child: OtpPinField(
                key: _otpPinFieldController,
                maxLength: 6,
                fieldWidth: 48,
                // Ширина каждого поля
                fieldHeight: 62,
                // Высота каждого поля
                showCursor: false,
                cursorColor: Colors.blue,
                showCustomKeyboard: true,
                customKeyboard: _buildNumpad(),
                otpPinFieldDecoration:
                    OtpPinFieldDecoration.custom,
                otpPinFieldStyle: const OtpPinFieldStyle(
                  textStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Color(0xffb222E54)),
                  fieldBorderRadius: 15.0,
                  activeFieldBorderColor: Color(0xffbD1D9F2),
                  activeFieldBackgroundColor: Color(0xffbF6F9FF),
                  defaultFieldBorderColor: Color(0xffbEBEBEF)
                ),
                keyboardType: TextInputType.number,
                onSubmit: (String text) {
                  _verifyOtp(text);
                },
                onChange: (String text) {
                  if (text.length == 6) {
                    _verifyOtp(text);
                  }
                  //_enteredOtp = text;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Создание цифровой клавиатуры
  Widget _buildNumpad() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        if (index < 9) {
          return _buildNumpadButton('${index + 1}');
        } else if (index == 9) {
          return const SizedBox.shrink(); // Пустая ячейка
        } else if (index == 10) {
          return _buildNumpadButton('0');
        } else {
          return _buildBackspaceButton();
        }
      },
    );
  }

  Widget _buildNumpadButton(String digit) {
    return Material(
      borderRadius: BorderRadius.circular(12),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _addDigit(digit),
        child: Container(
          child: Center(
            child: Text(
              digit,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Color(0xffb222E54),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton() {
    return Material(
      borderRadius: BorderRadius.circular(12),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _removeDigit,
        child: Container(
          child: const Center(
            child: Icon(
              Icons.backspace_outlined,
              size: 24,
              color: Color(0xffb222E54),
            ),
          ),
        ),
      ),
    );
  }

  // Добавление цифры
  void _addDigit(String digit) {
    if (_otpPinFieldController.currentState!.ending &&
        _otpPinFieldController.currentState!.controller.text.trim().length ==
            _otpPinFieldController.currentState!.widget.maxLength) {
      return;
    }
    _otpPinFieldController.currentState!.controller.text =
        _otpPinFieldController.currentState!.controller.text + digit;
    _bindTextIntoWidget(
        _otpPinFieldController.currentState!.controller.text.trim());
    setState(() {});
    _otpPinFieldController.currentState!.widget
        .onChange(_otpPinFieldController.currentState!.controller.text.trim());
    _otpPinFieldController.currentState!.ending =
        _otpPinFieldController.currentState!.controller.text.trim().length ==
            _otpPinFieldController.currentState!.widget.maxLength;
    if (_otpPinFieldController.currentState!.ending &&
        _otpPinFieldController.currentState!.widget.unFocusOnEnding) {
      FocusScope.of(_otpPinFieldController.currentState!.context).unfocus();
    }
  }

  void _bindTextIntoWidget(String text) {
    for (var i = text.length;
        i < _otpPinFieldController.currentState!.pinsInputed.length;
        i++) {
      _otpPinFieldController.currentState!.pinsInputed[i] = '';
    }
    if (text.isNotEmpty) {
      for (var i = 0; i < text.length; i++) {
        _otpPinFieldController.currentState!.pinsInputed[i] = text[i];
      }
    }
  }

  // Удаление цифры
  void _removeDigit() {
    if (_otpPinFieldController.currentState!.controller.text.isEmpty) {
      return;
    }
    _otpPinFieldController.currentState!.controller.text =
        _otpPinFieldController.currentState!.controller.text.substring(
            0, _otpPinFieldController.currentState!.controller.text.length - 1);
    _bindTextIntoWidget(
        _otpPinFieldController.currentState!.controller.text.trim());
    _otpPinFieldController.currentState!.setState(() {});
    _otpPinFieldController.currentState!.widget
        .onChange(_otpPinFieldController.currentState!.controller.text.trim());
  }
}
