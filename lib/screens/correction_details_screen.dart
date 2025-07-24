import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get_thumbnail_video/index.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:provider/provider.dart';
import 'package:task_tracker/models/task_role.dart';
import 'package:task_tracker/screens/add_extra_time_screen.dart';
import 'package:task_tracker/screens/change_executer_screen.dart';
import 'package:task_tracker/services/task_operations.dart';

import '../models/correction.dart';
import '../models/task.dart';
import '../models/task_status.dart';
import '../services/request_operation.dart';
import '../services/task_provider.dart';
import '../task_screens/TaskDescriptionTab.dart';

class CorrectionDetailsScreen extends StatelessWidget {
  final Correction correction;
  final Task task;
  final TaskRole role;

  const CorrectionDetailsScreen({
    super.key,
    required this.correction,
    required this.task,
    required this.role,
  });

  bool _isImage(String fileName) {
    return fileName.endsWith('.jpg') ||
        fileName.endsWith('.jpeg') ||
        fileName.endsWith('.png');
  }

  bool _isVideo(String fileName) {
    return fileName.endsWith('.mp4') || fileName.endsWith('.mov');
  }

  Future<Uint8List?> _generateThumbnail(String videoUrl) async {
    return await VideoThumbnail.thumbnailData(
      video: videoUrl,
      imageFormat: ImageFormat.PNG,
      maxWidth: 128,
      quality: 75,
    );
  }

  void _showEditDescriptionDialog(BuildContext context) {
    final TextEditingController _descriptionController =
        TextEditingController(text: task.description);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(task.taskName),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Описание задачи',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newDescription = _descriptionController.text.trim();
                if (newDescription.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Описание не может быть пустым')),
                  );
                  return;
                }

                try {
                  final taskProvider =
                      Provider.of<TaskProvider>(context, listen: false);
                  final updatedTask =
                      task.copyWith(description: newDescription);
                  await taskProvider.updateTask(updatedTask);
                  await TaskService().updateTask(updatedTask);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Описание обновлено')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка обновления: $e')),
                  );
                }
              },
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget? bottomSheet;

    switch (role) {
      case TaskRole.communicator:
        bottomSheet = _buildCommunicatorActions(context);
        break;
      case TaskRole.creator:
        bottomSheet = _buildCreatorActions(context);
        break;
      case TaskRole.executor:
        bottomSheet = _buildCreatorActions(context);
        break;
      case TaskRole.none:
        bottomSheet = null;
        break;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(correction.status == TaskStatus.needTicket
            ? "Письмо-решение"
            : 'Правки по задаче'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (correction.status == TaskStatus.needTicket) ...[
                Text(
                  'Решение',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ] else if (correction.status == TaskStatus.overdue) ...[
                Text(
                  'Объяснительная',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ] else ...[
                Text(
                  'Описание ошибки',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                correction.description ?? 'Нет описания',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text('Фотографии',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F9F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${correction.attachments?.where((file) => _isImage(file)).length ?? 0}',
                      style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (correction.attachments
                      ?.where((file) => _isImage(file))
                      .isEmpty ??
                  true)
                const Text('Нет фотографий')
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                  ),
                  itemCount: correction.attachments!
                      .where((file) => _isImage(file))
                      .length,
                  itemBuilder: (context, index) {
                    final photo = correction.attachments!
                        .where((file) => _isImage(file))
                        .toList()[index];
                    return GestureDetector(
                      onTap: () => _openPhotoGallery(
                        context,
                        index,
                        correction.attachments!
                            .where((file) => _isImage(file))
                            .toList(),
                      ),
                      child: Hero(
                        tag: 'correction_photo_$index',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Container(
                            color: Colors.white,
                            child: Image.network(
                              RequestService().getAttachment(photo),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.broken_image, size: 32),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
      bottomSheet: bottomSheet,
    );
  }

  void _openPhotoGallery(
      BuildContext context, int initialIndex, List<String> files) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoGalleryScreen(
          photos: files.map(RequestService().getAttachment).toList(),
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  void _openVideoGallery(
      BuildContext context, int initialIndex, List<String> videoUrls) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoGalleryScreen(
          videoUrls: videoUrls.map(RequestService().getAttachment).toList(),
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  Widget? _buildCreatorActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (task.status == TaskStatus.overdue) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context, task);
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Ознакомился',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final taskProvider =
                      Provider.of<TaskProvider>(context, listen: false);

                  if (correction.status == TaskStatus.needTicket) {
                    await taskProvider.updateTaskStatus(
                        task, TaskStatus.notRead);
                    RequestService()
                        .updateCorrection(correction..isDone = true);
                  } else {
                    await taskProvider.updateTaskStatus(
                        task, TaskStatus.newTask);
                  }

                  Navigator.pop(context, task);
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Принять',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (correction.status == TaskStatus.needTicket) {
                    final taskProvider =
                        Provider.of<TaskProvider>(context, listen: false);
                    taskProvider.updateTaskStatus(
                        task, TaskStatus.needExplanation);
                    RequestService()
                        .updateCorrection(correction..isDone = true);
                    RequestService()
                        .updateCorrectionByStatus(task.id, TaskStatus.notRead);
                  } else {
                    _showEditDescriptionDialog(context);
                  }
                  Navigator.pop(context, task);
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.grey,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  correction.status == TaskStatus.needTicket
                      ? 'Не принять'
                      : 'Отредактировать задачу',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ]
        ],
      ),
    );
  }

  Widget? _buildCommunicatorActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (task.status == TaskStatus.overdue) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddExtraTimeScreen(
                          task: task, correction: correction),
                    ),
                  ).then((result) {
                    if (result != null && result is Map<String, dynamic>) {
                      final updatedTask = result['task'] as Task;
                      Navigator.pop(context, updatedTask);
                    } else {
                      Navigator.pop(context, task);
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Дать дополнительное время',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChangeExecuterScreen(
                          task: task, correction: correction),
                    ),
                  ).then((result) {
                    if (result != null && result is Map<String, dynamic>) {
                      final updatedTask = result['task'] as Task;
                      Navigator.pop(context, updatedTask);
                    } else {
                      Navigator.pop(context, task);
                    }
                  });
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey,
                  side: const BorderSide(color: Colors.grey, width: 1),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  "Заменить исполнителя",
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final taskProvider =
                      Provider.of<TaskProvider>(context, listen: false);
                  taskProvider.updateTaskStatus(task, TaskStatus.completed);
                  RequestService().updateCorrection(correction..isDone = true);
                  Navigator.pop(context, task);
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.grey,
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  "Завершить задачу и сдать в архив",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final taskProvider =
                      Provider.of<TaskProvider>(context, listen: false);
                  taskProvider.updateTaskStatus(task, TaskStatus.notRead);
                  RequestService().updateCorrection(correction..isDone = true);
                  Navigator.pop(context, task);
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Принять',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final taskProvider =
                      Provider.of<TaskProvider>(context, listen: false);
                  if (correction.status == TaskStatus.needTicket) {
                    taskProvider.updateTaskStatus(
                        task, TaskStatus.needExplanation);
                    RequestService()
                        .updateCorrection(correction..isDone = true);
                    RequestService()
                        .updateCorrectionByStatus(task.id, TaskStatus.notRead);
                  } else {
                    taskProvider.updateTaskStatus(task, TaskStatus.revision);
                  }
                  Navigator.pop(context, task);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey,
                  side: const BorderSide(color: Colors.grey, width: 1),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  correction.status == TaskStatus.needTicket
                      ? "Не принять"
                      : 'Правки выполнены некорректно',
                  style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ]
        ],
      ),
    );
  }
}
