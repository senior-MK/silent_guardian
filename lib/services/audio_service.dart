// lib/services/audio_service.dart
import 'dart:async';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';

class AudioService {
  static final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  static bool _isInitialized = false;
  static bool _isRecording = false;
  static String? _currentFilePath;

  /// Initialize the recorder once (must be called before recording)
  static Future<void> init() async {
    if (_isInitialized) return;
    await _recorder.openRecorder();
    _isInitialized = true;
  }

  /// Generate a safe file path inside the app's documents directory
  static Future<String> _generateFilePath() async {
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return "${dir.path}/audio_$timestamp.aac";
  }

  /// Start recording to a managed file
  static Future<String> startRecording() async {
    if (!_isInitialized) {
      await init();
    }
    if (_isRecording) {
      throw Exception("Recording already in progress");
    }

    final filePath = await _generateFilePath();
    await _recorder.startRecorder(toFile: filePath, codec: Codec.aacADTS);

    _isRecording = true;
    _currentFilePath = filePath;
    return filePath;
  }

  /// Stop recording and return the saved file path
  static Future<String?> stopRecording() async {
    if (!_isRecording) return null;

    final path = await _recorder.stopRecorder();
    _isRecording = false;
    return path ?? _currentFilePath;
  }

  /// Whether a recording is in progress
  static bool get isRecording => _isRecording;

  /// Dispose recorder cleanly (e.g., on app exit)
  static Future<void> dispose() async {
    if (_isInitialized) {
      await _recorder.closeRecorder();
      _isInitialized = false;
    }
  }
}
