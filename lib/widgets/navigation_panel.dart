import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../screens/employees_screen.dart';
import '../screens/home_page.dart';
import '../screens/profile_screen.dart';
import '../screens/projects_screen.dart';
import '../screens/tasks_screen.dart';
import '../services/user_service.dart';

class BottomNavigationMenu extends StatelessWidget {
  const BottomNavigationMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NavigationController());
    return Obx(() {
      if (!UserService.to.isInitialized || !controller.isScreensReady.value) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      // Redirect to AuthScreen if not logged in
      if (!UserService.to.isLoggedIn) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.offNamed('/auth');
        });
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      // Display navigation bar and selected screen
      return Scaffold(
        bottomNavigationBar: NavigationBar(
          elevation: 0,
          backgroundColor: Colors.white,
          selectedIndex: controller.selectedIndex.value,
          onDestinationSelected: (index) =>
              controller.selectedIndex.value = index,
          destinations: const [
            NavigationDestination(
                icon: Icon(Iconsax.home_2_copy), label: 'Главная'),
            NavigationDestination(
                icon: Icon(Iconsax.category_copy), label: 'Проекты'),
            NavigationDestination(
                icon: Icon(Iconsax.document_text_copy), label: 'Задачи'),
            NavigationDestination(
                icon: Icon(Iconsax.profile_2user_copy), label: 'Сотрудники'),
            NavigationDestination(
                icon: Icon(Iconsax.profile_circle_copy), label: 'Профиль'),
          ],
        ),
        body: controller.screens[controller.selectedIndex.value],
      );
    });
  }
}

class NavigationController extends GetxController {
  final RxInt selectedIndex = 0.obs;
  final RxBool isScreensReady = false.obs;
  final List<Widget> _screens = [];

  @override
  void onInit() {
    super.onInit();
    _initializeScreens();
  }

  Future<void> _initializeScreens() async {
    debugPrint('Initializing NavigationController screens');
    try {
      // Wait for UserService to initialize
      if (!UserService.to.isInitialized) {
        await Future.doWhile(() async {
          await Future.delayed(const Duration(milliseconds: 100));
          return !UserService.to.isInitialized;
        });
      }

      // Check if user is logged in
      if (!UserService.to.isLoggedIn) {
        isScreensReady.value = true; // Allow redirection to AuthScreen
        return;
      }

      // Initialize screens with currentUser
      _screens.addAll([
        const HomeScreen(),
        ProjectScreen(),
        TasksScreen(user: UserService.to.currentUser!),
        EmployeesScreen(),
        ProfileScreen(user: UserService.to.currentUser!),
      ]);
      isScreensReady.value = true;
      debugPrint('Screens initialized');
    } catch (e) {
      debugPrint('Error initializing screens: $e');
      Get.snackbar('Ошибка', 'Не удалось инициализировать экраны: $e');
      isScreensReady.value = true; // Allow UI to proceed even on error
    }
  }

  List<Widget> get screens => _screens;
}
