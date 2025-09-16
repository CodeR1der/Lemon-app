import 'dart:typed_data';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:get_thumbnail_video/index.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:provider/provider.dart';
import 'package:task_tracker/services/control_point_operations.dart';
import 'package:task_tracker/services/task_operations.dart';
import 'package:task_tracker/services/user_service.dart';
import 'package:task_tracker/widgets/common/app_common.dart';
import 'package:video_player/video_player.dart';

import '../models/task.dart';
import '../models/task_role.dart';
import '../models/task_status.dart';
import '../services/task_provider.dart';
import '../widgets/custom_player.dart';
import '../widgets/task_layout/task_layout_builder.dart';

class TaskDescriptionTab extends StatefulWidget {
  final Task task;

  const TaskDescriptionTab({super.key, required this.task});

  @override
  State<TaskDescriptionTab> createState() => _TaskDescriptionTabState();
}

class _TaskDescriptionTabState extends State<TaskDescriptionTab> {
  final TaskService _database = TaskService();
  TaskStatus? _displayStatus;
  bool _isLoadingStatus = true; //
  late Task _currentTask;

  @override
  void initState() {
    super.initState();
    _currentTask = widget.task;
    _determineDisplayStatus();
  }

  @override
  void dispose() {
    // Очистка ресурсов если нужно
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Подписываемся на изменения задачи из провайдера
    final taskProvider = Provider.of<TaskProvider>(context, listen: true);
    final updatedTask = taskProvider.getTask(widget.task.id);

    if (updatedTask != null && updatedTask != _currentTask) {
      setState(() {
        _currentTask = updatedTask;
        // Переопределяем статус если задача обновилась
        _determineDisplayStatus();
      });
    }
  }

  Future<void> _determineDisplayStatus() async {
    final position = _getPosition();
    print('TaskDescriptionTab: Пользователь в роли: $position');
    print('TaskDescriptionTab: Статус задачи: ${_currentTask?.status}');

    if (position == "Коммуникатор" &&
        _currentTask?.status == TaskStatus.atWork) {
      print(
          'TaskDescriptionTab: Проверяем контрольные точки для коммуникатора');
      final controlPointService = ControlPointService();
      final hasUnclosedControlPoints =
          await controlPointService.hasUnclosedControlPoints(_currentTask!.id);
      print(
          'TaskDescriptionTab: Есть незакрытые контрольные точки: $hasUnclosedControlPoints');

      setState(() {
        _displayStatus = hasUnclosedControlPoints
            ? TaskStatus.controlPoint
            : TaskStatus.atWork;
        _isLoadingStatus = false;
      });
    } else {
      print('TaskDescriptionTab: Используем реальный статус задачи');
      setState(() {
        _displayStatus = _currentTask?.status;
        _isLoadingStatus = false;
      });
    }
  }

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

