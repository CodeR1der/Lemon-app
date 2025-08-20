import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
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

class TicketScreen extends StatefulWidget {
  final Task task;
  final Correction? prevCorrection;
  final TaskValidate? validate;

  const TicketScreen({
    super.key,
    required this.task,
    this.prevCorrection,
    this.validate,
  });

  @override
  State<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  double _textFieldHeight = 60.0;
  final List<String> _attachments = [];
  List<String> videoMessage = [];
  bool isRecording = false;

  final AudioRecorder _audioRecorder = AudioRecorder();
  final ImagePicker _imagePicker = ImagePicker();
  final player = AudioPlayer();

  bool get _canSubmit {
    return _descriptionController.text.isNotEmpty ||
        _attachments.isNotEmpty ||
        videoMessage.isNotEmpty;
  }

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        _attachments.add(result.files.single.path!);
      });
    }
  }

  Future<void> _showMediaPicker() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.videocam),
            title: const Text('Записать видео'),
            onTap: () async {
              Navigator.pop(context);
              await _recordVideo();
            },
          ),
          ListTile(
            leading: const Icon(Icons.video_library),
            title: const Text('Выбрать из галереи'),
            onTap: () async {
              Navigator.pop(context);
              await pickVideo();
            },
          ),
          ListTile(
            leading: const Icon(Icons.cancel),
            title: const Text('Отмена'),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Future<void> _recordVideo() async {
    final XFile? recordedFile =
        await _imagePicker.pickVideo(source: ImageSource.camera);
    if (recordedFile != null) {
      setState(() {
        videoMessage.add(recordedFile.path);
      });
    }
  }

  Future<void> pickVideo() async {
    final XFile? pickedFile =
        await _imagePicker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        videoMessage.add(pickedFile.path);
      });
    }
  }

  void removeAttachment(String filePath) {
    setState(() {
      if (_attachments.contains(filePath)) {
        _attachments.remove(filePath);
      } else if (videoMessage.contains(filePath)) {
        videoMessage.remove(filePath);
      }
    });
  }

  Correction _createCorrection() {
    return Correction(
      date: DateTime.now().toLocal(),
      taskId: widget.task.id,
      description: _descriptionController.text,
      attachments: _attachments,
      videoMessage: videoMessage,
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

      if (task.status == TaskStatus.needTicket) {
        await RequestService()
            .updateCorrection(widget.prevCorrection!..isDone = true);
      }
      await taskProvider.updateTaskStatus(task, TaskStatus.revision);

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
              'Решение',
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
            const Text(
              'Добавить файлы по задаче (в том числе фото)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: pickFile,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black,
                side: const BorderSide(color: Colors.orange),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
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
            const SizedBox(height: 16),
            if (_attachments.isNotEmpty || videoMessage.isNotEmpty) ...[
              const Text(
                'Добавленные файлы:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _attachments.length + videoMessage.length,
                  itemBuilder: (context, index) {
                    String filePath;
                    bool isVideo = false;
                    bool isAudio = false;

                    if (index < _attachments.length) {
                      filePath = _attachments[index];
                      if (filePath.endsWith(".mp4") ||
                          filePath.endsWith(".mov")) {
                        isVideo = true;
                      }
                    } else {
                      filePath = videoMessage[index - _attachments.length];
                      isVideo = true;
                    }

                    return ListTile(
                      leading: isVideo
                          ? const Icon(Icons.video_library, color: Colors.red)
                          : isAudio
                              ? const Icon(Icons.audiotrack, color: Colors.blue)
                              : Image.file(
                                  File(filePath),
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                  ),
                                ),
                      title: Text(filePath.split('/').last),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => removeAttachment(filePath),
                      ),
                    );
                  },
                ),
              ),
            ],
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
    return "Письмо-решение";
  }
}
