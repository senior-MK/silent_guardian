import 'dart:developer' as developer;
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'evidence_path.dart';

/// Handles audio recording for evidence (.m4a)
class RecordService {
  static final RecordService _instance = RecordService._internal();
  factory RecordService() => _instance;
  RecordService._internal();

  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _currentPath;

  /// Requests microphone + storage permissions.
  Future<bool> _requestPermissions() async {
    final mic = await Permission.microphone.request();
    final storage = await Permission.storage.request();
    final granted = mic.isGranted && (storage.isGranted || Platform.isAndroid);
    developer.log(
      'Permission mic=${mic.isGranted}, storage=${storage.isGranted}',
      name: 'RecordService',
    );
    return granted;
  }

  /// Start recording (.m4a) for given alertId.
  Future<String> startAudioRecording(String alertId) async {
    if (_isRecording) return _currentPath ?? '';

    final granted = await _requestPermissions();
    if (!granted) throw Exception('Permissions not granted');

    final path = await EvidencePath.getAudioPath(alertId);

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000),
      path: path,
    );

    _isRecording = true;
    _currentPath = path;
    developer.log('🎙 Started recording: $path', name: 'RecordService');
    return path;
  }

  /// Stop recording and return saved file path.
  Future<String?> stopAudioRecording() async {
    if (!_isRecording) return _currentPath;
    final path = await _recorder.stop();
    _isRecording = false;
    _currentPath = path;
    developer.log('🛑 Recording stopped, saved: $path', name: 'RecordService');
    return path;
  }

  bool get isRecording => _isRecording;

  Future<void> dispose() async {
    await _recorder.dispose();
  }
}
