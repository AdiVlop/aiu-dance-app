import 'package:url_launcher/url_launcher.dart';

void openUrlWeb(String url) {
  // Nu se folosește pe mobile
}

Future<void> openUrlMobile(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    throw 'Could not launch $url';
  }
}

void reloadWebApp() {
  // Nu se folosește pe mobile
}






