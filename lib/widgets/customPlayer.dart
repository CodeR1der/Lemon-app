import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;

  const AudioPlayerWidget({super.key, required this.audioUrl});

  @override
  AudioPlayerWidgetState createState() => AudioPlayerWidgetState();
}

class AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final _player = AudioPlayer();
  late Stream<Duration> _positionStream;
  late Stream<Duration?> _durationStream;
  final Color _playerColor = const Color(0xFF049FFF); // Основной цвет плеера

  @override
  void initState() {
    super.initState();
    _initAudio();
    _positionStream = _player.positionStream;
    _durationStream = _player.durationStream;
  }

  Future<void> _initAudio() async {
    try {
      await _player.setUrl(widget.audioUrl);
    } catch (e) {
      debugPrint('Error loading audio: $e');
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration?>(
      stream: _durationStream,
      builder: (context, durationSnapshot) {
        final duration = durationSnapshot.data ?? Duration.zero;
        return StreamBuilder<Duration>(
          stream: _positionStream,
          builder: (context, positionSnapshot) {
            var position = positionSnapshot.data ?? Duration.zero;
            if (position > duration) position = duration;

            return StreamBuilder<PlayerState>(
              stream: _player.playerStateStream,
              builder: (context, stateSnapshot) {
                final playing = stateSnapshot.data?.playing ?? false;

                return Row(
                  children: [
                    // Кнопка воспроизведения слева
                    IconButton(
                      iconSize: 34,
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        playing ? Iconsax.pause_circle : Iconsax.play_circle,
                        color: _playerColor,
                      ),
                      onPressed: () {
                        if (playing) {
                          _player.pause();
                        } else {
                          _player.play();
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    // Полоса прогресса и время
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: _playerColor,
                              inactiveTrackColor: _playerColor.withOpacity(0.3),
                              thumbColor: _playerColor,
                              trackHeight: 3,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6,
                              ),
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 10,
                              ),
                            ),
                            child: Slider(
                              min: 0,
                              max: duration.inMilliseconds.toDouble(),
                              value: position.inMilliseconds.toDouble(),
                              onChanged: (value) {
                                _player.seek(Duration(milliseconds: value.toInt()));
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(position),
                                  style: Theme.of(context).textTheme.displayMedium
                                ),
                                Text(
                                  _formatDuration(duration),
                                  style: Theme.of(context).textTheme.displayMedium
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}