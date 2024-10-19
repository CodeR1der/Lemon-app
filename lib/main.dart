import 'package:flutter/material.dart';
import 'firebase/employee_service.dart';
import 'models/employee.dart';
import 'screens/home_page.dart';
import 'screens/profile_screen.dart';

void main() {
  runApp(MyApp());
}

void createAndSaveEmployee() {
  Employee employee = Employee(
    employeeId: 'EMP001',
    name: 'Никита Тиводар',
    position: 'Программист',
    phone: '+79128204075',
    telegramId: '@herovi4',
    vkId: 'herovi4',
  );

  if (employee.isPhoneValid()) {
    EmployeeService().addEmployee(employee);
  } else {
    print('Неверный формат номера телефона');
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/home',  // Начальный экран приложения
      routes: {
        '/home': (context) => HomeScreen(),      // Маршрут для домашнего экрана
        '/profile': (context) => ProfileScreen(userId: '',), // Маршрут для профиля
      },
    );
  }
}
