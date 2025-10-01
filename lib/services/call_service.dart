// lib/services/call_service.dart
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'dart:io';

class CallService {
  Future<bool> makeCall(String phone) async {
    try {
      if (Platform.isAndroid) {
        // Direct call (requires CALL_PHONE permission)
        return await FlutterPhoneDirectCaller.callNumber(phone);
      } else {
        final uri = Uri.parse('tel:$phone');
        return await launchUrl(uri);
      }
    } catch (e) {
      return false;
    }
  }
}
