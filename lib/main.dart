import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/dashboard_screen.dart';
import 'services/location_service.dart'; // ✅ added for permissions
import 'services/battery_service.dart'; // ✅ added for battery monitoring

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

  runApp(const SilentGuardianApp());
}

class SilentGuardianApp extends StatelessWidget {
  const SilentGuardianApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // ✅ cleaner UI
      title: 'Silent Guardian',
      theme: ThemeData(primarySwatch: Colors.deepPurple),

      // ✅ Start directly on Dashboard
      initialRoute: '/dashboard',

      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/dashboard': (context) => const DashboardScreen(),
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
