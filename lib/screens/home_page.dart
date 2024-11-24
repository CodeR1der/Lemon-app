import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
    );
  }
}
