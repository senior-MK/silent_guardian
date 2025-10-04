// lib/services/call_service.dart
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';

class CallService {
  /// Makes a phone call for alerting.
  /// On Android attempts a direct call (needs CALL_PHONE permission).
  /// On other platforms opens the dialer.
  /// Returns true on success, false on failure.
  Future<bool> makeAlertCall(String phone, Map<String, dynamic> alert) async {
    try {
      if (Platform.isAndroid) {
        final result = await FlutterPhoneDirectCaller.callNumber(phone);
        // callNumber returns bool? — coerce to non-null
        return result ?? false;
      } else {
        final uri = Uri.parse('tel:$phone');
        return await canLaunchUrl(uri) ? await launchUrl(uri) : false;
      }
    } catch (e) {
      return false;
    }
  }
}
