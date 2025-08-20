import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:task_tracker/auth/qr_scanner_screen.dart';

import '../widgets/common/app_buttons.dart';
import '../widgets/common/app_spacing.dart';
import 'auth_screen.dart';

class AuthMainScreen extends StatelessWidget {
  const AuthMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Логотип или заголовок
              const SizedBox(height: 150),
              Image.asset(
                'assets/lemon_app_logo.webp',
                height: 54,
                width: 282,
              ),
              const SizedBox(height: 8),
              Text(
                'Управление задачами и проектами',
                style: Theme
                    .of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),

              // Кнопки действий
              AppButtons.primaryButton(
                text: 'Регистрация',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AuthScreen(supabase: Supabase.instance.client, isSignUp: true),
                    ),
                  );
                },
                icon: Icons.person_add,
              ),
              AppSpacing.height16,

              AppButtons.secondaryButton(
                text: 'Вход в приложение',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AuthScreen(supabase: Supabase.instance.client, isSignUp: false),
                    ),
                  );
                },
                icon: Icons.login,
              ),

              AppSpacing.height16,


              AppButtons.secondaryButton(
                text: 'Сканнировать QR-код',
                onPressed: () async {
                  final code = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const QRScannerScreen(),
                    ),
                  );

                  if (code != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AuthScreen(supabase: Supabase.instance.client, isSignUp: true, isEmployee: true, companyCode: code.toString()))
                    );
                  }
                },
                icon: Icons.qr_code,
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
