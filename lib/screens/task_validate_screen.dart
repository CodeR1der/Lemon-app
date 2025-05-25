import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import 'package:task_tracker/models/task_validate.dart';
import 'package:task_tracker/services/request_operation.dart';

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
    return _descriptionController.text.isNotEmpty || attachments.isNotEmpty;
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
      await _audioRecorder.start(const RecordConfig(), path: '');
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
        widget.task.setAudioMessage(path);
      });
    }
  }

  Future<void> playAudio() async {
    if (audioMessage != null) {
      await player.setFilePath(audioMessage!);
      player.play();
    }
  }

  // Метод для отображения меню с действиями
  Future<void> _showMediaPicker() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => Wrap(
        children: [
          // Запись видео
          ListTile(
            leading: const Icon(Icons.videocam),
            title: const Text('Записать видео'),
            onTap: () async {
              Navigator.pop(context); // Закрыть меню
              await _recordVideo();
            },
          ),
          // Выбор видео из галереи
          ListTile(
            leading: const Icon(Icons.video_library),
            title: const Text('Выбрать из галереи'),
            onTap: () async {
              Navigator.pop(context); // Закрыть меню
              await pickVideo();
            },
          ),
          // Отмена
          ListTile(
            leading: const Icon(Icons.cancel),
            title: const Text('Отмена'),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  // Метод для записи видео
  Future<void> _recordVideo() async {
    final XFile? recordedFile =
        await _imagePicker.pickVideo(source: ImageSource.camera);
    if (recordedFile != null) {
      setState(() {
        videoMessage.add(recordedFile.path);
        widget.task.setVideoMessage(recordedFile.path);
      });
    }
  }

  Future<void> pickVideo() async {
    final XFile? pickedFile =
        await _imagePicker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        videoMessage.add(pickedFile.path);
        widget.task.setVideoMessage(pickedFile.path);
      });
    }
    //не добавляется video_message
  }

  void removeAttachment(String filePath) {
    setState(() {
      if (attachments.contains(filePath)) {
        attachments.remove(filePath);
        widget.task.removeAttachment(filePath);
      } else {
        videoMessage.remove(filePath);
        widget.task.removeVideoMessage(filePath);
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

      await RequestService().addTaskValidate(validate);

      await widget.task.changeStatus(TaskStatus.completedUnderReview);

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
        title: Text(_getAppBarTitle(widget.task.status)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text(
            'Ссылка',
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

          const Text(
            'Описание',
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
                  )..layout(maxWidth: MediaQuery.of(context).size.width - 56);

                  setState(() {
                    _textFieldHeight = textPainter.size.height + 24;
                    if (_textFieldHeight < 60) _textFieldHeight = 60;
                  });
                },
              ),
            ),
          ),

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
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Записать аудио сообщение',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: isRecording ? stopRecording : recordAudio,
            icon:
                Icon(isRecording ? Icons.stop : Icons.mic, color: Colors.black),
            label: Text(isRecording ? 'Остановить запись' : 'Записать аудио'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              side: const BorderSide(color: Colors.orange),
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: playAudio,
            icon: const Icon(Icons.play_arrow, color: Colors.black),
            label: const Text('Прослушать запись'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              side: const BorderSide(color: Colors.orange),
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Прикрепить видео',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _showMediaPicker,
            icon: const Icon(Icons.video_library, color: Colors.black),
            label: const Text('Добавить видео'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              side: const BorderSide(color: Colors.orange),
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: attachments.length + videoMessage.length,
              itemBuilder: (context, index) {
                String filePath;
                bool isVideo = false;

                if (index < attachments.length) {
                  filePath = attachments[index];
                  if (filePath.endsWith(".mp4")) {
                    isVideo = true;
                  }
                } else {
                  filePath = videoMessage[index - attachments.length];
                  isVideo = true;
                }

                return ListTile(
                  leading: isVideo
                      ? const Icon(Icons.video_library, color: Colors.red)
                      : Image.file(File(filePath),
                          width: 50, height: 50, fit: BoxFit.cover),
                  title: Text(filePath.split('/').last),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => removeAttachment(filePath),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          // Секция с прикрепленными файлами
          if (attachments.isNotEmpty) ...[
            const Text(
              'Прикрепленные файлы:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: attachments.map((file) {
                return Chip(
                  label: Text(file.split('/').last),
                  onDeleted: () {
                    setState(() {
                      attachments.remove(file);
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                  );
                  widget.task.changeStatus(TaskStatus.completedUnderReview);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Отправить'),
              ),
            ),
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
    switch (status) {
      case TaskStatus.newTask || TaskStatus.needExplanation:
        return "Задача поставлена плохо / некорректно";
      case TaskStatus.needTicket:
        return "Письмо-решение";
      case TaskStatus.notRead:
        return "Причина разъяснения";
      case TaskStatus.needTicket:
        return "Письмо-решение";
      default:
        return "Письмо-решение";
    }
  }
}
