import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase/employee_service.dart';
import '../models/employee.dart';
import '../widgets/navigation_panel.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  ProfileScreen({required this.userId});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final EmployeeService _employeeService = EmployeeService();

  String name = '';
  String position = '';
  bool isLoading = true;

  // Контроллеры для текстовых полей
  late TextEditingController _phoneController = TextEditingController();
  late TextEditingController _telegramController = TextEditingController();
  late TextEditingController _vkController = TextEditingController();

  bool _isEditing = false; // Флаг редактирования

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('employees')
          .doc(widget.userId)
          .get();

      setState(() {
        name = userDoc['name'];
        position = userDoc['position'];
        _phoneController.text = userDoc['phone'];
        _telegramController.text = userDoc['telegramId'];
        _vkController.text = userDoc['vkId'];
        isLoading = false; // Устанавливаем флаг загрузки в false
      });
    } catch (e) {
      print('Ошибка при загрузке данных профиля: $e');
      setState(() {
        isLoading = false; // Устанавливаем флаг загрузки в false даже при ошибке
      });
    }
  }

  Future<void> _saveUserProfile() async {
    try {
      await _employeeService.updateEmployee(Employee(
        userId: widget.userId,
        name: name,
        position: position,
        phone: _phoneController.text,
        telegramId: _telegramController.text,
        vkId: _vkController.text,
      ));
    } catch (e) {
      print('Ошибка при сохранении данных профиля: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading // Показываем индикатор загрузки, если данные еще загружаются
            ? Center(child: CircularProgressIndicator())
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.only(left: 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: CircleAvatar(
                  radius: 40,
                  child: Icon(Icons.person, size: 40),
                ),
              ),
            ),
            _buildProfileSection('ФИО', name),
            _buildBorders(),
            _buildProfileSection('Должность', position),
            _buildBorders(),
            _buildEditableProfileSection('Контактный телефон', _phoneController),
            _buildBorders(),
            _buildEditableProfileSection('Имя пользователя в Телеграм', _telegramController),
            _buildBorders(),
            _buildEditableProfileSection('Адрес страницы в VK', _vkController),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(currentIndex: 4),
      floatingActionButton: isLoading
          ? null
          : _isEditing
          ? Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              setState(() {
                _isEditing = false; // Выход из режима редактирования без сохранения
              });
            },
            backgroundColor: Colors.red,
            child: Icon(Icons.close),
          ),
          SizedBox(width: 16), // Отступ между кнопками
          FloatingActionButton(
            onPressed: () async {
              await _saveUserProfile(); // Сохранение профиля
              setState(() {
                _isEditing = false; // Выход из режима редактирования после сохранения
              });
            },
            backgroundColor: Colors.green,
            child: Icon(Icons.save),
          ),
        ],
      )
          : FloatingActionButton(
        onPressed: () {
          setState(() {
            _isEditing = true; // Включает режим редактирования
          });
        },
        child: Icon(Icons.edit),
      ),
    );
  }

  Widget _buildBorders() {
    return Column(
      children: [
        Container(
          height: 0.5,
          width: MediaQuery.of(context).size.width,
          color: Colors.grey.withOpacity(0.5),
        ),
      ],
    );
  }

  Widget _buildProfileSection(String title, String content) {
    bool isLink = title == 'Имя пользователя в Телеграм' || title == 'Адрес страницы в VK';
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
            fontFamily: 'Roboto',
          ),
        ),
        Text(
          content.isNotEmpty ? content : 'Загрузка...',
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Roboto',
            color: isLink ? Colors.blue : Colors.black,
          ),
        ),
        SizedBox(height: 13),
      ],
    );
  }

  Widget _buildEditableProfileSection(String title, TextEditingController controller) {
    bool isLink = title == 'Имя пользователя в Телеграм' || title == 'Адрес страницы в VK';

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
            fontFamily: 'Roboto',
          ),
        ),
        SizedBox(height: 8), // Отступ между заголовком и содержимым
        if (_isEditing)
          Container(
            height: 20, // Фиксированная высота для текстового поля
            child: TextField(
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Roboto',
                color: isLink ? Colors.blue : Colors.black,
              ),
              controller: controller,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
              ),
            ),
          )
        else
          Container(
            height: 20, // Фиксированная высота для текстового поля
            alignment: Alignment.centerLeft,
            child: Text(
              controller.text.isNotEmpty ? controller.text : 'Загрузка...',
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Roboto',
                color: isLink ? Colors.blue : Colors.black,
              ),
            ),
          ),
        SizedBox(height: 13),
      ],
    );
  }
}
