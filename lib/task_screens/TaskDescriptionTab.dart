import 'dart:typed_data';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:get_thumbnail_video/index.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:task_tracker/services/task_operations.dart';
import 'package:task_tracker/services/user_service.dart';
import 'package:video_player/video_player.dart';

import '../models/task.dart';
import '../models/task_role.dart';
import '../models/task_status.dart';
import '../widgets/TaskLayout.dart';
import '../widgets/customPlayer.dart';

class TaskDescriptionTab extends StatelessWidget {
  final Task task;
  final TaskService _database = TaskService();

  TaskDescriptionTab({super.key, required this.task});


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
    if (task.team.creatorId == UserService.to.currentUser!.userId) {
      return "Постановщик";
    } else if (task.team.communicatorId == UserService.to.currentUser!.userId) {
      return "Коммуникатор";
    } else if (task.team.teamMembers.first ==
        UserService.to.currentUser!.userId) {
      return "Исполнитель";
    } else {
      return "Наблюдатель";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Статус', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEBEDF0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    task.status == TaskStatus.controlPoint &&
                        _getPosition() != "Коммуникатор"
                        ? StatusHelper.getStatusIcon(TaskStatus.atWork)
                        : StatusHelper.getStatusIcon(task.status),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    task.status == TaskStatus.controlPoint &&
                        _getPosition() != "Коммуникатор"
                        ? StatusHelper.displayName(TaskStatus.atWork)
                        : StatusHelper.displayName(task.status),
                    style: Theme.of(context).textTheme.bodySmall,
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
            Text('Проект', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(task.project?.name ?? 'Не указан',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),

            // Название задачи
            Text('Название задачи',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(task.taskName, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),

            // Описание задачи
            Text('Описание задачи',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(task.description,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Фотографии
                Text('Фотографии',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Color(0xFFF9F9F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    task.attachments.length.toString(),
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            task.attachments.where((file) => _isImage(file)).isNotEmpty
                ? GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
              ),
              itemCount:
              task.attachments.where((file) => _isImage(file)).length,
              itemBuilder: (context, index) {
                final photo = task.attachments
                    .where((file) => _isImage(file))
                    .toList()[index];
                return GestureDetector(
                  onTap: () => _openPhotoGallery(
                    context,
                    index,
                    task.attachments
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
                : const Text('Нет фотографий'),
            const SizedBox(height: 16),

            // Аудиозаписи
            Text(
              'Аудиозаписи ',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            if (task.audioMessage != null)
              Container(
                color: Colors.white,
                child: AudioPlayerWidget(
                  audioUrl: _database.getTaskAttachment(task.audioMessage!),
                ),
              )
            else
              const Text('Нет аудиозаписей'),
            const SizedBox(height: 16),

            // Видео
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Фотографии
                Text('Видео', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Color(0xFFF9F9F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    task.videoMessage!.length.toString(),
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            task.videoMessage!.where((file) => _isVideo(file)).isNotEmpty
                ? GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
              ),
              itemCount: task.videoMessage!
                  .where((file) => _isVideo(file))
                  .length,
              itemBuilder: (context, index) {
                final video = task.videoMessage!
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
                        task.videoMessage!
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
                task: task,
                role: RoleHelper.determineUserRoleInTask(
                    currentUserId: UserService.to.currentUser!.userId,
                    task: task))
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
