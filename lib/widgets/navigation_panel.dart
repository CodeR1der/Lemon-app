import 'package:flutter/material.dart';
import '../screens/home_page.dart';  // Ваша страница "Главная"
import '../screens/projects_screen.dart';  // Ваша страница "Проекты"
import '../screens/tasks_screen.dart';  // Ваша страница "Задачи"
import '../screens/employees_screen.dart';  // Ваша страница "Сотрудники"
import '../screens/profile_screen.dart';  // Ваша страница "Профиль"

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;

  const CustomBottomNavigationBar({Key? key, required this.currentIndex}) : super(key: key);

  void _onItemTapped(BuildContext context, int index) {
    Widget screen;
    switch (index) {
      case 0:
        screen = HomeScreen();
        break;
      case 1:
        screen = ProjectsScreen();
        break;
      case 2:
        screen = TasksScreen();
        break;
      case 3:
        screen = EmployeesScreen();
        break;
      case 4:
        screen = ProfileScreen(userId: '',);
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation1, animation2) => screen,
        transitionDuration: Duration.zero, // Убираем анимацию
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.black,
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Главная',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.work_outline),
          label: 'Проекты',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.task),
          label: 'Задачи',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: 'Сотрудники',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_2_outlined),
          label: 'Профиль',
        ),
      ],
      onTap: (index) => _onItemTapped(context, index), // Обработка нажатий
    );
  }
}
