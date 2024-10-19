import 'package:flutter/material.dart';
import '../widgets/navigation_panel.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Главная'),
        centerTitle: true,
      ),
      body: Center(
        child: Text('Главная страница'),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(currentIndex: 0), // Индекс для главной страницы
    );
  }
}
