// main.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:task_tracker/screens/home_page.dart';
import 'package:task_tracker/services/user_service.dart';
import 'package:task_tracker/task_screens/taskTitleScreen.dart';
import 'package:task_tracker/widgets/navigation_panel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  InitialBindings().dependencies();
  await Supabase.initialize(
    url: 'https://xusyxtgdmtpupmroemzb.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh1c3l4dGdkbXRwdXBtcm9lbXpiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzI0NDU2NTgsImV4cCI6MjA0ODAyMTY1OH0.Z7gU-A_s6ymY7-vTW4ObeHurvtbSIt4kWe-9EXF5j9M',
  );

  initializeDateFormatting().then((_) => runApp(const MyApp()));
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
    return GetMaterialApp(
      routes: {
        HomeScreen.routeName: (context) => const HomeScreen(),
        TaskTitleScreen.routeName: (context) => const TaskTitleScreen(),
        // Добавляй другие экраны здесь
      },
      theme: ThemeData(
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
        ),
        scaffoldBackgroundColor: Colors.white, // Белый фон для всех Scaffold
        fontFamily: 'Roboto',
        textTheme: const TextTheme(
            bodyMedium: TextStyle(fontSize: 15, color: Colors.black),
            bodySmall: TextStyle(fontSize: 14, color: Colors.black),
            bodyLarge: TextStyle(fontSize: 16, color: Colors.black),
            titleMedium: TextStyle(
                fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold),
            titleSmall: TextStyle(fontSize: 14, color: Colors.grey),
            displayMedium: TextStyle(fontSize: 13, color: Colors.grey),
            displaySmall: TextStyle(fontSize: 12, color: Colors.grey)
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
