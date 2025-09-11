// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void openUrlWeb(String url) {
  html.window.open(url, '_blank');
}

void reloadWebApp() {
  html.window.location.reload();
}








