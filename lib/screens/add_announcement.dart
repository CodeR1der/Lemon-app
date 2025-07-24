import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:task_tracker/models/announcement.dart';
import 'package:task_tracker/services/user_service.dart';

import '../services/announcement_operations.dart';

class CreateAnnouncementScreen extends StatefulWidget {
  static const routeName = '/create_announcement';

  const CreateAnnouncementScreen({super.key});

  @override
  State<CreateAnnouncementScreen> createState() => _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState extends State<CreateAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _fullTextController = TextEditingController();
  bool _isLoading = false;
  final List<String> _attachments = [];
  final String _companyId = UserService.to.currentUser!.companyId;


  bool get _canSubmit {
    return _titleController.text.isNotEmpty || _fullTextController.text.isNotEmpty;
  }

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        _attachments.add(result.files.single.path!);
      });
    }
  }
  @override
  void initState() {
    super.initState();
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

    setState(() {
      _isLoading = true;
    });

    try {
      final newAnnouncement = Announcement(
        title: _titleController.text.trim(),
        fullText: _fullTextController.text.trim(),
        date: DateTime.now(),
        readBy: [],
        attachments: _attachments,
        companyId: _companyId, id: '',
      );

      await AnnouncementService().createAnnouncement(newAnnouncement);
      Get.snackbar('Успех', 'Объявление успешно создано');
      Navigator.pop(context);
      Get.back(result: true); // Возвращаем результат, чтобы обновить главный экран
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: const Text('Объявление'),
      ),
      body: _companyId == null
          ? const Center(child: Text('Ошибка: идентификатор компании не указан'))
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
                    hintStyle:  Theme.of(context).textTheme.bodyMedium,
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
                Text(
                  'Подробное описание объявления',
                    style: Theme.of(context).textTheme.titleSmall
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _fullTextController,
                  decoration: InputDecoration(
                    hintText: 'Описание',
                    hintStyle:  Theme.of(context).textTheme.bodyMedium,
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
                Text('Прикрепить файлы (в том числе фото)',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 6),
                // Кнопка добавления файла
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
                      Icon(Iconsax.add_circle_copy),
                      SizedBox(width: 8),
                      Text('Добавить файл'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

      ),
      bottomSheet: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
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