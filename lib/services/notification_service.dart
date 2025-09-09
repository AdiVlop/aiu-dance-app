import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _supabase = Supabase.instance.client;

  /// Get notifications for current user
  Future<List<Map<String, dynamic>>> getNotifications({
    bool unreadOnly = false,
    int limit = 50,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      var query = _supabase
          .from('notifications')
          .select('*')
          .eq('user_id', userId);

      if (unreadOnly) {
        query = query.eq('read', false);
      }

      final response = await query
          .order('sent_at', ascending: false)
          .limit(limit > 0 ? limit : 1000);
      Logger.info('Loaded ${response.length} notifications');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      Logger.error('Error loading notifications: $e');
      return [];
    }
  }

  /// Get unread notifications count
  Future<int> getUnreadCount() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      final response = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('read', false);

      return response.length;
    } catch (e) {
      Logger.error('Error getting unread count: $e');
      return 0;
    }
  }

  /// Mark notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({
            'read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId);

      Logger.info('Marked notification as read: $notificationId');
      return true;
    } catch (e) {
      Logger.error('Error marking notification as read: $e');
      return false;
    }
  }

  /// Mark all notifications as read
  Future<bool> markAllAsRead() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase
          .from('notifications')
          .update({
            'read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('read', false);

      Logger.info('Marked all notifications as read');
      return true;
    } catch (e) {
      Logger.error('Error marking all notifications as read: $e');
      return false;
    }
  }

  /// Create notification (Admin only)
  Future<bool> createNotification({
    required String userId,
    required String title,
    required String body,
    String type = 'info',
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _supabase
          .from('notifications')
          .insert({
            'user_id': userId,
            'title': title,
            'body': body,
            'type': type,
            'metadata': metadata,
            'sent_at': DateTime.now().toIso8601String(),
          });

      Logger.info('Created notification for user: $userId');
      return true;
    } catch (e) {
      Logger.error('Error creating notification: $e');
      return false;
    }
  }

  /// Create enrollment notification
  Future<bool> createEnrollmentNotification({
    required String userId,
    required String courseTitle,
    required String courseId,
    required String enrollmentId,
  }) async {
    return await createNotification(
      userId: userId,
      title: 'Înscriere confirmată',
      body: 'Ai fost înscris cu succes la cursul "$courseTitle".',
      type: 'success',
      metadata: {
        'course_id': courseId,
        'enrollment_id': enrollmentId,
        'action_type': 'enrollment',
      },
    );
  }

  /// Create payment authorization notification
  Future<bool> createPaymentAuthorizationNotification({
    required String userId,
    required String courseTitle,
    required String paymentId,
    required bool approved,
  }) async {
    return await createNotification(
      userId: userId,
      title: approved ? 'Plată în rate aprobată' : 'Plată în rate refuzată',
      body: approved 
          ? 'Plata ta în rate pentru cursul "$courseTitle" a fost aprobată de administrator.'
          : 'Plata ta în rate pentru cursul "$courseTitle" a fost refuzată.',
      type: approved ? 'success' : 'error',
      metadata: {
        'payment_id': paymentId,
        'action_type': 'payment_authorization',
        'approved': approved,
      },
    );
  }

  /// Create payment confirmation notification
  Future<bool> createPaymentConfirmationNotification({
    required String userId,
    required String courseTitle,
    required String paymentId,
    required String paymentMethod,
    required double amount,
  }) async {
    String methodName;
    switch (paymentMethod) {
      case 'cash':
        methodName = 'cash';
        break;
      case 'wallet':
        methodName = 'wallet digital';
        break;
      case 'revolut':
        methodName = 'Revolut';
        break;
      case 'rate':
        methodName = 'rate';
        break;
      default:
        methodName = paymentMethod;
    }

    return await createNotification(
      userId: userId,
      title: 'Plată confirmată',
      body: 'Plata ta de ${amount.toStringAsFixed(2)} RON prin $methodName pentru cursul "$courseTitle" a fost confirmată.',
      type: 'success',
      metadata: {
        'payment_id': paymentId,
        'payment_method': paymentMethod,
        'amount': amount,
        'action_type': 'payment_confirmation',
      },
    );
  }

  /// Create general course notification
  Future<bool> createCourseNotification({
    required String userId,
    required String title,
    required String body,
    required String courseId,
    String type = 'info',
  }) async {
    return await createNotification(
      userId: userId,
      title: title,
      body: body,
      type: type,
      metadata: {
        'course_id': courseId,
        'action_type': 'course_update',
      },
    );
  }

  /// Send bulk notifications to multiple users
  Future<bool> sendBulkNotifications({
    required List<String> userIds,
    required String title,
    required String body,
    String type = 'info',
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final notifications = userIds.map((userId) => {
        'user_id': userId,
        'title': title,
        'body': body,
        'type': type,
        'metadata': metadata,
        'sent_at': DateTime.now().toIso8601String(),
      }).toList();

      await _supabase
          .from('notifications')
          .insert(notifications);

      Logger.info('Sent bulk notifications to ${userIds.length} users');
      return true;
    } catch (e) {
      Logger.error('Error sending bulk notifications: $e');
      return false;
    }
  }

  /// Listen to notifications in real-time
  Stream<List<Map<String, dynamic>>> listenToNotifications() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return Stream.empty();
    }

    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('sent_at', ascending: false);
  }

  /// Delete notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .delete()
          .eq('id', notificationId);

      Logger.info('Deleted notification: $notificationId');
      return true;
    } catch (e) {
      Logger.error('Error deleting notification: $e');
      return false;
    }
  }

  /// Clear all read notifications
  Future<bool> clearReadNotifications() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase
          .from('notifications')
          .delete()
          .eq('user_id', userId)
          .eq('read', true);

      Logger.info('Cleared all read notifications');
      return true;
    } catch (e) {
      Logger.error('Error clearing read notifications: $e');
      return false;
    }
  }
}
