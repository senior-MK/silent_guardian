import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/dashboard_screen.dart';
import 'services/location_service.dart'; // ✅ added for permissions

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Request location permissions before running app
  try {
    await LocationService.getCurrentLocation();
  } catch (e) {
    debugPrint("⚠️ Location not available at startup: $e");
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
