import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_tracker/models/task_role.dart';
import 'package:task_tracker/screens/change_executer_screen.dart';
import 'package:task_tracker/screens/tasks_screen.dart';
import 'package:task_tracker/services/user_service.dart';

import '../models/correction.dart';
import '../models/task.dart';
import '../models/task_status.dart';
import '../services/request_operation.dart';
import '../services/task_provider.dart';
import '../task_screens/TaskDescriptionTab.dart';
import 'choose_task_deadline_screen.dart';

class CorrectionDetailsScreen extends StatelessWidget {
  // Добавлено наследование
  final Correction correction;
  final Task task;
  final TaskRole role;

  const CorrectionDetailsScreen(
      {super.key,
      required this.correction,
      required this.task,
      required this.role}); // Добавлен const конструктор

  bool _isImage(String fileName) {
    return fileName.endsWith('.jpg') ||
        fileName.endsWith('.jpeg') ||
        fileName.endsWith('.png');
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
      // Добавлен Scaffold для правильной структуры экрана
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(correction.status == TaskStatus.needTicket
            ? "Письмо-решение"
            : 'Правки по задаче'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (correction.status == TaskStatus.needTicket) ...[
              Text(
                'Решение',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ] else if (correction.status == TaskStatus.overdue) ...[
              Text(
                'Объяснительная',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ] else ...[
              // Описание задачи
              Text(
                'Описание ошибки',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              correction.description ?? 'Нет описания',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            // Фотографии
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Фотографии',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${correction.attachments?.where((file) => _isImage(file)).length ?? 0}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (correction.attachments
                    ?.where((file) => _isImage(file))
                    .isEmpty ??
                true)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Нет прикрепленных фотографий'),
              )
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
                          color: Colors.grey.shade100,
                          child: Image.network(
                            RequestService().getAttachment(photo),
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
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

            const SizedBox(height: 12),
          ],
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
          // Первая кнопка
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final taskProvider = Provider.of<TaskProvider>(context, listen: false);

                if (correction.status == TaskStatus.needTicket) {
                  await taskProvider.updateTaskStatus(task, TaskStatus.notRead);
                  RequestService().updateCorrection(correction..isDone = true);
                } else {
                  await taskProvider.updateTaskStatus(task, TaskStatus.newTask);
                }

                Navigator.pop(
                  context,
                );
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Принять',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Вторая кнопка
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (correction.status == TaskStatus.needTicket) {
                  task.changeStatus(TaskStatus.needExplanation);
                  RequestService().updateCorrection(correction..isDone = true);
                  RequestService()
                      .updateCorrectionByStatus(task.id, TaskStatus.notRead);
                }
                Navigator.pop(
                  context,
                );
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                correction.status == TaskStatus.needTicket
                    ? 'Не принять'
                    : 'Отредактировать задачу',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8), // Дополнительный отступ снизу
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
            // Первая кнопка
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  task.changeStatus(TaskStatus.extraTime);
                  RequestService().updateCorrection(correction..isDone = true);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TaskCompletionPage(task: task),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Дать дополнительное время',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Вторая кнопка
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChangeExecuterScreen(task: task,correction: correction),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey,
                  side: const BorderSide(color: Colors.grey, width: 1),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text("Заменить исполнителя",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  task.changeStatus(TaskStatus.completed);
                  RequestService().updateCorrection(correction..isDone = true);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TasksScreen(user: UserService.to.currentUser!,),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.grey,
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text("Завершить задачу и сдать в архив",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ] else ...[
            // Первая кнопка
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  task.changeStatus(TaskStatus.notRead);
                  RequestService().updateCorrection(correction..isDone = true);
                  Navigator.pop(
                    context,
                  );
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Принять',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Вторая кнопка
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (correction.status == TaskStatus.needTicket) {
                    task.changeStatus(TaskStatus.needExplanation);
                    RequestService()
                        .updateCorrection(correction..isDone = true);
                    RequestService()
                        .updateCorrectionByStatus(task.id, TaskStatus.notRead);
                  } else {
                    task.changeStatus(TaskStatus.revision);
                  }
                  Navigator.pop(
                    context,
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey,
                  side: const BorderSide(color: Colors.grey, width: 1),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  correction.status == TaskStatus.needTicket
                      ? "Не принять"
                      : 'Правки выполнены некорректно',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8), // Дополнительный отступ снизу
          ]
        ],
      ),
    );
  }
}
