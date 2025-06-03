import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:task_tracker/screens/employees_screen.dart';
import 'package:task_tracker/screens/home_page.dart';
import 'package:task_tracker/screens/profile_screen.dart';
import 'package:task_tracker/screens/projects_screen.dart';
import 'package:task_tracker/screens/tasks_screen.dart';
import 'package:task_tracker/services/task_provider.dart';
import 'package:task_tracker/services/user_service.dart';
import 'package:task_tracker/task_screens/taskTitleScreen.dart';
import 'package:task_tracker/widgets/navigation_panel.dart';
import 'auth/auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://xusyxtgdmtpupmroemzb.supabase.co',
    anonKey:
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh1c3l4dGdkbXRwdXBtcm9lbXpiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzI0NDU2NTgsImV4cCI6MjA0ODAyMTY1OH0.Z7gU-A_s6ymY7-vTW4ObeHurvtbSIt4kWe-9EXF5j9M',
  );
  initializeDateFormatting().then((_) => runApp(MyApp()));
}

class InitialBindings extends Bindings {
  @override
  void dependencies() {
    Get.put(UserService(Supabase.instance.client));
  }
}

class MyApp extends StatelessWidget {
  final SupabaseClient supabaseClient = Supabase.instance.client;

  Future<void> _initializeApp() async {
    try {
      AuthWrapper(supabase: supabaseClient, homeScreen: const BottomNavigationMenu());
    } catch (e) {
      print('Ошибка инициализации приложения: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskProvider()),
      ],
      child: GetMaterialApp(
        getPages: [
          GetPage(name: '/', page: () => const BottomNavigationMenu()),
          GetPage(name: '/auth', page: () => AuthScreen(supabase: Supabase.instance.client)),
          GetPage(name: HomeScreen.routeName, page: () => const HomeScreen()),
          GetPage(name: TaskTitleScreen.routeName, page: () => const TaskTitleScreen()),
          GetPage(name: '/projects', page: () => ProjectScreen()),
          GetPage(name: '/tasks', page: () => TasksScreen(user: UserService.to.currentUser!)),
          GetPage(name: '/employees', page: () => EmployeesScreen()),
          GetPage(name: '/profile', page: () => ProfileScreen(user: UserService.to.currentUser!)),
        ],
        initialBinding: InitialBindings(),
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
                fontSize: 14, color: Color(0xff6D7885), fontWeight: FontWeight.bold),
            titleSmall: TextStyle(fontSize: 14, color: Color(0xff6D7885)),
            displayMedium: TextStyle(fontSize: 13, color: Color(0xff6D7885)),
            displaySmall: TextStyle(fontSize: 12, color: Color(0xff6D7885)),
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
      ),
    );
  }
}