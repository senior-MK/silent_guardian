import 'dart:async';
import 'package:flutter/material.dart';
import 'package:silent_guardian/services/audio_service.dart';

class SimpleAudioPlayer extends StatefulWidget {
  final String filePath;
  const SimpleAudioPlayer({super.key, required this.filePath});

  @override
  State<SimpleAudioPlayer> createState() => _SimpleAudioPlayerState();
}

class _SimpleAudioPlayerState extends State<SimpleAudioPlayer> {
  bool _isPlaying = false;
  Duration _currentPos = Duration.zero;
  Duration _totalDuration = const Duration(seconds: 1);
  StreamSubscription? _positionSub;
  // use the static AudioService API

  @override
  void initState() {
    super.initState();
    _listenToPlayer();
  }

  void _listenToPlayer() {
    final stream = AudioService.positionStream;
    if (stream != null) {
      _positionSub = stream.listen((pos) {
        setState(() {
          // `pos.position` and `pos.duration` are non-nullable from the
          // playback stream; assign directly.
          _currentPos = pos.position;
          _totalDuration = pos.duration;
        });
      });
    }
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await AudioService.pause();
    } else {
      await AudioService.playFile(widget.filePath);
    }
    setState(() => _isPlaying = !_isPlaying);
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _totalDuration.inMilliseconds == 0
        ? 0.0
        : _currentPos.inMilliseconds / _totalDuration.inMilliseconds;

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                  onPressed: _togglePlay,
                ),
                Text(
                  "${_formatDuration(_currentPos)} / ${_formatDuration(_totalDuration)}",
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }
}
