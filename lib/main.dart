import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:task_tracker/widgets/navigation_panel.dart';
import 'screens/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Supabase.initialize(
    url: 'https://oergqqjwtapfqcqagyfs.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9lcmdxcWp3dGFwZnFjcWFneWZzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzEzNDU3ODUsImV4cCI6MjA0NjkyMTc4NX0.jnj7QD0WEnkjiTq2cIq_dR_LwyXJy70rHJ8UHeiJC-s',
  );
  //createAndSaveEmployee();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      routes: {
        '/home': (context) => const HomeScreen(),      // Маршрут для домашнего экрана
      },
      home: const BottomNavigationMenu(),
    );
  }
}
