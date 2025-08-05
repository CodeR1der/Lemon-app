import 'dart:io';

import 'package:file_picker/file_picker.dart'; // Для выбора файлов
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart'; // Для выбора видео
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart'; // Для записи аудио
import 'package:task_tracker/task_screens/employees_selection_screen.dart';
import 'package:task_tracker/widgets/common/app_buttons.dart';

import '../models/task.dart'; // Импортируйте ваш класс Task

class AddedFilesScreen extends StatefulWidget {
  final Task taskData;

  const AddedFilesScreen(this.taskData, {super.key});

  @override
  AddedFilesScreenState createState() => AddedFilesScreenState();
}

class AddedFilesScreenState extends State<AddedFilesScreen> {
  List<String> attachments = [];
  String? audioMessage;
  List<String> videoMessage = [];
  bool isRecording = false;

  final AudioRecorder _audioRecorder = AudioRecorder();
  final ImagePicker _imagePicker = ImagePicker();
  final player = AudioPlayer();

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        attachments.add(result.files.single.path!);
        widget.taskData.addAttachment(result.files.single.path!);
      });
    }
    //проверить функцию создания фото
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
        widget.taskData.setAudioMessage(path);
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
        widget.taskData.setVideoMessage(recordedFile.path);
      });
    }
  }

  Future<void> pickVideo() async {
    final XFile? pickedFile =
        await _imagePicker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        videoMessage.add(pickedFile.path);
        widget.taskData.setVideoMessage(pickedFile.path);
      });
    }
    //не добавляется video_message
  }

  void removeAttachment(String filePath) {
    setState(() {
      if (attachments.contains(filePath)) {
        attachments.remove(filePath);
        widget.taskData.removeAttachment(filePath);
      } else {
        videoMessage.remove(filePath);
        widget.taskData.removeVideoMessage(filePath);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Материалы для выполнения задачи'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Добавить файлы по задаче (в том числе фото)',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 8),
            AppButtons.addFilesButton(
                text: 'Добавить файл',
                onPressed: pickFile,
                icon: Iconsax.add_circle_copy),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Записать аудио сообщение',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 8),
            AppButtons.addFilesButton(
                text: isRecording ? 'Остановить запись' : 'Записать аудио',
                onPressed: isRecording ? stopRecording : recordAudio,
                icon: isRecording ? Iconsax.stop_circle_copy : Iconsax.microphone_2_copy,),
            const SizedBox(height: 16),
            AppButtons.addFilesButton(
              text: 'Прослушать запись',
              onPressed: playAudio,
              icon: Iconsax.play_circle_copy),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Прикрепить видео',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 8),
            AppButtons.addFilesButton(
              text: 'Добавить видео',
              onPressed: _showMediaPicker,
              icon: Iconsax.video_play_copy),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Добавленные файлы:',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 8),
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
            const Spacer(),
            AppButtons.primaryButton(text: 'Дальше', onPressed: () {
              widget.taskData.attachments = attachments;
              widget.taskData.audioMessage = audioMessage;
              widget.taskData.videoMessage = videoMessage;

              // Иначе идем на экран выбора сотрудников
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      EmployeeSelectionScreen(widget.taskData),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
