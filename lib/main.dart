import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:task_tracker/widgets/navigation_panel.dart';
import 'screens/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Supabase.initialize(
    url: 'https://xusyxtgdmtpupmroemzb.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh1c3l4dGdkbXRwdXBtcm9lbXpiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzI0NDU2NTgsImV4cCI6MjA0ODAyMTY1OH0.Z7gU-A_s6ymY7-vTW4ObeHurvtbSIt4kWe-9EXF5j9M',
  );
  //createAndSaveEmployee();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      theme: ThemeData(
        // Задаем шрифт для всего приложения
        fontFamily: 'Roboto', // Название шрифта
        textTheme: TextTheme(
          bodyMedium: TextStyle(fontSize: 15,color: Colors.black),
          bodySmall: TextStyle(fontSize: 14,color: Colors.black),
          bodyLarge: TextStyle(fontSize: 16,color: Colors.black),
          titleMedium: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold),
        ),
      ),
      debugShowCheckedModeBanner: false,
      routes: {
        '/home': (context) => const HomeScreen(),      // Маршрут для домашнего экрана
      },
      home: const BottomNavigationMenu(),
    );
  }
}
