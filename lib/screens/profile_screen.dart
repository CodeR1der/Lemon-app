import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/navigation_panel.dart';

class ProfileScreen extends StatefulWidget {
  final String userId; // Передаем идентификатор пользователя

  ProfileScreen({required this.userId});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Переменные для хранения данных профиля
  String name = '';
  String phone = '';
  String telegramId = '';
  String vkId = '';

  @override
  void initState() {
    super.initState();
    // Загружаем данные пользователя при инициализации
    _loadUserProfile();
  }

  // Функция для загрузки данных профиля из Firestore
  Future<void> _loadUserProfile() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('employees') // Имя коллекции в Firestore
          .doc(widget.userId)
          .get();

      // Получаем данные из документа и обновляем состояние
      setState(() {
        name = userDoc['name'];
        phone = userDoc['phone'];
        telegramId = userDoc['telegramId'];
        vkId = userDoc['vkId'];
      });
    } catch (e) {
      print('Ошибка при загрузке данных профиля: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Профиль'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Контент страницы профиля
            Padding(
              padding: const EdgeInsets.only(left: 0), // Отступ слева
              child: Align(
                alignment: Alignment.centerLeft, // Выравнивание по левому краю
                child: CircleAvatar(
                  radius: 40,
                  child: Icon(Icons.person, size: 40),
                ),
              ),
            ),
            SizedBox(height: 24),
            // Динамически загруженные данные профиля
            _buildProfileSection('ФИО', name),
            SizedBox(height: 16),
            _buildProfileSection('Контактный телефон', phone),
            SizedBox(height: 16),
            _buildProfileSection('Имя пользователя в Телеграм', telegramId),
            SizedBox(height: 16),
            _buildProfileSection('Адрес страницы в VK', vkId),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(currentIndex: 4), // Панель навигации
    );
  }

  // Вспомогательная функция для отображения секций профиля
  Widget _buildProfileSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        SizedBox(height: 4),
        Text(
          content.isNotEmpty ? content : 'Загрузка...', // Отображаем данные или текст "Загрузка..."
          style: TextStyle(fontSize: 18),
        ),
      ],
    );
  }
}
