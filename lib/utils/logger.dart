import 'package:flutter/foundation.dart';

class Logger {
  static const String _tag = '[AIU_DANCE]';

  // Debug logging
  static void debug(String message, [String? tag]) {
    if (kDebugMode) {
      final logTag = tag != null ? '$_tag[$tag]' : _tag;
      debugPrint('$logTag DEBUG: $message');
    }
  }

  // Info logging
  static void info(String message, [String? tag]) {
    if (kDebugMode) {
      final logTag = tag != null ? '$_tag[$tag]' : _tag;
      debugPrint('$logTag INFO: $message');
    }
  }

  // Warning logging
  static void warning(String message, [String? tag]) {
    if (kDebugMode) {
      final logTag = tag != null ? '$_tag[$tag]' : _tag;
      debugPrint('$logTag WARNING: $message');
    }
  }

  // Error logging
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('$_tag ERROR: $message');
      if (error != null) {
        debugPrint('$_tag ERROR DETAILS: $error');
      }
      if (stackTrace != null) {
        debugPrint('$_tag STACK TRACE: $stackTrace');
      }
    }
  }

  // Success logging
  static void success(String message, [String? tag]) {
    if (kDebugMode) {
      final logTag = tag != null ? '$_tag[$tag]' : _tag;
      debugPrint('$logTag SUCCESS: $message');
    }
  }

  // Performance logging
  static void performance(String operation, Duration duration) {
    if (kDebugMode) {
      debugPrint('$_tag PERFORMANCE: $operation took ${duration.inMilliseconds}ms');
    }
  }

  // API logging
  static void api(String endpoint, {String? method, Map<String, dynamic>? data}) {
    if (kDebugMode) {
      final methodStr = method ?? 'GET';
      debugPrint('$_tag API: $methodStr $endpoint');
      if (data != null) {
        debugPrint('$_tag API DATA: $data');
      }
    }
  }

  // Supabase logging
  static void supabase(String operation, [String? table, String? recordId]) {
    if (kDebugMode) {
      final details = table != null ? ' ($table${recordId != null ? '/$recordId' : ''})' : '';
      debugPrint('$_tag SUPABASE: $operation$details');
    }
  }

  // User action logging
  static void userAction(String action, [String? userId, Map<String, dynamic>? details]) {
    if (kDebugMode) {
      final userStr = userId != null ? ' (User: $userId)' : '';
      final detailsStr = details != null ? ' - $details' : '';
      debugPrint('$_tag USER_ACTION: $action$userStr$detailsStr');
    }
  }
}

