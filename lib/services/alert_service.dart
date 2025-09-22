import 'dart:developer' as developer;
import '../models/alert.dart';
import 'db_helper.dart';
import 'location_service.dart'; // 👈 add this import

class AlertService {
  // Panic/test alert that now tries to include location
  static Future<int> createTestAlert({String meta = 'test'}) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // 1. Try to get last known position
    final position = await LocationService.getLastKnownPosition();

    // 2. Build alert model
    final alert = AlertModel(
      type: 'panic',
      timestamp: now,
      synced: false,
      meta: meta,
      latitude: position?.latitude, // 👈 added
      longitude: position?.longitude, // 👈 added
    );

    // 3. Insert into DB
    final id = await DBHelper().insertAlert(alert);

    // 4. Debug log
    developer.log(
      'Alert: inserted id=$id meta=$meta lat=${alert.latitude}, lon=${alert.longitude}',
      name: 'alert_service',
    );
    return id;
  }

  static Future<List<AlertModel>> getAllAlerts() async {
    return DBHelper().getAllAlerts();
  }
}
