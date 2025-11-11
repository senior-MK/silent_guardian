import 'dart:io';
import 'dart:developer' as developer;
import 'package:path_provider/path_provider.dart';

/// Handles folder creation and file path generation for all evidence (audio + video)
class EvidencePath {
  /// Root app folder under internal storage
  static const String _rootFolderName = 'SilentGuardian';

  /// Returns: /.../SilentGuardian/Evidence/<alertId>/
  static Future<Directory> getEvidenceDir(String alertId) async {
    Directory? base;
    try {
      base = await getExternalStorageDirectory(); // preferred on Android
    } catch (e) {
      developer.log(
        'getExternalStorageDirectory failed: $e',
        name: 'evidence_path',
      );
    }

    // Fallback to application documents dir if external is null
    base ??= await getApplicationDocumentsDirectory();

    final dir = Directory('${base.path}/$_rootFolderName/Evidence/$alertId');

    try {
      if (!await dir.exists()) {
        await dir.create(recursive: true);
        developer.log(
          'Created evidence directory: ${dir.path}',
          name: 'evidence_path',
        );
      } else {
        developer.log(
          'Evidence directory exists: ${dir.path}',
          name: 'evidence_path',
        );
      }
    } catch (e, st) {
      developer.log(
        'Failed to create evidence directory: $e\n$st',
        name: 'evidence_path',
      );
      rethrow;
    }

    return dir;
  }

  /// Returns audio path like: <evidenceDir>/audio.m4a
  static Future<String> getAudioPath(String alertId) async {
    final dir = await getEvidenceDir(alertId);
    final audioPath = '${dir.path}/audio.m4a';
    developer.log('Audio path: $audioPath', name: 'evidence_path');
    return audioPath;
  }

  /// Returns video path like: <evidenceDir>/video.mp4
  static Future<String> getVideoPath(String alertId) async {
    final dir = await getEvidenceDir(alertId);
    final videoPath = '${dir.path}/video.mp4';
    developer.log('Video path: $videoPath', name: 'evidence_path');
    return videoPath;
  }
}
