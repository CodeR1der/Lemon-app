import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:task_tracker/services/correction_operation.dart';

import '../models/correction.dart';
import '../models/task.dart';
import '../models/task_status.dart';

class CorrectionScreen extends StatefulWidget {
  final Task task;

  const CorrectionScreen({
    super.key,
    required this.task,
  });

  @override
  State<CorrectionScreen> createState() => _CorrectionScreenState();
}

class _CorrectionScreenState extends State<CorrectionScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  double _textFieldHeight = 60.0;
  List<String> _attachments = [];

  bool get _canSubmit {
    return _descriptionController.text.isNotEmpty || _attachments.isNotEmpty;
  }

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        _attachments.add(result.files.single.path!);
      });
    }
  }

  Correction _createCorrection() {
    return Correction(
        date: DateTime.now(),
        taskId: widget.task.id,
        description: _descriptionController.text,
        attachments: _attachments,
        isDone: false,
        status: widget.task.status);
  }

  void _submitCorrection() async {
    if (!_canSubmit) return;

    try {
      final correction = _createCorrection();

      await CorrectionService().addCorrection(correction);

      if (widget.task.status == TaskStatus.newTask) {
        await widget.task.changeStatus(TaskStatus.revision);
      } else if (widget.task.status == TaskStatus.notRead) {
        await widget.task.changeStatus(TaskStatus.needExplanation);
      }
        // 4. Показываем уведомление
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Задача отправлена на доработку')),
      );

      // 5. Закрываем экран и возвращаем результат
      Navigator.pop(
        context,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Задача поставлена плохо / некорректно'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Описание ошибок
          const Text(
            'Описание ошибок в постановке задачи',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),

          // Поле ввода описания
          Container(
            constraints: BoxConstraints(
              minHeight: _textFieldHeight,
            ),
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
                  hintText:
                      'Опишите подробно, что именно сделано неправильно...',
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
                  )..layout(maxWidth: MediaQuery.of(context).size.width - 56);

                  setState(() {
                    _textFieldHeight = textPainter.size.height + 24;
                    if (_textFieldHeight < 60) _textFieldHeight = 60;
                  });
                },
              ),
            ),
          ),

          if (widget.task.status == TaskStatus.newTask) ...[
            const SizedBox(height: 24),
            // Секция с прикрепленными файлами
            if (_attachments.isNotEmpty) ...[
              const Text(
                'Прикрепленные файлы:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _attachments.map((file) {
                  return Chip(
                    label: Text(file.split('/').last),
                    onDeleted: () {
                      setState(() {
                        _attachments.remove(file);
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Добавление файлов
            const Text(
              'Добавить файлы',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),

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
            const SizedBox(height: 24),
          ]
        ]),
      ),
      bottomSheet: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _canSubmit ? _submitCorrection : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _canSubmit ? Colors.orange : Colors.grey,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Отправить на доработку'),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }
}
