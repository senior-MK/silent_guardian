// lib/services/whatsapp_service.dart
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class WhatsappService {
  Future<bool> openChat(String phone, String text) async {
    // Use wa.me link
    final url = Uri.parse(
      'https://wa.me/$phone?text=${Uri.encodeComponent(text)}',
    );
    return await canLaunchUrl(url) ? await launchUrl(url) : false;
  }

  Future<void> shareFilesToWhatsapp(List<String> filePaths, String text) async {
    // share_plus will open share sheet; user selects WhatsApp
    await Share.shareFiles(filePaths, text: text);
  }
}
