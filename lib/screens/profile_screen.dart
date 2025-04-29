import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/employee.dart';
import '../services/employee_operations.dart';

// Абстрактное состояние профиля
abstract class ProfileState {
  Widget buildBody(_ProfileScreenState screen);

  Widget buildFloatingActionButton(_ProfileScreenState screen);
}

// Состояние просмотра профиля
class ViewProfileState implements ProfileState {
  @override
  Widget buildBody(_ProfileScreenState screen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        Center(child: screen._buildAvatar()),
        screen._buildProfileSection('ФИО', screen.name),
        screen._buildBorders(),
        screen._buildProfileSection('Должность', screen.position),
        screen._buildBorders(),
        screen._buildEditableProfileSection(
            'Контактный телефон', screen._phoneController, false),
        screen._buildBorders(),
        screen._buildEditableProfileSection(
            'Имя пользователя в Телеграм', screen._telegramController, false),
        screen._buildBorders(),
        screen._buildEditableProfileSection(
            'Адрес страницы в VK', screen._vkController, false),
      ],
    );
  }

  @override
  Widget buildFloatingActionButton(_ProfileScreenState screen) {
    return FloatingActionButton(
      onPressed: () {
        screen.setState(() {
          screen._currentState = EditProfileState();
        });
      },
      child: const Icon(Icons.edit),
    );
  }
}

// Состояние редактирования профиля
class EditProfileState implements ProfileState {
  @override
  Widget buildBody(_ProfileScreenState screen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        Center(child: screen._buildAvatar()),
        screen._buildProfileSection('ФИО', screen.name),
        screen._buildBorders(),
        screen._buildProfileSection('Должность', screen.position),
        screen._buildBorders(),
        screen._buildEditableProfileSection(
            'Контактный телефон', screen._phoneController, true),
        screen._buildBorders(),
        screen._buildEditableProfileSection(
            'Имя пользователя в Телеграм', screen._telegramController, true),
        screen._buildBorders(),
        screen._buildEditableProfileSection(
            'Адрес страницы в VK', screen._vkController, true),
      ],
    );
  }

  @override
  Widget buildFloatingActionButton(_ProfileScreenState screen) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton(
          onPressed: () {
            screen.setState(() {
              screen._currentState = ViewProfileState();
            });
          },
          backgroundColor: Colors.red,
          child: const Icon(Icons.close),
        ),
        const SizedBox(width: 16),
        FloatingActionButton(
          onPressed: () async {
            await screen._saveUserProfile();
            screen.setState(() {
              screen._currentState = ViewProfileState();
            });
          },
          backgroundColor: Colors.green,
          child: const Icon(Icons.save),
        ),
      ],
    );
  }
}

class ProfileScreen extends StatefulWidget {
  final Employee user;

  const ProfileScreen({required this.user, Key? key}) : super(key: key);

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

  late TextEditingController _phoneController;
  late TextEditingController _telegramController;
  late TextEditingController _vkController;

  ProfileState _currentState = ViewProfileState();

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController();
    _telegramController = TextEditingController();
    _vkController = TextEditingController();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _telegramController.dispose();
    _vkController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      if (widget.user != null) {
        setState(() {
          name = widget.user.name;
          position = widget.user.position;
          _phoneController.text = widget.user.phone ?? '';
          _telegramController.text = widget.user.telegramId ?? '';
          _vkController.text = widget.user.vkId ?? '';
          avatarUrl = widget.user.avatarUrl;
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
        userId: widget.user.userId,
        name: name,
        position: position,
        phone: _phoneController.text,
        telegramId: _telegramController.text,
        vkId: _vkController.text,
        avatarUrl: avatarUrl,
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
          await _employeeService.uploadAvatar(file, widget.user.userId);
      if (uploadedFileName != null) {
        setState(() {
          avatarUrl = uploadedFileName;
        });
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
          backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
              ? NetworkImage(_employeeService.getAvatarUrl(avatarUrl!))
              : null,
          child: avatarUrl == null || avatarUrl!.isEmpty
              ? const Icon(Icons.person, size: 50)
              : null,
        ),
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
        const SizedBox(height: 13),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          content.isNotEmpty ? content : 'Загрузка...',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 13),
      ],
    );
  }

  Widget _buildEditableProfileSection(
      String title, TextEditingController controller, bool isEditing) {
  Widget _buildEditableProfileSection(String title, TextEditingController controller, bool isEditing) {
    bool isLink = title == 'Имя пользователя в Телеграм' ||
        title == 'Адрес страницы в VK';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 13),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.grey,
            fontFamily: 'Roboto',
          ),
        ),
        const SizedBox(height: 8),
        if (isEditing)
          SizedBox(
            height: 20,
            child: TextField(
              style: Theme.of(context).textTheme.titleMedium,
              controller: controller,
              decoration: const InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
              ),
            ),
          )
        else
          SizedBox(
            height: 20,
            child: Align(
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
          ),
        const SizedBox(height: 13),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : _currentState.buildBody(this),
      ),
      floatingActionButton:
          isLoading ? null : _currentState.buildFloatingActionButton(this),
    );
  }
}