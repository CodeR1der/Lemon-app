import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/common/app_buttons.dart';
import '../widgets/common/app_spacing.dart';
import 'auth_screen.dart';
import 'login_screen.dart';

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
              const SizedBox(height: 60),
              Icon(
                Icons.task_alt,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 24),
              Text(
                'Task Tracker',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Управление задачами и проектами',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
                          AuthScreen(supabase: Supabase.instance.client),
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
                      builder: (_) => const LoginScreen(),
                    ),
                  );
                },
                icon: Icons.login,
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
