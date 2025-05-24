import 'package:flutter/material.dart';

import '../models/correction.dart';
import '../models/task.dart';
import '../models/task_status.dart';
import '../services/correction_operation.dart';
import '../task_screens/TaskDescriptionTab.dart';
import '../task_screens/taskTitleScreen.dart';

class CorrectionDetailsScreen extends StatelessWidget {  // Добавлено наследование
  final Correction correction;
  final Task task;
  const CorrectionDetailsScreen({super.key, required this.correction, required this.task});  // Добавлен const конструктор

  bool _isImage(String fileName) {
    return fileName.endsWith('.jpg') ||
        fileName.endsWith('.jpeg') ||
        fileName.endsWith('.png');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(  // Добавлен Scaffold для правильной структуры экрана
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Описание ошибок'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Описание задачи
            Text(
              'Описание ошибки',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

            if (correction.attachments?.where((file) => _isImage(file)).isEmpty ?? true)
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
                itemCount: correction.attachments!.where((file) => _isImage(file)).length,
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
                            CorrectionService().getAttachment(photo),
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
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
        bottomSheet: Container(
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
                  onPressed: () {
                    task.changeStatus(TaskStatus.newTask);
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
                    // Другое действие
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
                  child: const Text(
                    'Отредактировать задачу',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8), // Дополнительный отступ снизу
            ],
          ),
        )
    );
  }

  void _openPhotoGallery(
      BuildContext context, int initialIndex, List<String> files) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoGalleryScreen(
          photos: files.map(CorrectionService().getAttachment).toList(),
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}