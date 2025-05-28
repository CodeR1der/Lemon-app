// main.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:task_tracker/screens/home_page.dart';
import 'package:task_tracker/services/task_provider.dart';
import 'package:task_tracker/services/user_service.dart';
import 'package:task_tracker/task_screens/taskTitleScreen.dart';
import 'package:task_tracker/widgets/app_initializer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  InitialBindings().dependencies();
  await Supabase.initialize(
    url: 'https://xusyxtgdmtpupmroemzb.supabase.co',
    anonKey:
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh1c3l4dGdkbXRwdXBtcm9lbXpiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzI0NDU2NTgsImV4cCI6MjA0ODAyMTY1OH0.Z7gU-A_s6ymY7-vTW4ObeHurvtbSIt4kWe-9EXF5j9M',
  );

  initializeDateFormatting().then((_) {
    runApp(const MyApp());
  });
}

class InitialBindings extends Bindings {
  @override
  void dependencies() {
    Get.put<UserService>(UserService(), permanent: true);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskProvider()),
      ],
      child: GetMaterialApp(
        routes: {
          HomeScreen.routeName: (context) => const HomeScreen(),
          TaskTitleScreen.routeName: (context) => const TaskTitleScreen(),
        },
        theme: ThemeData(
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.black),
          ),
          scaffoldBackgroundColor: Colors.white,
          fontFamily: 'Roboto',
          textTheme: const TextTheme(
            bodyMedium: TextStyle(fontSize: 15, color: Colors.black),
            bodySmall: TextStyle(fontSize: 14, color: Colors.black),
            bodyLarge: TextStyle(fontSize: 16, color: Colors.black),
            titleMedium: TextStyle(
                fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold),
            titleSmall: TextStyle(fontSize: 14, color: Colors.grey),
            displayMedium: TextStyle(fontSize: 13, color: Colors.grey),
            displaySmall: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
        debugShowCheckedModeBanner: false,
        home: const AppInitializer(),
      ),
    );
  }
}