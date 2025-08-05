import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_tracker/models/task.dart';
import 'package:task_tracker/services/task_provider.dart';

class EditTaskDetailsScreen extends StatefulWidget {
  final Task task;

  const EditTaskDetailsScreen({super.key, required this.task});

  @override
  _EditTaskDetailsScreenState createState() => _EditTaskDetailsScreenState();
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
        await taskProvider.updateTask(updatedTask);

        if (mounted) {
          Navigator.pop(context, updatedTask);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Задача обновлена')),
          );
        }
      } catch (e) {
        if (mounted) {
        }
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
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Введите название задачи',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Название не может быть пустым';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Описание задачи',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Введите описание задачи',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Описание не может быть пустым';
                  }
                  return null;
                },
              ),
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
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Отмена',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveTask,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Сохранить',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
