import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/employee.dart';
import '../services/employee_operations.dart';

class ProfileScreen extends StatefulWidget {
  final String user_id;

  ProfileScreen({required this.user_id});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final EmployeeService _employeeService = EmployeeService();
  final ImagePicker _imagePicker = ImagePicker();

  String name = '';
  String position = '';
  String? avatarUrl;
  bool isLoading = true;
  String role = '';

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
      final employee = await _employeeService.getEmployee(widget.user_id);
      if (employee != null) {
        setState(() {
          name = employee.name;
          position = employee.position;
          _phoneController.text = employee.phone?? '';
          _telegramController.text = employee.telegram_id?? '';
          _vkController.text = employee.vk_id ?? '';
          avatarUrl = employee.avatar_url;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Ошибка при загрузке данных профиля: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _saveUserProfile() async {
    try {
      await _employeeService.updateEmployee(Employee(
        user_id: widget.user_id,
        name: name,
        position: position,
        phone: _phoneController.text,
        telegram_id: _telegramController.text,
        vk_id: _vkController.text,
        avatar_url: avatarUrl,
        role: role,
      ));
    } catch (e) {
      print('Ошибка при сохранении данных профиля: $e');
    }
  }

  Future<void> _selectAndUploadAvatar() async {
    final pickedFile =
        await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final uploadedFileName =
          await _employeeService.uploadAvatar(file, widget.user_id);
      if (uploadedFileName != null) {
        setState(() {
          avatarUrl = uploadedFileName; // Обновляем URL аватара
        });

        // Сразу вызываем сохранение профиля, чтобы сохранить URL аватара
        await _saveUserProfile();
      }
    }
  }

  Widget _buildAvatar() {
    return GestureDetector(
      onTap: _selectAndUploadAvatar,
      child: Align(
        alignment: Alignment.centerLeft,
        child: CircleAvatar(
          radius: 50,
          backgroundImage: avatarUrl != ''
              ? NetworkImage(_employeeService.getAvatarUrl(avatarUrl),)
              : null,
          child: avatarUrl == ''
              ? const Icon(Icons.person, size: 50)
              : null,
        ),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 40),
                  Center(child: _buildAvatar()),
                  _buildProfileSection('ФИО', name),
                  _buildBorders(),
                  _buildProfileSection('Должность', position),
                  _buildBorders(),
                  _buildEditableProfileSection(
                      'Контактный телефон', _phoneController),
                  _buildBorders(),
                  _buildEditableProfileSection(
                      'Имя пользователя в Телеграм', _telegramController),
                  _buildBorders(),
                  _buildEditableProfileSection(
                      'Адрес страницы в VK', _vkController),
                ],
              ),
      ),
      floatingActionButton: isLoading
          ? null
          : _isEditing
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FloatingActionButton(
                      onPressed: () {
                        setState(() {
                          _isEditing =
                              false; // Выход из режима редактирования без сохранения
                        });
                      },
                      backgroundColor: Colors.red,
                      child: Icon(Icons.close),
                    ),
                    SizedBox(width: 16),
                    FloatingActionButton(
                      onPressed: () async {
                        await _saveUserProfile(); // Сохранение профиля
                        setState(() {
                          _isEditing =
                              false; // Выход из режима редактирования после сохранения
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 13),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium
        ),
        Text(
          content.isNotEmpty ? content : 'Загрузка...',
          style: Theme.of(context).textTheme.bodyLarge
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
              style: Theme.of(context).textTheme.titleMedium,
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
