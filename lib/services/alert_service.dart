import 'dart:developer' as developer;
import '../models/alert.dart';
import 'db_helper.dart';

class AlertService {
  // Simple panic/test alert that doesn't include location yet
  static Future<int> createTestAlert({String meta = 'test'}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final alert = AlertModel(
      type: 'panic',
      timestamp: now,
      synced: false,
      meta: meta,
    );
    final id = await DBHelper().insertAlert(alert);
    // optional: print to console for debug
    developer.log(
      'Alert: inserted alert id=$id meta=$meta',
      name: 'alert_service',
    );
    return id;
  }

  static Future<List<AlertModel>> getAllAlerts() async {
    return DBHelper().getAllAlerts();
  }
}
