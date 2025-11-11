import 'dart:async';
import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'recording_paths.dart'; // 🔹 added import for organized file paths

class AudioService {
  static final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  static final FlutterSoundPlayer _player = FlutterSoundPlayer();

  static bool _recorderInitialized = false;
  static bool _playerInitialized = false;
  static bool _isRecording = false;
  static bool _isPlaying = false;
  static String? _currentFilePath;

  // -------------------------
  // 🔹 Recorder Section
  // -------------------------

  static Future<void> initRecorder() async {
    if (_recorderInitialized) return;

    await Permission.microphone.request();
    await _recorder.openRecorder();
    _recorderInitialized = true;
  }

  static Future<String?> startRecording() async {
    await initRecorder();

    // 🔹 Create a clean, timestamped path in /recordings folder
    final path = await newRecordingPath("recording");

    await _recorder.startRecorder(
      toFile: path,
      codec: Codec
          .aacMP4, // 🔸 Prefer modern m4a container for better compatibility
    );

    _isRecording = true;
    _currentFilePath = path;
    return path;
  }

  static Future<String?> stopRecording() async {
    if (!_isRecording) return null;
    await _recorder.stopRecorder();
    _isRecording = false;
    return _currentFilePath;
  }

  // -------------------------
  // 🔹 Player Section
  // -------------------------

  static Future<void> initPlayer() async {
    if (_playerInitialized) return;
    await _player.openPlayer();
    _playerInitialized = true;
  }

  static Future<void> playFile(String filePath) async {
    await initPlayer();
    if (!File(filePath).existsSync()) return;

    _currentFilePath = filePath;
    await _player.startPlayer(
      fromURI: filePath,
      codec: Codec.aacMP4,
      whenFinished: () => _isPlaying = false,
    );
    _isPlaying = true;
  }

  static Future<void> pause() async {
    if (_isPlaying) {
      await _player.pausePlayer();
      _isPlaying = false;
    }
  }

  static Future<void> resume() async {
    if (!_isPlaying && _player.isPaused) {
      await _player.resumePlayer();
      _isPlaying = true;
    }
  }

  static Future<void> stopPlayback() async {
    await _player.stopPlayer();
    _isPlaying = false;
  }

  // -------------------------
  // 🔹 State Streams (for UI)
  // -------------------------

  static Stream<PlaybackDisposition>? get positionStream => _player.onProgress;

  static bool get isPlaying => _isPlaying;
  static String? get currentFilePath => _currentFilePath;

  // -------------------------
  // 🔹 Clean up
  // -------------------------

  static Future<void> dispose() async {
    await _recorder.closeRecorder();
    await _player.closePlayer();
    _recorderInitialized = false;
    _playerInitialized = false;
  }
}
