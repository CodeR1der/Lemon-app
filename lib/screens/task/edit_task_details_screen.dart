import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_tracker/models/task.dart';
import 'package:task_tracker/services/task_provider.dart';
import 'package:task_tracker/widgets/common/app_common.dart';

import '../../widgets/common/app_buttons.dart';

class EditTaskDetailsScreen extends StatefulWidget {
  final Task task;

  const EditTaskDetailsScreen({super.key, required this.task});

  @override
  State<EditTaskDetailsScreen> createState() => _EditTaskDetailsScreenState();
}

class _EditTaskDetailsScreenState extends State<EditTaskDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.task.taskName);
    _descriptionController =
        TextEditingController(text: widget.task.description);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveTask() async {
    if (_formKey.currentState!.validate()) {
      try {
        final updatedTask = widget.task.copyWith(
          taskName: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
        );

        final taskProvider = Provider.of<TaskProvider>(context, listen: false);
        await taskProvider.updateTaskFields(updatedTask);

        if (mounted) {
          Navigator.pop(context, updatedTask);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Задача обновлена')),
          );
        }
      } catch (e) {
        if (mounted) {}
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Редактировать задачу'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Название задачи',
                style: AppTextStyles.titleSmall,
              ),
              const SizedBox(height: 8),
              AppCommonWidgets.inputField(controller: _nameController, hintText: 'Введите название задачи'),//

              const SizedBox(height: 16),
              Text(
                'Описание задачи',
                style: AppTextStyles.titleSmall,
              ),
              const SizedBox(height: 8),
              AppCommonWidgets.inputField(controller: _descriptionController,maxLines: 5, hintText: 'Введите описание задачи'),//

              // TextFormField(
              //   controller: _descriptionController,
              //   maxLines: 5,
              //   decoration: const InputDecoration(
              //     border: OutlineInputBorder(),
              //     hintText: 'Введите описание задачи',
              //   ),
              //   validator: (value) {
              //     if (value == null || value.trim().isEmpty) {
              //       return 'Описание не может быть пустым';
              //     }
              //     return null;
              //   },
              // ),
            ],
          ),
        ),
      ),
      bottomSheet: Container(
        padding: EdgeInsets.only(
          top: 16,
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewPadding.bottom + 16,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppButtons.secondaryButton(
                text: 'Отмена', onPressed: () => Navigator.pop(context)),
            const SizedBox(height: 12),
            AppButtons.primaryButton(text: 'Сохранить', onPressed: _saveTask)
          ],
        ),
      ),
    );
  }
}
