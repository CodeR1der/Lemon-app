import 'package:flutter/material.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

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
    );
  }
}
