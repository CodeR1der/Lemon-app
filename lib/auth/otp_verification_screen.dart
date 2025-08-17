// otp_verification_screen.dart
import 'package:flutter/material.dart';
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
  final TextEditingController _otpController = TextEditingController();

  void _onNumberPressed(String number) {
    if (_otpController.text.length < 6) {
      setState(() {
        _otpController.text += number;
      });
    }
  }

  void _onBackspacePressed() {
    if (_otpController.text.isNotEmpty) {
      setState(() {
        _otpController.text =
            _otpController.text.substring(0, _otpController.text.length - 1);
      });
    }
  }

  Future<void> _verifyOtp() async {
    final authService = AuthService();
    final isVerified =
        await authService.verifyOtp(widget.phone, _otpController.text);

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
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Text(
              'Сейчас вам в SMS придёт код, чтобы подтвердить ваш номер телефона - введите его',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 40),
            // Поле для отображения введенного кода
            SizedBox(
              height: 60,
              child: Center(
                child: Text(
                  _otpController.text.padRight(6, '_'),
                  style: const TextStyle(
                    fontSize: 32,
                    letterSpacing: 10,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            // Цифровая клавиатура
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                childAspectRatio: 1.5,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                padding: const EdgeInsets.symmetric(horizontal: 40),
                children: [
                  for (int i = 1; i <= 9; i++)
                    _NumberButton(
                      number: i.toString(),
                      onPressed: () => _onNumberPressed(i.toString()),
                    ),
                  const SizedBox(), // Пустая кнопка
                  _NumberButton(
                    number: '0',
                    onPressed: () => _onNumberPressed('0'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.backspace),
                    onPressed: _onBackspacePressed,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _otpController.text.length == 6 ? _verifyOtp : null,
                child: const Text('ПОДТВЕРДИТЬ'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberButton extends StatelessWidget {
  final String number;
  final VoidCallback onPressed;

  const _NumberButton({
    required this.number,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        shape: const CircleBorder(),
        padding: EdgeInsets.zero,
      ),
      onPressed: onPressed,
      child: Text(
        number,
        style: const TextStyle(fontSize: 24),
      ),
    );
  }
}
