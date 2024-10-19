import 'package:flutter/material.dart';
import '../widgets/navigation_panel.dart';

class ProjectsScreen extends StatelessWidget {
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
      bottomNavigationBar: CustomBottomNavigationBar(currentIndex: 1),
    );
  }
}
