import 'package:flutter/material.dart';
import '../widgets/navigation_panel.dart';

class EmployeesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Сотрудники'),
        centerTitle: true,
      ),
      body: Center(
        child: Text('Здесь сотрудники'),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(currentIndex: 3), // Индекс для главной страницы
    );
  }
}
