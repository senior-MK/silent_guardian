import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';

import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/dashboard_screen.dart';
import 'package:silent_guardian/ui/outbox/outbox_screen.dart';
// Removed duplicate or incorrect import
import 'services/location_service.dart';
import 'services/battery_service.dart';
import 'services/sync_service.dart'; // ✅ added for background sync

const String syncTaskKey = "sync_alerts_task";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == syncTaskKey) {
        final syncService = SyncService();
        await syncService.syncAlerts();
      }
    } catch (e) {
      debugPrint("⚠️ Background task error: $e");
    }
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Request location permissions before running app
  try {
    await LocationService.getCurrentLocation();
  } catch (e) {
    debugPrint("⚠️ Location not available at startup: $e");
  }

  // ✅ Start BatteryService monitoring at a 15% threshold
  try {
    BatteryService.startMonitoring(threshold: 15);
  } catch (e) {
    debugPrint("⚠️ Battery monitoring failed to start: $e");
  }

  // ✅ Initialize background sync worker
  await Workmanager().initialize(callbackDispatcher);
  await Workmanager().registerPeriodicTask(
    "silent_guardian_sync",
    syncTaskKey,
    frequency: const Duration(minutes: 15),
    initialDelay: const Duration(minutes: 1),
    backoffPolicy: BackoffPolicy.linear,
  );

  runApp(const SilentGuardianApp());
}

class SilentGuardianApp extends StatelessWidget {
  const SilentGuardianApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Silent Guardian',
      theme: ThemeData(primarySwatch: Colors.deepPurple),

      // ✅ Start directly on Dashboard
      initialRoute: '/dashboard',

      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/outbox': (context) => const OutboxScreen(),
        // Make sure OutboxScreen is defined in outbox_screen.dart and is exported as 'OutboxScreen'
      },

      builder: (context, child) {
        debugPrint(
          "🚀 Starting route: ${ModalRoute.of(context)?.settings.name}",
        );
        return child!;
      },
    );
  }
}