  String _getPosition() {
    if (_currentTask.team.creatorId.userId ==
        UserService.to.currentUser!.userId) {
      return "Постановщик";
    } else if (_currentTask.team.communicatorId.userId ==
        UserService.to.currentUser!.userId) {
      return "Коммуникатор";
    } else if (_currentTask.team.teamMembers
        .any((member) => member.userId == UserService.to.currentUser!.userId)) {
      return "Исполнитель";
    } else if (_currentTask.team.observerId?.userId ==
        UserService.to.currentUser!.userId) {
      return "Наблюдатель";
    } else {
      return "Наблюдатель";
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: true);
    final currentTask = taskProvider.getTask(widget.task.id) ?? _currentTask;

    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Статус', style: AppTextStyles.titleSmall),
            const SizedBox(height: 4),
            _isLoadingStatus
                ? Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBEDF0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 6),
                        Text('Загрузка...', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  )
                : Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBEDF0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          StatusHelper.getStatusIcon(_displayStatus!),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          StatusHelper.displayName(_displayStatus!),
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              // Добавляем отступы по бокам
              child: Divider(),
            ),

            // Проект
            Text('Проект', style: AppTextStyles.titleSmall),
            const SizedBox(height: 4),
            Text(_currentTask.project?.name ?? 'Не указан',
                style: AppTextStyles.bodyMedium),
            const SizedBox(height: 16),

            if(_currentTask.number != null)...[
              // Название задачи
              Text('Номер задачи',
                  style: AppTextStyles.titleSmall),
              const SizedBox(height: 4),
              Text(_currentTask.number.toString() ,
                  style: AppTextStyles.bodyMedium),
              const SizedBox(height: 16),
            ],

            // Название задачи
            Text('Название задачи',
                style: AppTextStyles.titleSmall),
            const SizedBox(height: 4),
            Text(_currentTask.taskName,
                style: AppTextStyles.bodyMedium),
            const SizedBox(height: 16),

            // Описание задачи
            Text('Описание задачи',
                style: AppTextStyles.titleSmall),
            const SizedBox(height: 4),
            Text(_currentTask.description,
                style: AppTextStyles.bodyMedium),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Фотографии
                Text('Фотографии',
                    style: AppTextStyles.titleSmall),
                const SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Color(0xFFF9F9F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _currentTask.attachments.length.toString(),
                    style: AppTextStyles.bodyMedium
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _currentTask.attachments.where((file) => _isImage(file)).isNotEmpty
                ? GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 8.0,
                    ),
                    itemCount: _currentTask.attachments
                        .where((file) => _isImage(file))
                        .length,
                    itemBuilder: (context, index) {
                      final photo = _currentTask.attachments
                          .where((file) => _isImage(file))
                          .toList()[index];
                      return GestureDetector(
                        onTap: () => _openPhotoGallery(
                          context,
                          index,
                          _currentTask.attachments
                              .where((file) => _isImage(file))
                              .toList(),
                        ),
                        child: Hero(
                          tag: 'photo_$index',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Container(
                              color: Colors.white, // Белый фон для изображения
                              child: Image.network(
                                _database.getTaskAttachment(photo),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  color: Colors.grey.shade200,
                                  child:
                                      const Icon(Icons.broken_image, size: 32),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  )
                : const Text('Нет фотографий', style: AppTextStyles.bodyMedium,),
            const SizedBox(height: 16),

            // Аудиозаписи
            Text(
              'Аудиозаписи ',
              style: AppTextStyles.titleSmall,
            ),
            const SizedBox(height: 8),
            if (_currentTask.audioMessage != null)
              Container(
                color: Colors.white,
                child: AudioPlayerWidget(
                  audioUrl:
                      _database.getTaskAttachment(_currentTask.audioMessage!),
                ),
              )
            else
              const Text('Нет аудиозаписей',style: AppTextStyles.bodyMedium,),
            const SizedBox(height: 16),

            // Видео
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Фотографии
                Text('Видео', style: AppTextStyles.titleSmall),
                const SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Color(0xFFF9F9F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _currentTask.videoMessage!.length.toString(),
                    style: AppTextStyles.bodyMedium
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _currentTask.videoMessage!
                    .where((file) => _isVideo(file))
                    .isNotEmpty
                ? GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 8.0,
                    ),
                    itemCount: _currentTask.videoMessage!
                        .where((file) => _isVideo(file))
                        .length,
                    itemBuilder: (context, index) {
                      final video = _currentTask.videoMessage!
                          .where((file) => _isVideo(file))
                          .toList()[index];
                      final videoUrl = _database.getTaskAttachment(video);

                      return FutureBuilder<Uint8List?>(
                        future: _generateThumbnail(videoUrl),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Container(
                              color: Colors.white,
                              child: const Center(
                                  child: CircularProgressIndicator()),
                            );
                          }
                          if (snapshot.hasError || snapshot.data == null) {
                            return Container(
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.broken_image, size: 32),
                            );
                          }
                          return GestureDetector(
                            onTap: () => _openVideoGallery(
                              context,
                              index,
                              _currentTask.videoMessage!
                                  .where((file) => _isVideo(file))
                                  .toList(),
                            ),
                            child: Container(
                              color: Colors.white, // Белый фон для видео
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: Image.memory(
                                      snapshot.data!,
                                      fit: BoxFit.contain,
                                      width: double.infinity,
                                      height: double.infinity,
                                    ),
                                  ),
                                  Icon(
                                    Iconsax.play_circle,
                                    color: const Color(0xFF049FFF),
                                    size: 48.0,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  )
                : const Text('Нет видео'),

            const SizedBox(height: 16),
            const Divider(),

            TaskLayoutBuilder(
              task: currentTask ?? widget.task, // Используем обновленную задачу
              role: RoleHelper.determineUserRoleInTask(
                currentUserId: UserService.to.currentUser!.userId,
                task: currentTask ?? widget.task,
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  void _openPhotoGallery(
      BuildContext context, int initialIndex, List<String> files) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoGalleryScreen(
          photos: files.map(_database.getTaskAttachment).toList(),
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
          videoUrls: videoUrls.map(_database.getTaskAttachment).toList(),
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}

class PhotoGalleryScreen extends StatelessWidget {
  final List<String> photos;
  final int initialIndex;

  const PhotoGalleryScreen({
    super.key,
    required this.photos,
    this.initialIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: PhotoViewGallery.builder(
        itemCount: photos.length,
        pageController: PageController(initialPage: initialIndex),
        builder: (context, index) {
          return PhotoViewGalleryPageOptions(
            imageProvider: NetworkImage(photos[index]),
            heroAttributes: PhotoViewHeroAttributes(tag: 'photo_$index'),
          );
        },
        scrollPhysics: const BouncingScrollPhysics(),
        loadingBuilder: (context, event) => Center(
          child: Container(
            color: Colors.white,
            child: CircularProgressIndicator(
              value: event == null
                  ? null
                  : event.cumulativeBytesLoaded /
                      (event.expectedTotalBytes ?? 1),
            ),
          ),
        ),
        backgroundDecoration: const BoxDecoration(color: Colors.white),
      ),
    );
  }
}

class VideoGalleryScreen extends StatefulWidget {
  final List<String> videoUrls;
  final int initialIndex;

  const VideoGalleryScreen({
    super.key,
    required this.videoUrls,
    this.initialIndex = 0,
  });

  @override
  _VideoGalleryScreenState createState() => _VideoGalleryScreenState();
}

class _VideoGalleryScreenState extends State<VideoGalleryScreen> {
  late PageController _pageController;
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    _initializeVideoPlayer(widget.videoUrls[widget.initialIndex]);
  }

  void _initializeVideoPlayer(String videoUrl) {
    _videoPlayerController = VideoPlayerController.network(videoUrl)
      ..initialize().then((_) {
        if (mounted) {
          _chewieController = ChewieController(
            videoPlayerController: _videoPlayerController!,
            autoPlay: true,
            looping: false,
            showControls: true,
          );
          setState(() {});
        }
      });
  }

  void _changeVideo(int index) {
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    _initializeVideoPlayer(widget.videoUrls[index]);
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) => _changeVideo(index),
        itemCount: widget.videoUrls.length,
        itemBuilder: (context, index) {
          return Container(
            color: Colors.white,
            child: Center(
              child: _chewieController != null &&
                      _chewieController!
                          .videoPlayerController.value.isInitialized
                  ? Chewie(controller: _chewieController!)
                  : const CircularProgressIndicator(),
            ),
          );
        },
      ),
    );
  }
}
