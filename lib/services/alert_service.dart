import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../models/alert.dart';
import 'db_helper.dart';
import 'location_service.dart';
import 'record_service.dart';
import 'video_service.dart';
import 'evidence_path.dart';
import 'evidence_metadata_service.dart';

/// Enum for all supported alert types
enum AlertType { guardianLock, panic, escalation, redAlert, lowBattery, decoy }

class AlertService {
  // --- Helper: fetch best available location ---
  static Future<Map<String, double?>> _fetchLocation() async {
    double? lat;
    double? lon;
    try {
      final pos = await LocationService.getCurrentLocation();
      lat = pos.latitude;
      lon = pos.longitude;
    } catch (e) {
      developer.log('getCurrentLocation failed: $e', name: 'alert_service');
      try {
        final last = await LocationService.getLastKnownPosition();
        if (last != null) {
          lat = last.latitude;
          lon = last.longitude;
        }
      } catch (e2) {
        developer.log(
          'getLastKnownPosition failed: $e2',
          name: 'alert_service',
        );
      }
    }
    return {'lat': lat, 'lon': lon};
  }

  // --- Generic trigger wrapper ---
  static Future<int> triggerAlert({
    required AlertType type,
    String? extraMeta,
    String? escalationPolicy,
    String? targetContacts,
    bool isDecoy = false,
    String? escalationState,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final dummyFile = File(
      '${dir.path}/dummy_${DateTime.now().millisecondsSinceEpoch}.txt',
    );
    await dummyFile.writeAsString("Evidence placeholder");

    final id = await createAlertWithEvidence(
      type: type,
      extraMeta: extraMeta,
      escalationPolicy: escalationPolicy,
      targetContacts: targetContacts,
      isDecoy: isDecoy,
      escalationState: escalationState,
      evidencePaths: [dummyFile.path],
    );

    developer.log("triggerAlert: stored alert id=$id", name: 'alert_service');
    return id;
  }

  // --- Guardian Lock ---
  static Future<int> createGuardianLock({
    required int durationSeconds,
    String? extraMeta,
    String? escalationPolicy,
    String? targetContacts,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final loc = await _fetchLocation();
    final metaMap = {
      'duration': durationSeconds,
      'status': 'armed',
      if (extraMeta != null) 'note': extraMeta,
    };

    final alert = AlertModel(
      type: AlertType.guardianLock.name,
      timestamp: now,
      latitude: loc['lat'],
      longitude: loc['lon'],
      synced: false,
      meta: jsonEncode(metaMap),
      escalationPolicy: escalationPolicy,
      targetContacts: targetContacts,
    );

    final id = await DBHelper().insertAlert(alert);
    await EvidenceMetadataService.generate(alert.copyWith(id: id));
    return id;
  }

  // --- Escalation Alert (auto audio + video) ---
  static Future<int> createEscalationAlert({
    int? guardianId,
    String? extraMeta,
    String? escalationPolicy,
    String? targetContacts,
    String escalationState = "pending",
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final loc = await _fetchLocation();

    final metaMap = {
      if (guardianId != null) 'guardian_id': guardianId,
      if (extraMeta != null) 'note': extraMeta,
      'reason': 'countdown_expired',
    };

    final alert = AlertModel(
      type: AlertType.escalation.name,
      timestamp: now,
      latitude: loc['lat'],
      longitude: loc['lon'],
      synced: false,
      meta: jsonEncode(metaMap),
      escalationPolicy: escalationPolicy,
      targetContacts: targetContacts,
      escalationState: escalationState,
    );

    final id = await DBHelper().insertAlert(alert);

    try {
      final evidenceDir = await EvidencePath.getEvidenceDir(id.toString());
      developer.log(
        '🎯 Evidence folder: ${evidenceDir.path}',
        name: 'alert_service',
      );

      final audio = RecordService();
      final video = VideoService();

      await audio.startAudioRecording(id.toString());
      await video.startVideoRecording(id.toString());

      developer.log(
        '🎥 Audio + Video recording started for escalation $id',
        name: 'alert_service',
      );
    } catch (e, st) {
      developer.log(
        '⚠️ Failed to start recording: $e\n$st',
        name: 'alert_service',
      );
    }

    await EvidenceMetadataService.generate(alert.copyWith(id: id));
    return id;
  }

  // --- Stop all recorders & generate metadata ---
  static Future<void> stopAllRecordings(String alertId) async {
    try {
      final recorder = RecordService();
      final video = VideoService();

      final audioPath = await recorder.stopAudioRecording();
      final videoPath = await video.stopVideoRecording(alertId);

      developer.log(
        '🛑 Recordings stopped for alert $alertId',
        name: 'alert_service',
      );

      // Get and update alert meta
      final allAlerts = await DBHelper().getAllAlerts();
      final alert = allAlerts.firstWhere(
        (a) => a.id.toString() == alertId,
        orElse: () => allAlerts.last,
      );

      Map<String, dynamic> metaMap = alert.meta != null
          ? jsonDecode(alert.meta!)
          : {};
      metaMap['audio_path'] = audioPath;
      metaMap['video_path'] = videoPath;

      await DBHelper().updateAlertMeta(alert.id!, jsonEncode(metaMap));

      await EvidenceMetadataService.generate(
        alert.copyWith(meta: jsonEncode(metaMap)),
      );

      developer.log(
        '✅ Metadata generated successfully for alert $alertId',
        name: 'alert_service',
      );
    } catch (e, st) {
      developer.log(
        '⚠️ Error stopping recordings / generating metadata: $e',
        name: 'alert_service',
        error: e,
        stackTrace: st,
      );
    }
  }

  // --- Panic Alert ---
  static Future<int> createPanicAlert({
    String? extraMeta,
    String? escalationPolicy,
    String? targetContacts,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final loc = await _fetchLocation();
    final metaMap = {
      'reason': 'panic_button',
      if (extraMeta != null) 'note': extraMeta,
    };

    final alert = AlertModel(
      type: AlertType.panic.name,
      timestamp: now,
      latitude: loc['lat'],
      longitude: loc['lon'],
      synced: false,
      meta: jsonEncode(metaMap),
      escalationPolicy: escalationPolicy,
      targetContacts: targetContacts,
    );

    final id = await DBHelper().insertAlert(alert);
    await EvidenceMetadataService.generate(alert.copyWith(id: id));
    return id;
  }

  // --- Red Alert ---
  static Future<int> createRedAlert({
    String? extraMeta,
    String? escalationPolicy,
    String? targetContacts,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final loc = await _fetchLocation();
    final metaMap = {
      'reason': 'red_alert',
      if (extraMeta != null) 'note': extraMeta,
    };

    final alert = AlertModel(
      type: AlertType.redAlert.name,
      timestamp: now,
      latitude: loc['lat'],
      longitude: loc['lon'],
      synced: false,
      meta: jsonEncode(metaMap),
      escalationPolicy: escalationPolicy,
      targetContacts: targetContacts,
    );

    final id = await DBHelper().insertAlert(alert);
    await EvidenceMetadataService.generate(alert.copyWith(id: id));
    return id;
  }

  // --- Decoy Alert ---
  static Future<int> createDecoyAlert({
    String? extraMeta,
    String? escalationPolicy,
    String? targetContacts,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final loc = await _fetchLocation();
    final metaMap = {
      'reason': 'decoy_pin_triggered',
      if (extraMeta != null) 'note': extraMeta,
    };

    final alert = AlertModel(
      type: AlertType.decoy.name,
      timestamp: now,
      latitude: loc['lat'],
      longitude: loc['lon'],
      synced: false,
      meta: jsonEncode(metaMap),
      escalationPolicy: escalationPolicy,
      targetContacts: targetContacts,
      isDecoy: true,
    );

    final id = await DBHelper().insertAlert(alert);
    await EvidenceMetadataService.generate(alert.copyWith(id: id));
    return id;
  }

  // --- Low Battery Alert ---
  static Future<int> createLowBatteryAlert({
    int? batteryLevel,
    String? extraMeta,
    String? escalationPolicy,
    String? targetContacts,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final loc = await _fetchLocation();
    final metaMap = {
      'reason': 'low_battery',
      if (batteryLevel != null) 'battery': batteryLevel,
      if (extraMeta != null) 'note': extraMeta,
    };

    final alert = AlertModel(
      type: AlertType.lowBattery.name,
      timestamp: now,
      latitude: loc['lat'],
      longitude: loc['lon'],
      synced: false,
      meta: jsonEncode(metaMap),
      escalationPolicy: escalationPolicy,
      targetContacts: targetContacts,
    );

    final id = await DBHelper().insertAlert(alert);
    await EvidenceMetadataService.generate(alert.copyWith(id: id));
    return id;
  }

  // --- Alert with evidence ---
  static Future<int> createAlertWithEvidence({
    required AlertType type,
    String? extraMeta,
    String? escalationPolicy,
    String? targetContacts,
    bool isDecoy = false,
    String? escalationState,
    List<String>? evidencePaths,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final loc = await _fetchLocation();
    final metaMap = {
      if (extraMeta != null) 'note': extraMeta,
      if (evidencePaths != null && evidencePaths.isNotEmpty)
        'evidence': evidencePaths,
    };

    final alert = AlertModel(
      type: type.name,
      timestamp: now,
      latitude: loc['lat'],
      longitude: loc['lon'],
      synced: false,
      meta: jsonEncode(metaMap),
      escalationPolicy: escalationPolicy,
      targetContacts: targetContacts,
      isDecoy: isDecoy,
      escalationState: escalationState,
    );

    final id = await DBHelper().insertAlert(alert);
    await EvidenceMetadataService.generate(alert.copyWith(id: id));
    return id;
  }

  // --- Fetch all alerts ---
  static Future<List<AlertModel>> getAllAlerts() async {
    return DBHelper().getAllAlerts();
  }
}
