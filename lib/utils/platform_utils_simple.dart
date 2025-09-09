import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class PlatformUtils {
  /// Deschide un URL pe toate platformele
  static Future<void> openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      print('Error opening URL: $e');
    }
  }

  /// Partajează conținut pe toate platformele
  static Future<void> shareContent(String content, {String? subject}) async {
    try {
      await Share.share(content, subject: subject);
    } catch (e) {
      print('Error sharing content: $e');
    }
  }

  /// Reîncarcă aplicația (doar pe web)
  static void reloadApp() {
    if (kIsWeb) {
      // Pentru web, afișează mesaj să reîncarce manual
      print('Please reload the web page manually');
    }
  }

  /// Deschide WhatsApp cu mesaj (cross-platform)
  static Future<void> openWhatsApp(String message) async {
    try {
      final encodedMessage = Uri.encodeComponent(message);
      final whatsappUrl = 'https://wa.me/?text=$encodedMessage';
      await openUrl(whatsappUrl);
    } catch (e) {
      // Fallback la share general
      await shareContent(message, subject: 'AIU Dance');
    }
  }
}
