import 'dart:typed_data';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:just_audio/just_audio.dart';
import 'package:task_tracker/services/task_operations.dart';
import 'package:video_player/video_player.dart';
import 'package:get_thumbnail_video/index.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';

import '../models/task.dart';

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
      maxWidth: 128, // Размер миниатюры
      quality: 75,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Проект: ${task.project!.name}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8.0),
          Text('Название задачи: ${task.taskName}'),
          const SizedBox(height: 8.0),
          Text('Описание задачи: ${task.description}'),
          const SizedBox(height: 16.0),
          const Text('Фотографии:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8.0),
          task.attachments.where((file) => _isImage(file)).isNotEmpty
              ? GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                          child: Image.network(
                            _database.getTaskAttachment(photo),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.broken_image, size: 32),
                          ),
                        ),
                      ),
                    );
                  },
                )
              : const Text('Нет фотографий'),
          const SizedBox(height: 16.0),
          const Text('Аудиозаписи:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8.0),
          if (task.audioMessage != null)
            AudioPlayerWidget(
                audioUrl: _database.getTaskAttachment(task.audioMessage!))
          else
            const Text('Нет аудиозаписей'),
          const SizedBox(height: 16.0),
          const Text('Видео:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8.0),
          task.videoMessage!.where((file) => _isVideo(file)).isNotEmpty
              ? GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                  ),
                  itemCount:
                      task.videoMessage!.where((file) => _isVideo(file)).length,
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
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError || snapshot.data == null) {
                          return const Icon(Icons.broken_image, size: 48);
                        }
                        return GestureDetector(
                          onTap: () => _openVideoGallery(
                            context,
                            index,
                            task.videoMessage!
                                .where((file) => _isVideo(file))
                                .toList(),
                          ),
                          child: Hero(
                            tag: 'video_$index',
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Image.memory(
                                    snapshot.data!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                ),
                                const Icon(
                                  Icons.play_circle_fill,
                                  color: Colors.white,
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
        ],
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
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
          child: CircularProgressIndicator(
            value: event == null
                ? null
                : event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? 1),
          ),
        ),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
      ),
    );
  }
}

class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;

  const AudioPlayerWidget({super.key, required this.audioUrl});

  @override
  _AudioPlayerWidgetState createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.setUrl(widget.audioUrl);
    _audioPlayer.playerStateStream.listen((playerState) {
      // Обновляем состояние плеера, чтобы кнопка переключалась правильно
      if (playerState.processingState == ProcessingState.completed) {
        setState(() {
          _audioPlayer.pause();
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        StreamBuilder<Duration>(
          stream: _audioPlayer.positionStream, // Подписываемся на поток позиции
          builder: (context, snapshot) {
            final position = snapshot.data ?? Duration.zero;
            final duration = _audioPlayer.duration ?? Duration.zero;
            final isPlaying = _audioPlayer.playerState.playing;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                      onPressed: () {
                        if (isPlaying) {
                          _audioPlayer.pause();
                        } else {
                          _audioPlayer.play();
                        }
                      },
                    ),
                    Expanded(
                      child: Slider(
                        value: position.inMilliseconds.toDouble(),
                        max: duration.inMilliseconds.toDouble(),
                        min: 0.0,
                        onChanged: (value) {
                          _audioPlayer
                              .seek(Duration(milliseconds: value.toInt()));
                        },
                      ),
                    ),
                    Text(_formatDuration(position)),
                  ],
                ),
                if (_audioPlayer.playerState.processingState ==
                    ProcessingState.completed)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text('Завершено'),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes);
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) => _changeVideo(index),
        itemCount: widget.videoUrls.length,
        itemBuilder: (context, index) {
          return Center(
            child: _chewieController != null &&
                    _chewieController!.videoPlayerController.value.isInitialized
                ? Chewie(controller: _chewieController!)
                : const CircularProgressIndicator(),
          );
        },
      ),
    );
  }
}
