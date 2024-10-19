import 'package:flutter/material.dart';
import '../widgets/navigation_panel.dart';

class TasksScreen extends StatelessWidget {
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
      bottomNavigationBar: CustomBottomNavigationBar(currentIndex: 2), // Индекс для главной страницы
    );
  }
}
