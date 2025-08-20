import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:task_tracker/models/task_validate.dart';
import 'package:task_tracker/services/request_operation.dart';

import '../../models/correction.dart';
import '../../models/task.dart';
import '../../models/task_status.dart';
import '../../services/task_provider.dart';

class ExplanationScreen extends StatefulWidget {
  final Task task;
  final Correction? prevCorrection;
  final TaskValidate? validate;

  const ExplanationScreen({
    super.key,
    required this.task,
    this.prevCorrection,
    this.validate,
  });

  @override
  State<ExplanationScreen> createState() => _ExplanationScreenState();
}

class _ExplanationScreenState extends State<ExplanationScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  double _textFieldHeight = 60.0;

  final AudioRecorder _audioRecorder = AudioRecorder();
  final ImagePicker _imagePicker = ImagePicker();
  final player = AudioPlayer();

  bool get _canSubmit {
    return _descriptionController.text.isNotEmpty;
  }

  Correction _createCorrection() {
    return Correction(
      date: DateTime.now().toLocal(),
      taskId: widget.task.id,
      description: _descriptionController.text,
      isDone: false,
      status: widget.task.status,
    );
  }

  void _submitCorrection() async {
    if (!_canSubmit) return;

    try {
      final correction = _createCorrection();
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      final task = widget.task;

      await RequestService().addCorrection(correction);

      Navigator.pop(context);
      await taskProvider.updateTaskStatus(task, TaskStatus.needExplanation);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Задача отправлена на доработку')),
      );

      Navigator.pop(context);
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(_getAppBarTitle(widget.task.status)),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text(
              'Описание ошибок в постановке задачи',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Container(
              constraints: BoxConstraints(minHeight: _textFieldHeight),
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
                          text: text, style: const TextStyle(fontSize: 16)),
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
            const SizedBox(height: 24),
          ]),
        ),
      ),
      bottomSheet: Container(
        color: Colors.white,
        padding: EdgeInsets.only(
          top: 30,
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewPadding.bottom + 16,
        ),
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _canSubmit ? _submitCorrection : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _canSubmit ? Colors.orange : Colors.grey,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Отправить'),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  String _getAppBarTitle(TaskStatus status) {
    return "Причина разъяснения";
  }
}
