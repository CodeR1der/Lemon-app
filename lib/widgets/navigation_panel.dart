import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:get/get.dart';
import '../screens/home_page.dart';
import '../screens/projects_screen.dart';
import '../screens/tasks_screen.dart';
import '../screens/employees_screen.dart';
import '../screens/profile_screen.dart';
import '../services/user_service.dart';

class BottomNavigationMenu extends StatelessWidget {
  const BottomNavigationMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NavigationController());
    return Scaffold(
      bottomNavigationBar: Obx(
        () => NavigationBar(
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
      ),
      body: Obx(() => controller.screens[controller.selectedIndex.value]),
    );
  }
}

class NavigationController extends GetxController {
  final Rx<int> selectedIndex = 0.obs;

  List<Widget> get screens {
    final user = UserService.to.currentUser!;
    return [
      HomeScreen(),
      ProjectScreen(),
      TasksScreen(user: user),
      EmployeesScreen(),
      ProfileScreen(user: user)
    ];
  }
}
