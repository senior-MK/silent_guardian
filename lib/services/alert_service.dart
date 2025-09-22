// lib/services/alert_service.dart
import 'dart:convert';
import 'dart:developer' as developer;
import '../models/alert.dart';
import 'db_helper.dart';
import 'location_service.dart';

/// Enum to represent all supported alert types
enum AlertType { guardianLock, panic, escalation, redAlert, lowBattery }

class AlertService {
  // Helper - fetch best available location (current -> last known)
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

  // Create Guardian Lock (start of countdown). Returns the inserted alert id.
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
    final alert = AlertModel(
      type: AlertType.guardianLock.name,
      timestamp: now,
      latitude: loc['lat'],
      longitude: loc['lon'],
      synced: false,
      meta: jsonEncode(metaMap),
    );
    final id = await DBHelper().insertAlert(alert);
    developer.log(
      'GuardianLock inserted id=$id meta=${alert.meta}',
      name: 'alert_service',
    );
    return id;
  }

  // Create Escalation alert (triggered when guardian countdown expires)
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
    final alert = AlertModel(
      type: AlertType.escalation.name,
      timestamp: now,
      latitude: loc['lat'],
      longitude: loc['lon'],
      synced: false,
      meta: jsonEncode(metaMap),
    );
    final id = await DBHelper().insertAlert(alert);
    developer.log(
      'Escalation inserted id=$id meta=${alert.meta}',
      name: 'alert_service',
    );
    return id;
  }

  // Immediate Panic alert
  static Future<int> createPanicAlert({String? extraMeta}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final loc = await _fetchLocation();
    final metaMap = {
      if (extraMeta != null) 'note': extraMeta,
      'reason': 'panic_button',
    };
    final alert = AlertModel(
      type: AlertType.panic.name,
      timestamp: now,
      latitude: loc['lat'],
      longitude: loc['lon'],
      synced: false,
      meta: jsonEncode(metaMap),
    );
    final id = await DBHelper().insertAlert(alert);
    developer.log(
      'Panic inserted id=$id meta=${alert.meta}',
      name: 'alert_service',
    );
    return id;
  }

  // Red Alert (decoy PIN triggered)
  static Future<int> createRedAlert({String? extraMeta}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final loc = await _fetchLocation();
    final metaMap = {
      if (extraMeta != null) 'note': extraMeta,
      'reason': 'red_alert_decoy_pin',
    };
    final alert = AlertModel(
      type: AlertType.redAlert.name,
      timestamp: now,
      latitude: loc['lat'],
      longitude: loc['lon'],
      synced: false,
      meta: jsonEncode(metaMap),
    );
    final id = await DBHelper().insertAlert(alert);
    developer.log(
      'RedAlert inserted id=$id meta=${alert.meta}',
      name: 'alert_service',
    );
    return id;
  }

  // Low battery alert
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
    final alert = AlertModel(
      type: AlertType.lowBattery.name,
      timestamp: now,
      latitude: loc['lat'],
      longitude: loc['lon'],
      synced: false,
      meta: jsonEncode(metaMap),
    );
    final id = await DBHelper().insertAlert(alert);
    developer.log(
      'LowBattery inserted id=$id meta=${alert.meta}',
      name: 'alert_service',
    );
    return id;
  }

  // Fetch all alerts
  static Future<List<AlertModel>> getAllAlerts() async {
    return DBHelper().getAllAlerts();
  }
}
