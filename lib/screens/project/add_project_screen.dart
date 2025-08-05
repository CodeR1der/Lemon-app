import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../models/employee.dart';
import '../../services/employee_operations.dart';
import '../../services/project_provider.dart';
import '../../services/user_service.dart';

class AddProjectScreen extends StatefulWidget {
  const AddProjectScreen({super.key});

  @override
  _AddProjectScreenState createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends State<AddProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _logo;
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _goalsController = TextEditingController();
  final _projectLinkController = TextEditingController();
  final _socialMediaController = TextEditingController();
  double _textFieldHeight = 60.0;

  final EmployeeService _employeeService = EmployeeService();
  List<Employee> _allEmployees = [];
  final List<Employee> _selectedEmployees = [UserService.to.currentUser!];
  bool _isLoadingEmployees = false;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    setState(() => _isLoadingEmployees = true);
    try {
      final employees = await _employeeService.getAllEmployees();
      setState(() {
        _allEmployees = employees.where((employee) => employee.userId != UserService.to.currentUser!.userId).toList();
        _isLoadingEmployees = false;
      });
    } catch (e) {
      setState(() => _isLoadingEmployees = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _goalsController.dispose();
    _projectLinkController.dispose();
    _socialMediaController.dispose();
    super.dispose();
  }

  void _showEmployeesModalSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              color: Colors.white,
              height: MediaQuery.of(context).size.height * 0.6,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Выберите сотрудников',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _isLoadingEmployees
                      ? const Center(child: CircularProgressIndicator())
                      : Expanded(
                          child: ListView.builder(
                            itemCount: _allEmployees.length,
                            itemBuilder: (context, index) {
                              final employee = _allEmployees[index];
                              final isSelected =
                                  _selectedEmployees.contains(employee);
                              return CheckboxListTile(
                                title: Text(employee.name),
                                subtitle: Text(employee.role),
                                value: isSelected,
                                onChanged: (bool? value) {
                                  setModalState(() {
                                    setState(() {
                                      if (value == true) {
                                        _selectedEmployees.add(employee);
                                      } else {
                                        _selectedEmployees.remove(employee);
                                      }
                                    });
                                  });
                                },
                                secondary: CircleAvatar(
                                  radius: 16,
                                  backgroundImage: employee.avatarUrl !=
                                      null &&
                                      employee.avatarUrl!.isNotEmpty
                                      ? NetworkImage(EmployeeService().getAvatarUrl(employee.avatarUrl!))
                                      : null,
                                  child: employee.avatarUrl == null ||
                                      employee.avatarUrl!.isEmpty
                                      ? const Icon(Icons.person, size: 16)
                                      : null,
                                ),
                              );
                            },
                          ),
                        ),
                  const SizedBox(height: 16),
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 30, horizontal: 16),
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Готово'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        _logo = result.files.single.path!;
      });
    }
  }

  bool get _canSubmit {
    return _descriptionController.text.isNotEmpty &&
        _nameController.text.isNotEmpty &&
        _goalsController.text.isNotEmpty;
  }

  void _submit() async {
    if (!_canSubmit) return;

    try {
      final projectProvider =
          Provider.of<ProjectProvider>(context, listen: false);
      final userService = UserService.to;
      final companyId = userService.currentUser?.companyId;
      if (companyId == null) {
        Get.snackbar('Ошибка', 'Компания не найдена');
        return;
      }

      projectProvider.addProject(
          logo: _logo,
          name: _nameController.text,
          description: _descriptionController.text,
          goals: _goalsController.text,
          projectLink: _projectLinkController.text,
          companyId: companyId,
          team: _selectedEmployees);

      if (projectProvider.error == null) {
        Navigator.pop(context);
      }
    } catch (e) {
    }
  }

  @override
  Widget build(BuildContext context) {
    final paddingBottomSheet = 80.0;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Создать проект'),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: paddingBottomSheet),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Consumer<ProjectProvider>(
              builder: (context, provider, child) {
                return Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      const Text(
                        'Логотип проекта',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: pickFile,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black,
                          side: const BorderSide(color: Colors.orange),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Iconsax.gallery,
                              size: 24,
                            ),
                            SizedBox(width: 8),
                            Text('Добавить логотип'),
                          ],
                        ),
                      ),
                      if (_logo != null) ...[
                        const SizedBox(height: 8),
                        Text('Выбранный логотип: $_logo'),
                      ],
                      const SizedBox(height: 12),
                      const Text(
                        'Название проекта',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SingleChildScrollView(
                          child: TextField(
                            controller: _nameController,
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.all(12),
                              border: InputBorder.none,
                              hintText: 'Название',
                              hintStyle: TextStyle(color: Colors.grey),
                            ),
                            onChanged: (text) {
                              final textPainter = TextPainter(
                                text: TextSpan(
                                  text: text,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                maxLines: null,
                                textDirection: TextDirection.ltr,
                              )..layout(
                                  maxWidth:
                                      MediaQuery.of(context).size.width - 56);

                              setState(() {
                                _textFieldHeight = textPainter.size.height + 60;
                                if (_textFieldHeight < 60)
                                  _textFieldHeight = 60;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Описание проекта',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SingleChildScrollView(
                          child: TextField(
                            controller: _descriptionController,
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.all(12),
                              border: InputBorder.none,
                              hintText: 'Описание',
                              hintStyle: TextStyle(color: Colors.grey),
                            ),
                            onChanged: (text) {
                              final textPainter = TextPainter(
                                text: TextSpan(
                                  text: text,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                maxLines: null,
                                textDirection: TextDirection.ltr,
                              )..layout(
                                  maxWidth:
                                      MediaQuery.of(context).size.width - 56);

                              setState(() {
                                _textFieldHeight = textPainter.size.height + 24;
                                if (_textFieldHeight < 60)
                                  _textFieldHeight = 60;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Цели проекта',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SingleChildScrollView(
                          child: TextField(
                            controller: _goalsController,
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.all(12),
                              border: InputBorder.none,
                              hintText: 'Цели',
                              hintStyle: TextStyle(color: Colors.grey),
                            ),
                            onChanged: (text) {
                              final textPainter = TextPainter(
                                text: TextSpan(
                                  text: text,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                maxLines: null,
                                textDirection: TextDirection.ltr,
                              )..layout(
                                  maxWidth:
                                      MediaQuery.of(context).size.width - 56);

                              setState(() {
                                _textFieldHeight = textPainter.size.height + 24;
                                if (_textFieldHeight < 60)
                                  _textFieldHeight = 60;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Ссылка на проект',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SingleChildScrollView(
                          child: TextField(
                            controller: _projectLinkController,
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.all(12),
                              border: InputBorder.none,
                              hintText: 'Ссылка',
                              hintStyle: TextStyle(color: Colors.grey),
                            ),
                            onChanged: (text) {
                              final textPainter = TextPainter(
                                text: TextSpan(
                                  text: text,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                maxLines: null,
                                textDirection: TextDirection.ltr,
                              )..layout(
                                  maxWidth:
                                      MediaQuery.of(context).size.width - 56);

                              setState(() {
                                _textFieldHeight = textPainter.size.height + 24;
                                if (_textFieldHeight < 60)
                                  _textFieldHeight = 60;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Социальные сети',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SingleChildScrollView(
                          child: TextField(
                            controller: _socialMediaController,
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.all(12),
                              border: InputBorder.none,
                              hintText: '{"facebook": "link"}',
                              hintStyle: TextStyle(color: Colors.grey),
                            ),
                            onChanged: (text) {
                              final textPainter = TextPainter(
                                text: TextSpan(
                                  text: text,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                maxLines: null,
                                textDirection: TextDirection.ltr,
                              )..layout(
                                  maxWidth:
                                      MediaQuery.of(context).size.width - 56);

                              setState(() {
                                _textFieldHeight = textPainter.size.height + 24;
                                if (_textFieldHeight < 60)
                                  _textFieldHeight = 60;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Прикрепить сотрудников к проекту',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: _showEmployeesModalSheet,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black,
                          side: const BorderSide(color: Colors.orange),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Iconsax.user_cirlce_add,
                              size: 24,
                            ),
                            SizedBox(width: 8),
                            Text('Прикрепить сотрудников'),
                          ],
                        ),
                      ),
                      if (_selectedEmployees.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Выбранные сотрудники:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        ..._selectedEmployees.map((employee) => ListTile(
                              leading: CircleAvatar(
                                child: Text(employee.name[0]),
                              ),
                              title: Text(employee.name),
                              subtitle: Text(employee.role),
                              trailing: employee.userId != UserService.to.currentUser!.userId ? IconButton(
                                icon: const Icon(Iconsax.trash,
                                    color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _selectedEmployees.remove(employee);
                                  });
                                },
                              ) : null,
                            )),
                      ],
                      const SizedBox(height: 12),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
      bottomSheet: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _canSubmit ? _submit : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _canSubmit ? Colors.orange : Colors.grey,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Отправить'),
        ),
      ),
    );
  }
}
