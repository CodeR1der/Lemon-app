import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:task_tracker/auth/auth.dart';
import 'package:task_tracker/screens/onboarding/onboarding_page.dart';
import 'package:task_tracker/services/onboarding_service.dart';
import 'package:task_tracker/services/user_service.dart';
import 'package:task_tracker/widgets/navigation_panel.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Минимальное время показа splash screen (2 секунды)
      final startTime = DateTime.now();

      // Ждем инициализации сервисов
      await Future.delayed(const Duration(milliseconds: 300));

      final onboardingService = OnboardingService.to;
      final userService = UserService.to;

      // Ждем полной инициализации OnboardingService
      await onboardingService.waitForInitialization();

      // Вычисляем оставшееся время для минимального показа splash screen
      final elapsedTime = DateTime.now().difference(startTime);
      final minShowTime = const Duration(seconds: 2);

      if (elapsedTime < minShowTime) {
        await Future.delayed(minShowTime - elapsedTime);
      }

      // Если пользователь еще не видел онбординг, показываем его
      if (!onboardingService.hasSeenOnboarding) {
        Get.offAll(() => const OnboardingPage());
        return;
      }

      // Если пользователь авторизован, показываем главный экран
      if (userService.isLoggedIn.value) {
        Get.offAll(() => const BottomNavigationMenu());
        return;
      }

      // Иначе показываем экран авторизации
      Get.offAll(() => AuthWrapper(
            supabase: Supabase.instance.client,
            homeScreen: const BottomNavigationMenu(),
          ));
    } catch (e) {
      print('Ошибка инициализации приложения: $e');
      // В случае ошибки показываем экран авторизации
      Get.offAll(() => AuthWrapper(
            supabase: Supabase.instance.client,
            homeScreen: const BottomNavigationMenu(),
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/lemon_app_logo.webp',
              height: 54,
              width: 282,
            ),
            const SizedBox(height: 20),
            // Optional loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
            ),
          ],
        ),
      ),
    );
  }
}
