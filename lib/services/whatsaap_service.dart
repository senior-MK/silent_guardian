// lib/services/whatsapp_service.dart
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class WhatsappService {
  /// Opens a WhatsApp chat (wa.me) with a prefilled message derived from the alert.
  /// Returns true if the URL could be launched, false otherwise.
  Future<bool> sendWhatsAppMessage(
    String phone,
    Map<String, dynamic> alert,
  ) async {
    try {
      final text = _buildAlertMessage(alert);
      final url = Uri.parse(
        'https://wa.me/$phone?text=${Uri.encodeComponent(text)}',
      );
      return await canLaunchUrl(url)
          ? await launchUrl(url, mode: LaunchMode.externalApplication)
          : false;
    } catch (e) {
      return false;
    }
  }

  /// Share files via the system share sheet — user picks WhatsApp if desired.
  Future<void> shareFilesToWhatsapp(List<String> filePaths, String text) async {
    await Share.shareXFiles(
      filePaths.map((p) => XFile(p)).toList(),
      text: text,
    );
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
