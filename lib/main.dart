import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:task_tracker/models/announcement.dart';
import 'package:task_tracker/screens/annoncement/add_announcement.dart';
import 'package:task_tracker/screens/annoncement/announcement_screen.dart';
import 'package:task_tracker/screens/employee/employees_screen.dart';
import 'package:task_tracker/screens/employee/profile_screen.dart';
import 'package:task_tracker/screens/home_page.dart';
import 'package:task_tracker/screens/project/projects_screen.dart';
import 'package:task_tracker/screens/search_screen.dart';
import 'package:task_tracker/screens/task/tasks_screen.dart';
import 'package:task_tracker/services/project_provider.dart';
import 'package:task_tracker/services/task_provider.dart';
import 'package:task_tracker/services/user_service.dart';
import 'package:task_tracker/task_screens/task_title_screen.dart';
import 'package:task_tracker/widgets/navigation_panel.dart';

import 'auth/auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Настройка системного интерфейса
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarContrastEnforced: false,
    statusBarBrightness: Brightness.light,
    statusBarIconBrightness: Brightness.dark,
  ));

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
    Get.put(UserService(Supabase.instance.client));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => ProjectProvider()),
      ],
      child: Builder(
        builder: (context) {
          // Получаем размеры системных панелей
          final mediaQuery = MediaQuery.of(context);
          final padding = mediaQuery.padding;

          return GetMaterialApp(
            builder: (context, child) {
              return MediaQuery(
                data: mediaQuery.copyWith(
                  // Сохраняем отступ для статус бара, убираем только нижний отступ
                  padding: EdgeInsets.only(top: padding.top),
                  viewPadding: EdgeInsets.only(top: padding.top),
                ),
                child: Container(
                  // Добавляем отступ только снизу (для навигационной панели)
                  padding: EdgeInsets.only(bottom: padding.bottom),
                  child: child,
                ),
              );
            },
            getPages: [
              GetPage(name: '/', page: () => const BottomNavigationMenu()),
              GetPage(
                  name: '/auth',
                  page: () => AuthScreen(supabase: Supabase.instance.client)),
              GetPage(
                  name: HomeScreen.routeName, page: () => const HomeScreen()),
              GetPage(
                  name: TaskTitleScreen.routeName,
                  page: () => const TaskTitleScreen()),
              GetPage(name: '/projects', page: () => const ProjectScreen()),
              GetPage(
                  name: '/tasks',
                  page: () => TasksScreen(user: UserService.to.currentUser!)),
              GetPage(name: '/employees', page: () => EmployeesScreen()),
              GetPage(
                  name: '/profile',
                  page: () => ProfileScreen(user: UserService.to.currentUser!)),
              GetPage(name: '/homePage', page: () => const HomeScreen()),
              GetPage(
                  name: '/create_announcement',
                  page: () => const CreateAnnouncementScreen()),
              GetPage(name: '/search', page: () => const SearchScreen()),
              GetPage(
                  name: '/announcement_detail',
                  page: () => AnnouncementDetailScreen(
                        announcement: Get.arguments as Announcement,
                      )),
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
            ),
            debugShowCheckedModeBanner: false,
            home: FutureBuilder(
              future: _initializeApp(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.hasError) {
                    return Scaffold(
                      body: Center(
                          child: Text('Ошибка запуска: ${snapshot.error}')),
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
        },
      ),
    );
  }

  Future<void> _initializeApp() async {
    try {
      AuthWrapper(
          supabase: Supabase.instance.client,
          homeScreen: const BottomNavigationMenu());
    } catch (e) {
      print('Ошибка инициализации приложения: $e');
      rethrow;
    }
  }
}
