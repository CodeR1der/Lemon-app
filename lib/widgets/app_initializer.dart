// app_initializer.dart
import 'package:flutter/material.dart';

import '../services/user_service.dart';
import 'navigation_panel.dart';

class AppInitializer extends StatelessWidget {
  const AppInitializer({super.key});

  Future<void> _initializeApp() async {
    try {
      const userId =
          //'e50629e9-fef5-472f-b798-58fedc9739be'; //наблюдатель
          //'d1e6c36b-0fb1-4686-9ccd-a062bd95011d'; //сотрудник исполнитель
          'd6c99c8b-fd07-4702-b849-71cd603eab0b'; //владислав постановщик
          //'71a5a83c-7bf8-4227-ba71-3fc5eb6407c2'; //никита коммуникатор
      await UserService.to.initializeUser(userId);
    } catch (e) {
      print('Ошибка инициализации приложения: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializeApp(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(child: Text('Ошибка запуска: ${snapshot.error}')),
            );
          }
          return const BottomNavigationMenu();
        }
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
