import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

// Conditional imports pentru platforme
import 'platform_utils_web.dart' if (dart.library.io) 'platform_utils_mobile.dart' as platform_impl;

class PlatformUtils {
  /// Deschide un URL într-un tab nou (web) sau browser (mobile)
  static Future<void> openUrl(String url) async {
    try {
      if (kIsWeb) {
        platform_impl.openUrlWeb(url);
      } else {
        await platform_impl.openUrlMobile(url);
      }
    } catch (e) {
      print('Error opening URL: $e');
      // Fallback cu url_launcher
      await _fallbackOpenUrl(url);
    }
  }

  static Future<void> _fallbackOpenUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('Fallback URL launch failed: $e');
    }
  }

  /// Reîncarcă aplicația (doar pe web)
  static void reloadApp() {
    if (kIsWeb) {
      platform_impl.reloadWebApp();
    }
  }
}
