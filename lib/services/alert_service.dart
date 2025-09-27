// lib/services/alert_service.dart
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../models/alert.dart';
import 'db_helper.dart';
import 'location_service.dart';

/// Enum for all supported alert types
enum AlertType { guardianLock, panic, escalation, redAlert, lowBattery, decoy }

class AlertService {
  // Helper to fetch best available location (current -> last known)
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
  }) async {
    // Placeholder file for evidence
    final dir = await getApplicationDocumentsDirectory();
    final dummyFile = File(
      '${dir.path}/dummy_${DateTime.now().millisecondsSinceEpoch}.txt',
    );
    await dummyFile.writeAsString("Evidence placeholder");

    final id = await createAlertWithEvidence(
      type: type,
      extraMeta: extraMeta,
      evidencePaths: [dummyFile.path],
    );

    developer.log("triggerAlert: stored alert id=$id", name: 'alert_service');
    return id;
  }

  // --- Specific alert creators ---
  static Future<int> createGuardianLock({
    required int durationSeconds,
    String? extraMeta,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final loc = await _fetchLocation();
    final metaMap = {
      'duration': durationSeconds,
      'status': 'armed',
      if (extraMeta != null) 'note': extraMeta,
    };
    return DBHelper().insertAlert(
      AlertModel(
        type: AlertType.guardianLock.name,
        timestamp: now,
        latitude: loc['lat'],
        longitude: loc['lon'],
        synced: false,
        meta: jsonEncode(metaMap),
      ),
    );
  }

  static Future<int> createEscalationAlert({
    int? guardianId,
    String? extraMeta,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final loc = await _fetchLocation();
    final metaMap = {
      if (guardianId != null) 'guardian_id': guardianId,
      if (extraMeta != null) 'note': extraMeta,
      'reason': 'countdown_expired',
    };
    return DBHelper().insertAlert(
      AlertModel(
        type: AlertType.escalation.name,
        timestamp: now,
        latitude: loc['lat'],
        longitude: loc['lon'],
        synced: false,
        meta: jsonEncode(metaMap),
      ),
    );
  }

  static Future<int> createPanicAlert({String? extraMeta}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final loc = await _fetchLocation();
    final metaMap = {
      if (extraMeta != null) 'note': extraMeta,
      'reason': 'panic_button',
    };
    return DBHelper().insertAlert(
      AlertModel(
        type: AlertType.panic.name,
        timestamp: now,
        latitude: loc['lat'],
        longitude: loc['lon'],
        synced: false,
        meta: jsonEncode(metaMap),
      ),
    );
  }

  static Future<int> createRedAlert({String? extraMeta}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final loc = await _fetchLocation();
    final metaMap = {
      if (extraMeta != null) 'note': extraMeta,
      'reason': 'red_alert',
    };
    return DBHelper().insertAlert(
      AlertModel(
        type: AlertType.redAlert.name,
        timestamp: now,
        latitude: loc['lat'],
        longitude: loc['lon'],
        synced: false,
        meta: jsonEncode(metaMap),
      ),
    );
  }

  // --- New Decoy Alert ---
  static Future<int> createDecoyAlert({String? extraMeta}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final loc = await _fetchLocation();
    final metaMap = {
      if (extraMeta != null) 'note': extraMeta,
      'reason': 'decoy_pin_triggered',
    };
    return DBHelper().insertAlert(
      AlertModel(
        type: AlertType.decoy.name,
        timestamp: now,
        latitude: loc['lat'],
        longitude: loc['lon'],
        synced: false,
        meta: jsonEncode(metaMap),
      ),
    );
  }

  static Future<int> createLowBatteryAlert({
    int? batteryLevel,
    String? extraMeta,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final loc = await _fetchLocation();
    final metaMap = {
      if (batteryLevel != null) 'battery': batteryLevel,
      if (extraMeta != null) 'note': extraMeta,
      'reason': 'low_battery',
    };
    return DBHelper().insertAlert(
      AlertModel(
        type: AlertType.lowBattery.name,
        timestamp: now,
        latitude: loc['lat'],
        longitude: loc['lon'],
        synced: false,
        meta: jsonEncode(metaMap),
      ),
    );
  }

  // --- Alert with evidence ---
  static Future<int> createAlertWithEvidence({
    required AlertType type,
    String? extraMeta,
    List<String>? evidencePaths,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final loc = await _fetchLocation();
    final metaMap = {
      if (extraMeta != null) 'note': extraMeta,
      if (evidencePaths != null && evidencePaths.isNotEmpty)
        'evidence': evidencePaths,
    };
    return DBHelper().insertAlert(
      AlertModel(
        type: type.name,
        timestamp: now,
        latitude: loc['lat'],
        longitude: loc['lon'],
        synced: false,
        meta: jsonEncode(metaMap),
      ),
    );
  }

  // Fetch all alerts
  static Future<List<AlertModel>> getAllAlerts() async {
    return DBHelper().getAllAlerts();
  }
}
