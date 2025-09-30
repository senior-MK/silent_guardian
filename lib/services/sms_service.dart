// lib/services/sms_service.dart
import 'package:telephony/telephony.dart';
import 'package:url_launcher/url_launcher.dart';

class SmsService {
  final Telephony telephony = Telephony.instance;

  /// Ask for SMS permission (Android only)
  Future<bool> requestPermissions() async {
    try {
      final granted = await telephony.requestSmsPermissions;
      return granted ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Send SMS silently (Android only)
  Future<bool> sendPlainSmsAndroid(String to, String message) async {
    try {
      await telephony.sendSms(to: to, message: message);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Cross-platform wrapper
  Future<bool> sendSmsPlatformAware(String to, String message) async {
    try {
      final perms = await telephony.requestSmsPermissions;
      if (perms == true) {
        await telephony.sendSms(to: to, message: message);
        return true;
      }
    } catch (e) {
      // fallback below
    }

    // iOS (and Android fallback): open Messages app
    final uri = Uri.parse('sms:$to?body=${Uri.encodeComponent(message)}');
    return await launchUrl(uri);
  }
}
