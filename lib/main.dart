// main.dart
import 'package:get/get.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:task_tracker/widgets/navigation_panel.dart';
import 'package:task_tracker/services/user_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  InitialBindings().dependencies();
  await Supabase.initialize(
    url: 'https://xusyxtgdmtpupmroemzb.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh1c3l4dGdkbXRwdXBtcm9lbXpiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzI0NDU2NTgsImV4cCI6MjA0ODAyMTY1OH0.Z7gU-A_s6ymY7-vTW4ObeHurvtbSIt4kWe-9EXF5j9M',
  );

  runApp(MyApp());
}

class InitialBindings extends Bindings {
  @override
  void dependencies() {
    Get.put<UserService>(UserService(), permanent: true);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<void> _initializeApp() async {
    try {
      const userId = '71a5a83c-7bf8-4227-ba71-3fc5eb6407c2';
      await UserService.to.initializeUser(userId);
    } catch (e) {
      print('Ошибка инициализации приложения: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      theme: ThemeData(
        fontFamily: 'Roboto',
        textTheme: TextTheme(
          bodyMedium: TextStyle(fontSize: 15, color: Colors.black),
          bodySmall: TextStyle(fontSize: 14, color: Colors.black),
          bodyLarge: TextStyle(fontSize: 16, color: Colors.black),
          titleMedium: TextStyle(fontSize: 14, color: Colors.grey,
              fontWeight: FontWeight.bold),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: FutureBuilder(
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
      ),
    );
  }
}