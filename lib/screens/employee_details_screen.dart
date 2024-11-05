import 'package:flutter/material.dart';
import '../models/employee.dart';

class EmployeeDetailScreen extends StatelessWidget {
  final Employee employee;

  const EmployeeDetailScreen({Key? key, required this.employee})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(employee.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            // Динамически загруженные данные профиля
            _buildProfileSection('ФИО', employee.name),
            _buildBorders(context),
            _buildProfileSection('Должность', employee.position),
            _buildBorders(context),
            _buildProfileSection('Контактный телефон', employee.phone),
            _buildBorders(context),
            _buildProfileSection('Имя пользователя в Телеграм', employee.telegramId),
            _buildBorders(context),
            _buildProfileSection('Адрес страницы в VK', employee.vkId),
          ],
        ),
      ),
    );
  }

  Widget _buildBorders(BuildContext context) { // Принимаем контекст
    return Column(
      children: [
        Container(
          height: 0.5, // Высота линии
          width: MediaQuery.of(context).size.width,
          color: Colors.grey.withOpacity(0.5),
        ),
      ],
    );
  }

  // Вспомогательная функция для отображения секций профиля
  Widget _buildProfileSection(String title, String content) {
    bool isLink = title == 'Имя пользователя в Телеграм' ||
        title == 'Адрес страницы в VK'; // Проверяем, является ли это ссылкой
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 13),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.grey,
            fontFamily: 'Roboto', // Используем шрифт Roboto
          ),
        ),
        Text(
          content.isNotEmpty ? content : 'Загрузка...',
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Roboto', // Используем шрифт Roboto
            color: isLink ? Colors.blue : Colors.black, // Меняем цвет на синий для Telegram и VK
          ),
        ),
        SizedBox(height: 13),
      ],
    );
  }
}
