import 'dart:io';
import 'dart:developer' as developer;
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'evidence_path.dart';

/// Handles video recording with embedded audio.
class VideoService {
  static final VideoService _instance = VideoService._internal();
  factory VideoService() => _instance;
  VideoService._internal();

  CameraController? _controller;
  bool _isRecording = false;

  /// Initializes the camera (back camera preferred)
  Future<void> initCamera() async {
    developer.log('Initializing camera...', name: 'video_service');
    final statusCam = await Permission.camera.request();
    final statusMic = await Permission.microphone.request();

    if (!statusCam.isGranted || !statusMic.isGranted) {
      throw Exception('Camera or microphone permission denied');
    }

    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw Exception('No cameras available on this device');
    }

    final backCam = cameras.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      backCam,
      ResolutionPreset.high,
      enableAudio: true, // crucial: embeds audio track
    );

    try {
      await _controller!.initialize();
      developer.log(
        'Camera initialized: ${backCam.name}',
        name: 'video_service',
      );
    } catch (e, st) {
      developer.log(
        'Camera initialization failed: $e\n$st',
        name: 'video_service',
      );
      rethrow;
    }
  }

  /// Starts recording video to the evidence folder
  Future<String?> startVideoRecording(String alertId) async {
    if (_isRecording) {
      developer.log(
        'Attempt to start video while already recording',
        name: 'video_service',
      );
      return await EvidencePath.getVideoPath(alertId);
    }

    try {
      if (_controller == null || !_controller!.value.isInitialized) {
        await initCamera();
      }

      final videoPath = await EvidencePath.getVideoPath(alertId);
      final outFile = File(videoPath);
      if (await outFile.exists()) {
        await outFile.delete();
      } else {
        // make sure parent dir exists
        await outFile.parent.create(recursive: true);
      }

      // start recording (camera plugin will write temporary file and we save on stop)
      await _controller!.startVideoRecording();
      _isRecording = true;

      developer.log(
        '🎥 Video recording started for alert $alertId -> temp recording (will save to $videoPath on stop)',
        name: 'video_service',
      );
      return videoPath;
    } catch (e, st) {
      developer.log(
        'Failed to start video recording: $e\n$st',
        name: 'video_service',
      );
      rethrow;
    }
  }

  /// Stops recording and saves the file
  Future<String?> stopVideoRecording(String alertId) async {
    if (!_isRecording || _controller == null) {
      developer.log(
        'stopVideoRecording called but no recording active',
        name: 'video_service',
      );
      return null;
    }

    try {
      final recordedFile = await _controller!
          .stopVideoRecording(); // returns XFile
      _isRecording = false;

      final targetPath = await EvidencePath.getVideoPath(alertId);

      // Save recorded temp file to targetPath
      try {
        await recordedFile.saveTo(targetPath);
        developer.log('🎬 Video saved to: $targetPath', name: 'video_service');
      } catch (e) {
        developer.log(
          'Failed to save recorded video to $targetPath: $e',
          name: 'video_service',
        );
        rethrow;
      }

      return targetPath;
    } catch (e, st) {
      developer.log(
        'Failed to stop or save video recording: $e\n$st',
        name: 'video_service',
      );
      rethrow;
    }
  }

  bool get isRecording => _isRecording;

  Future<void> dispose() async {
    try {
      await _controller?.dispose();
      _controller = null;
      developer.log('VideoService disposed', name: 'video_service');
    } catch (e) {
      developer.log('Error disposing VideoService: $e', name: 'video_service');
    }
  }
}
