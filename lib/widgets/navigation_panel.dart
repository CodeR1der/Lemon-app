import 'package:flutter/material.dart';
import '../screens/home_page.dart';
import '../screens/projects_screen.dart';
import '../screens/tasks_screen.dart';
import '../screens/employees_screen.dart';
import '../screens/profile_screen.dart';

class CustomBottomNavigationBar extends StatefulWidget {
  final int currentIndex;

  const CustomBottomNavigationBar({Key? key, required this.currentIndex}) : super(key: key);

  @override
  _CustomBottomNavigationBarState createState() => _CustomBottomNavigationBarState();
}

class _CustomBottomNavigationBarState extends State<CustomBottomNavigationBar> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.currentIndex;
  }

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
        screen = ProfileScreen(userId: 'e717cc52-72ec-4b21-aa48-05a2a60dec8c');
        break;
      default:
        return;
    }

    setState(() {
      _selectedIndex = index;
    });

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation1, animation2) => screen,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      items: [
        _buildNavigationBarItem(
          context,
          index: 0,
          assetPath: 'icons/navigation_panel/home.png',
          label: 'Главная',
        ),
        _buildNavigationBarItem(
          context,
          index: 1,
          assetPath: 'icons/navigation_panel/projects.png',
          label: 'Проекты',
        ),
        _buildNavigationBarItem(
          context,
          index: 2,
          assetPath: 'icons/navigation_panel/tasks.png',
          label: 'Задачи',
        ),
        _buildNavigationBarItem(
          context,
          index: 3,
          assetPath: 'icons/navigation_panel/employees.png',
          label: 'Сотрудники',
        ),
        _buildNavigationBarItem(
          context,
          index: 4,
          assetPath: 'icons/navigation_panel/profile.png',
          label: 'Профиль',
        ),
      ],
      onTap: (index) => _onItemTapped(context, index),
    );
  }

  BottomNavigationBarItem _buildNavigationBarItem(BuildContext context,
      {required int index, required String assetPath, required String label}) {
    return BottomNavigationBarItem(
      icon: GestureDetector(
        onTap: () => _onItemTapped(context, index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Анимация применяется только к иконке
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: 64, // Ширина для иконки
              height: 32, // Высота для иконки
              decoration: BoxDecoration(
                color: _selectedIndex == index ? Colors.grey[300] : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Image.asset(
                  assetPath,
                  width: 24,
                  height: 24,
                  color: _selectedIndex == index ? Colors.black : Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: _selectedIndex == index ? Colors.black : Colors.grey,
                fontSize: 12,
                fontFamily: 'Roboto'
              ),
            ),
          ],
        ),
      ),
      label: '',
    );
  }
}
