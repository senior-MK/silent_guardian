// lib/services/sms_service.dart
import 'package:telephony/telephony.dart';
import 'package:url_launcher/url_launcher.dart';

class SmsService {
  final Telephony _telephony = Telephony.instance;

  /// Send an alert SMS. Uses silent send on Android when permission is granted,
  /// otherwise falls back to opening the native Messages composer.
  /// Returns true when the action to send/open succeeded, false on error.
  Future<bool> sendAlertSms(String phone, Map<String, dynamic> alert) async {
    final String msg = _buildAlertMessage(alert);

    try {
      // Request SMS permission if required
      bool? perms;
      try {
        perms = await _telephony.requestSmsPermissions;
      } catch (_) {
        perms = false;
      }

      if (perms == true) {
        // Attempt silent send on Android
        try {
          await _telephony.sendSms(to: phone, message: msg);
          return true;
        } catch (e) {
          // Fall through to composer fallback
        }
      }

      // Fallback (iOS / permission denied / send failed): open SMS composer
      final uri = Uri.parse('sms:$phone?body=${Uri.encodeComponent(msg)}');
      return await canLaunchUrl(uri) ? await launchUrl(uri) : false;
    } catch (e) {
      return false;
    }
  }

  String _buildAlertMessage(Map<String, dynamic> alert) {
    final type = alert['type'] ?? 'alert';
    final tsVal = alert['timestamp'];
    String timeString = '';
    if (tsVal is int) {
      final dt = DateTime.fromMillisecondsSinceEpoch(tsVal).toLocal();
      timeString = dt.toIso8601String();
    }
    final lat = alert['latitude']?.toString() ?? 'N/A';
    final lon = alert['longitude']?.toString() ?? 'N/A';
    final meta = alert['meta'] ?? '';

    return 'SilentGuardian ALERT\n'
        'Type: $type\n'
        'Time: $timeString\n'
        'Location: $lat, $lon\n'
        '${meta.isNotEmpty ? 'Info: $meta\n' : ''}'
        '—';
  }
}
