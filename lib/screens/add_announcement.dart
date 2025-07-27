import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:task_tracker/models/announcement.dart';
import 'package:task_tracker/models/employee.dart';
import 'package:task_tracker/services/employee_operations.dart';
import 'package:task_tracker/services/user_service.dart';

import '../services/announcement_operations.dart';

class CreateAnnouncementScreen extends StatefulWidget {
  static const routeName = '/create_announcement';

  const CreateAnnouncementScreen({super.key});

  @override
  State<CreateAnnouncementScreen> createState() =>
      _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState extends State<CreateAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _fullTextController = TextEditingController();
  bool _isLoading = false;
  final List<String> _attachments = [];
  final String _companyId = UserService.to.currentUser!.companyId;

  // Новые поля для выбора сотрудников
  List<Employee> _allEmployees = [];
  Set<String> _selectedEmployeeIds = {};
  bool _isLoadingEmployees = true;

  bool get _canSubmit {
    return _titleController.text.isNotEmpty &&
        _fullTextController.text.isNotEmpty &&
        _selectedEmployeeIds.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    try {
      final employees = await EmployeeService().getAllEmployees();
      setState(() {
        _allEmployees = employees;
        // По умолчанию выбираем всех сотрудников
        _selectedEmployeeIds = employees.map((e) => e.userId).toSet();
        _isLoadingEmployees = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingEmployees = false;
      });
      Get.snackbar('Ошибка', 'Не удалось загрузить сотрудников: $e');
    }
  }

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        _attachments.add(result.files.single.path!);
      });
    }
  }

  void _toggleEmployeeSelection(String employeeId) {
    setState(() {
      if (_selectedEmployeeIds.contains(employeeId)) {
        _selectedEmployeeIds.remove(employeeId);
      } else {
        _selectedEmployeeIds.add(employeeId);
      }
    });
  }

  void _selectAllEmployees() {
    setState(() {
      _selectedEmployeeIds = _allEmployees.map((e) => e.userId).toSet();
    });
  }

  void _deselectAllEmployees() {
    setState(() {
      _selectedEmployeeIds.clear();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _fullTextController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedEmployeeIds.isEmpty) {
      Get.snackbar('Ошибка', 'Выберите хотя бы одного сотрудника');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = UserService.to.currentUser!;

      final newAnnouncement = Announcement(
        title: _titleController.text.trim(),
        fullText: _fullTextController.text.trim(),
        date: DateTime.now(),
        readBy: [],
        attachments: _attachments,
        companyId: _companyId,
        selectedEmployees: _selectedEmployeeIds.toList(),
        status: 'active',
        id: '',
      );

      await AnnouncementService().createAnnouncement(newAnnouncement);

      // Создаем лог создания объявления в отдельной таблице
      await AnnouncementService.addLog(
          newAnnouncement.id,
          'created',
          currentUser.userId,
          currentUser.name,
          currentUser.role,
          newAnnouncement.companyId);
      Get.snackbar('Успех', 'Объявление успешно создано');
      Navigator.pop(context);
      Get.back(result: true);
    } catch (e) {
      Get.snackbar('Ошибка', 'Не удалось создать объявление: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset:
          false, // Предотвращаем поднятие контента при появлении клавиатуры
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: const Text('Объявление'),
      ),
      body: SafeArea(
        top: false,
        child: _companyId == null
            ? const Center(
                child: Text('Ошибка: идентификатор компании не указан'))
            : _isLoadingEmployees
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Название объявления',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _titleController,
                              decoration: InputDecoration(
                                hintText: 'Краткий текст',
                                hintStyle:
                                    Theme.of(context).textTheme.bodyMedium,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Пожалуйста, введите заголовок';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            Text('Подробное описание объявления',
                                style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _fullTextController,
                              decoration: InputDecoration(
                                hintText: 'Описание',
                                hintStyle:
                                    Theme.of(context).textTheme.bodyMedium,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              maxLines: 5,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Пожалуйста, введите полный текст';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            // Секция выбора сотрудников
                            Text(
                              'Выберите сотрудников',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),

                            // Кнопки выбора всех/отмены выбора всех
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _selectAllEmployees,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.black,
                                      side: const BorderSide(
                                          color: Colors.orange),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text('Выбрать всех'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _deselectAllEmployees,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.black,
                                      side:
                                          const BorderSide(color: Colors.grey),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text('Снять выбор'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Список сотрудников
                            Container(
                              constraints: const BoxConstraints(maxHeight: 200),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: _allEmployees.length,
                                itemBuilder: (context, index) {
                                  final employee = _allEmployees[index];
                                  final isSelected = _selectedEmployeeIds
                                      .contains(employee.userId);

                                  return CheckboxListTile(
                                    value: isSelected,
                                    onChanged: (bool? value) {
                                      _toggleEmployeeSelection(employee.userId);
                                    },
                                    title: Text(employee.name),
                                    subtitle: Text(employee.position),
                                    secondary: CircleAvatar(
                                      radius: 16,
                                      backgroundImage: employee.avatarUrl !=
                                                  null &&
                                              employee.avatarUrl!.isNotEmpty
                                          ? NetworkImage(employee.avatarUrl!)
                                          : null,
                                      child: employee.avatarUrl == null ||
                                              employee.avatarUrl!.isEmpty
                                          ? const Icon(Icons.person, size: 16)
                                          : null,
                                    ),
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                  );
                                },
                              ),
                            ),

                            const SizedBox(height: 16),
                            Text(
                              'Прикрепить файлы (в том числе фото)',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 6),
                            // Кнопка добавления файла
                            OutlinedButton(
                              onPressed: pickFile,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.black,
                                side: const BorderSide(color: Colors.orange),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Iconsax.add_circle_copy),
                                  SizedBox(width: 8),
                                  Text('Добавить файл'),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _submitForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    _canSubmit ? Colors.orange : Colors.grey,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Опубликовать'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
      ),
      bottomSheet: Container(
        color: Colors.white,
        padding: EdgeInsets.only(
          top: 30,
          left: 16,
          right: 16,//
          bottom: MediaQuery.of(context).viewPadding.bottom +
              16, // Используем viewPadding для учета системной навигации
        ),
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _submitForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: _canSubmit ? Colors.orange : Colors.grey,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Опубликовать'),
        ),
      ),
    );
  }
}
