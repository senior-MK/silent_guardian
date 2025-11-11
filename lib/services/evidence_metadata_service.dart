// lib/services/evidence_metadata_service.dart
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import '../models/alert.dart';
import 'evidence_path.dart';

/// Handles creation and updating of metadata.json for each alert.
class EvidenceMetadataService {
  /// Generates a new metadata.json file for the given alert.
  static Future<void> generate(AlertModel alert) async {
    try {
      // Use alert ID if available, else fallback to timestamp.
      final alertIdStr = alert.id?.toString() ?? alert.timestamp.toString();
      final dir = await EvidencePath.getEvidenceDir(alertIdStr);
      final file = File('${dir.path}/metadata.json');

      // Decode meta only once for efficiency.
      Map<String, dynamic> metaMap = {};
      if (alert.meta != null) {
        try {
          metaMap = jsonDecode(alert.meta!) as Map<String, dynamic>;
        } catch (_) {
          metaMap = {'raw_meta': alert.meta};
        }
      }

      // Determine evidence file existence.
      final audioFile = File('${dir.path}/audio.m4a');
      final videoFile = File('${dir.path}/video.mp4');
      final audioExists = await audioFile.exists();
      final videoExists = await videoFile.exists();

      final data = {
        'alert_id': alert.id,
        'timestamp': DateTime.fromMillisecondsSinceEpoch(
          alert.timestamp,
        ).toUtc().toIso8601String(),
        'type': alert.type,
        'latitude': alert.latitude,
        'longitude': alert.longitude,
        'battery_level': metaMap['battery'],
        'network_status': metaMap['network'],
        'audio_path': audioFile.path,
        'video_path': videoFile.path,
        'audio_exists': audioExists,
        'video_exists': videoExists,
        'meta': metaMap,
        'generated_at': DateTime.now().toUtc().toIso8601String(),
      };

      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(data),
        flush: true,
      );

      developer.log(
        '🧾 Metadata created for ${alert.type} (id=${alert.id ?? alertIdStr})',
        name: 'EvidenceMetadataService',
      );
    } catch (e, st) {
      developer.log(
        '❌ Metadata generation failed: $e',
        name: 'EvidenceMetadataService',
        error: e,
        stackTrace: st,
      );
    }
  }
}
