import 'package:geolocator/geolocator.dart';

class LocationService {
  // Ask for permission
  static Future<bool> _handlePermission() async {
    LocationPermission permission;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  // ✅ Get current GPS location (live fix)
  static Future<Position> getCurrentLocation() async {
    final hasPermission = await _handlePermission();
    if (!hasPermission) {
      throw Exception("Location permissions not granted");
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // ✅ Fallback: last known location
  static Future<Position?> getLastKnownPosition() async {
    return await Geolocator.getLastKnownPosition();
  }
}
