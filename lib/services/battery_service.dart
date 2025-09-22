// lib/services/battery_service.dart
import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'alert_service.dart';

class BatteryService {
  static final Battery _battery = Battery();
  static Timer? _timer;

  /// Start monitoring battery level automatically
  static void startMonitoring({
    int threshold = 15, // default trigger at 15%
    Duration interval = const Duration(minutes: 1), // check every 1 minute
  }) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) async {
      final level = await _battery.batteryLevel;
      if (level <= threshold) {
        await AlertService.createLowBatteryAlert(batteryLevel: level);
      }
    });
  }

  /// Stop monitoring
  static void stopMonitoring() {
    _timer?.cancel();
    _timer = null;
  }
}
