import 'package:flutter/material.dart';

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
    );
  }
}
