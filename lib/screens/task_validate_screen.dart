import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:task_tracker/models/task_validate.dart';
import 'package:task_tracker/services/request_operation.dart';
import 'package:task_tracker/services/task_provider.dart';

import '../models/task.dart';
import '../models/task_status.dart';

class TaskValidateScreen extends StatefulWidget {
  final Task task;

  const TaskValidateScreen({
    super.key,
    required this.task,
  });

  @override
  State<TaskValidateScreen> createState() => _TaskValidateScreenState();
}

class _TaskValidateScreenState extends State<TaskValidateScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();

  double _textFieldHeight = 60.0;
  List<String> attachments = [];
  String? audioMessage;
  List<String> videoMessage = [];
  bool isRecording = false;

  final AudioRecorder _audioRecorder = AudioRecorder();
  final ImagePicker _imagePicker = ImagePicker();
  final player = AudioPlayer();

  bool get _canSubmit {
    return _descriptionController.text.isNotEmpty ||
        attachments.isNotEmpty ||
        audioMessage != null ||
        videoMessage.isNotEmpty;
  }

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        attachments.add(result.files.single.path!);
      });
    }
  }

  Future<bool> _checkPermission() async {
    return await _audioRecorder.hasPermission();
  }

  Future<void> recordAudio() async {
    if (await _checkPermission()) {
      final dir = await getTemporaryDirectory(); // путь к временной папке
      final filePath =
          '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.m4a'; // имя файла

      await _audioRecorder.start(
        const RecordConfig(),
        path: filePath,
      );

      setState(() {
        isRecording = true;
        audioMessage = 'Запись...';
      });
    } else {
      setState(() {
        audioMessage = 'Нет разрешения на запись аудио';
      });
    }
  }

  Future<void> stopRecording() async {
    final path = await _audioRecorder.stop();
    if (path != null) {
      setState(() {
        isRecording = false;
        audioMessage = path;
      });
    }
  }

  Future<void> playAudio() async {
    if (audioMessage != null && audioMessage != 'Запись...') {
      await player.setFilePath(audioMessage!);
      player.play();
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
      if (attachments.contains(filePath)) {
        attachments.remove(filePath);
      } else if (videoMessage.contains(filePath)) {
        videoMessage.remove(filePath);
      } else if (audioMessage == filePath) {
        audioMessage = null;
      }
    });
  }

  TaskValidate _createValidate() {
    return TaskValidate(
      date: DateTime.now().toLocal(),
      taskId: widget.task.id,
      link: _linkController.text,
      description: _descriptionController.text,
      attachments: attachments,
      videoMessage: videoMessage,
      audioMessage: audioMessage,
      isDone: false,
    );
  }

  void _submitCorrection() async {
    if (!_canSubmit) return;

    try {
      final validate = _createValidate();
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);

      await RequestService().addTaskValidate(validate);
      await taskProvider.updateTaskStatus(
          widget.task, TaskStatus.completedUnderReview);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Задача отправлена на проверку')),
      );

      Navigator.pop(context, TaskStatus.completedUnderReview);
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
        title: const Text('Сдать задачу на проверку'),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text(
              'Ссылка',
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
                  controller: _linkController,
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
            const SizedBox(height: 16),
            const Text(
              'Описание',
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
            const SizedBox(height: 16),
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
            const Text(
              'Записать аудио сообщение',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: isRecording ? stopRecording : recordAudio,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black,
                side: const BorderSide(color: Colors.orange),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isRecording ? Icons.stop : Icons.mic,
                      color: Colors.black),
                  const SizedBox(width: 8),
                  Text(isRecording ? 'Остановить запись' : 'Записать аудио'),
                ],
              ),
            ),
            if (audioMessage != null) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: playAudio,
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
                    Icon(Icons.play_arrow, color: Colors.black),
                    SizedBox(width: 8),
                    Text('Прослушать запись'),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'Прикрепить видео',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _showMediaPicker,
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
                  Icon(Icons.video_library, color: Colors.black),
                  SizedBox(width: 8),
                  Text('Добавить видео'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (attachments.isNotEmpty ||
                videoMessage.isNotEmpty ||
                audioMessage != null) ...[
              const Text(
                'Добавленные файлы:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: attachments.length +
                      videoMessage.length +
                      (audioMessage != null ? 1 : 0),
                  itemBuilder: (context, index) {
                    String filePath;
                    bool isVideo = false;
                    bool isAudio = false;

                    if (index < attachments.length) {
                      filePath = attachments[index];
                      if (filePath.endsWith(".mp4") ||
                          filePath.endsWith(".mov")) {
                        isVideo = true;
                      }
                    } else if (index <
                        attachments.length + videoMessage.length) {
                      filePath = videoMessage[index - attachments.length];
                      isVideo = true;
                    } else {
                      filePath = audioMessage!;
                      isAudio = true;
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
    _linkController.dispose();
    super.dispose();
  }

  String _getAppBarTitle(TaskStatus status) {
    switch (status) {
      case TaskStatus.newTask:
      case TaskStatus.needExplanation:
        return "Задача поставлена плохо / некорректно";
      case TaskStatus.notRead:
        return "Причина разъяснения";
      case TaskStatus.needTicket:
        return "Письмо-решение";
      default:
        return "Письмо-решение";
    }
  }
}
