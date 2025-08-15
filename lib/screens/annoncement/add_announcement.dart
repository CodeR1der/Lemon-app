import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:task_tracker/models/announcement.dart';
import 'package:task_tracker/models/employee.dart';
import 'package:task_tracker/services/employee_operations.dart';
import 'package:task_tracker/services/user_service.dart';
import 'package:task_tracker/widgets/common/app_colors.dart';
import 'package:task_tracker/widgets/common/app_common.dart';
import 'package:task_tracker/widgets/employees_modal_sheet.dart';

import '../../services/announcement_operations.dart';

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
        _allEmployees = employees
            .where((e) => e.userId != UserService.to.currentUser!.userId)
            .toList();
        // По умолчанию выбираем всех сотрудников
        _isLoadingEmployees = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingEmployees = false;
      });
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

  String _getLastName(String fullName) {
    final nameParts = fullName.trim().split(' ');
    return nameParts.isNotEmpty ? nameParts.first : fullName;
  }

  void _showEmployeesModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: EmployeesModalSheet(
          allEmployees: _allEmployees,
          selectedEmployeeIds: _selectedEmployeeIds,
          onEmployeesSelected: (Set<String> selectedIds) {
            setState(() {
              _selectedEmployeeIds = selectedIds;
            });
          },
        ),
      ),
    );
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
      AppCommonWidgets.defaultAlert(title: 'Объявление опубликовано');
      Navigator.pop(context);
      Get.back(result: true);
    } catch (e) {
      Get.snackbar('Ошибка', 'Не удалось создать объявление');
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
                            // Секция выбора сотрудников
                            Text(
                              'Для кого объявление',
                              style: AppTextStyles.titleSmall,
                            ),
                            AppSpacing.height8,

                            /// Поле для отображения выбранных сотрудников
                            GestureDetector(
                              onTap: _showEmployeesModal,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.white,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (_selectedEmployeeIds.isEmpty) ...[
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Выбрать сотрудников',
                                              style: AppTextStyles.titleSmall,
                                            ),
                                          ),
                                          const Icon(Icons.arrow_drop_down,
                                              color: Colors.grey),
                                        ],
                                      ),
                                    ],
                                    if (_selectedEmployeeIds.isNotEmpty) ...[
                                      Row(
                                        children: [
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: _showEmployeesModal,
                                              child: Text(
                                                _allEmployees
                                                    .where((employee) =>
                                                        _selectedEmployeeIds
                                                            .contains(employee
                                                                .userId))
                                                    .map((employee) =>
                                                        _getLastName(
                                                            employee.name))
                                                    .join(', '),
                                                style: AppTextStyles.titleSmall,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(Icons.arrow_drop_down,
                                              color: Colors.grey),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            AppSpacing.height24,
                            Text(
                              'Название объявления',
                              style: AppTextStyles.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _titleController,
                              decoration: InputDecoration(
                                hintText: 'Краткий текст',
                                hintStyle:
                                    AppTextStyles.bodyMedium,
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
                                style: AppTextStyles.titleSmall),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _fullTextController,
                              decoration: InputDecoration(
                                hintText: 'Описание',
                                hintStyle:
                                    AppTextStyles.bodyMedium,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppColors.primaryGrey, width: 1.0),
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
                            Text(
                              'Прикрепить файлы (в том числе фото)',
                              style: AppTextStyles.titleSmall,
                            ),
                            const SizedBox(height: 6),
                            // Кнопка добавления файла
                            AppButtons.secondaryButton(text: 'Добавить файл', icon:Iconsax.add_circle_copy , onPressed: pickFile),
                            const SizedBox(height: 8),
                            Container(
                              color: Colors.white,
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _submitForm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      _canSubmit ? AppColors.appPrimary : Colors.grey,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Опубликовать',style: AppTextStyles.buttonText, )
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }
}
