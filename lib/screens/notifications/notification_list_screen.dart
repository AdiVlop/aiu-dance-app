import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/notification_service.dart';
import '../../utils/logger.dart';

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({Key? key}) : super(key: key);

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  final NotificationService _notificationService = NotificationService();
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      setState(() => _isLoading = true);
      
      final notifications = await _notificationService.getNotifications(
        unreadOnly: _selectedFilter == 'unread',
        limit: 100,
      );
      
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      Logger.error('Error loading notifications: $e');
      setState(() => _isLoading = false);
      _showErrorSnackBar('Eroare la încărcarea notificărilor');
    }
  }

  Future<void> _markAsRead(String notificationId, int index) async {
    final success = await _notificationService.markAsRead(notificationId);
    if (success) {
      setState(() {
        _notifications[index]['read'] = true;
        _notifications[index]['read_at'] = DateTime.now().toIso8601String();
      });
    }
  }

  Future<void> _markAllAsRead() async {
    final success = await _notificationService.markAllAsRead();
    if (success) {
      setState(() {
        for (var notification in _notifications) {
          notification['read'] = true;
          notification['read_at'] = DateTime.now().toIso8601String();
        }
      });
      _showSuccessSnackBar('Toate notificările au fost marcate ca citite');
    } else {
      _showErrorSnackBar('Eroare la marcarea notificărilor');
    }
  }

  Future<void> _deleteNotification(String notificationId, int index) async {
    final success = await _notificationService.deleteNotification(notificationId);
    if (success) {
      setState(() {
        _notifications.removeAt(index);
      });
      _showSuccessSnackBar('Notificare ștearsă');
    } else {
      _showErrorSnackBar('Eroare la ștergerea notificării');
    }
  }

  Future<void> _clearReadNotifications() async {
    final success = await _notificationService.clearReadNotifications();
    if (success) {
      setState(() {
        _notifications.removeWhere((notification) => notification['read'] == true);
      });
      _showSuccessSnackBar('Notificările citite au fost șterse');
    } else {
      _showErrorSnackBar('Eroare la ștergerea notificărilor');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => n['read'] == false).length;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Notificări${unreadCount > 0 ? ' ($unreadCount)' : ''}'),
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'mark_all_read':
                  _markAllAsRead();
                  break;
                case 'clear_read':
                  _clearReadNotifications();
                  break;
                case 'refresh':
                  _loadNotifications();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: Row(
                  children: [
                    Icon(Icons.done_all),
                    SizedBox(width: 8),
                    Text('Marchează toate ca citite'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_read',
                child: Row(
                  children: [
                    Icon(Icons.clear_all),
                    SizedBox(width: 8),
                    Text('Șterge notificările citite'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 8),
                    Text('Reîmprospătează'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterTabs(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _notifications.isEmpty
                    ? _buildEmptyState()
                    : _buildNotificationsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      color: Colors.grey.shade100,
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () {
                setState(() => _selectedFilter = 'all');
                _loadNotifications();
              },
              child: Text(
                'Toate',
                style: TextStyle(
                  color: _selectedFilter == 'all' ? Colors.purple : Colors.grey,
                  fontWeight: _selectedFilter == 'all' ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
          Expanded(
            child: TextButton(
              onPressed: () {
                setState(() => _selectedFilter = 'unread');
                _loadNotifications();
              },
              child: Text(
                'Necitite',
                style: TextStyle(
                  color: _selectedFilter == 'unread' ? Colors.purple : Colors.grey,
                  fontWeight: _selectedFilter == 'unread' ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _selectedFilter == 'unread' 
                ? 'Nu ai notificări necitite'
                : 'Nu ai notificări',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Notificările vor apărea aici când sunt disponibile',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return _buildNotificationCard(notification, index);
        },
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification, int index) {
    final isRead = notification['read'] == true;
    final sentAt = DateTime.parse(notification['sent_at']);
    final formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(sentAt);
    
    return Dismissible(
      key: Key(notification['id']),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmare'),
            content: const Text('Dorești să ștergi această notificare?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Anulează'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Șterge'),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (direction) => _deleteNotification(notification['id'], index),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        color: isRead ? Colors.white : Colors.blue.shade50,
        child: InkWell(
          onTap: () => !isRead ? _markAsRead(notification['id'], index) : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification['title'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildTypeIcon(notification['type']),
                    const SizedBox(width: 8),
                    if (!isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  notification['body'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const Spacer(),
                    if (notification['metadata'] != null && 
                        notification['metadata']['action_type'] != null)
                      Chip(
                        label: Text(
                          _getActionTypeLabel(notification['metadata']['action_type']),
                          style: const TextStyle(fontSize: 10),
                        ),
                        backgroundColor: _getActionTypeColor(notification['metadata']['action_type']),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeIcon(String type) {
    IconData icon;
    Color color;
    
    switch (type) {
      case 'success':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'error':
        icon = Icons.error;
        color = Colors.red;
        break;
      case 'warning':
        icon = Icons.warning;
        color = Colors.orange;
        break;
      default:
        icon = Icons.info;
        color = Colors.blue;
    }
    
    return Icon(icon, size: 16, color: color);
  }

  String _getActionTypeLabel(String actionType) {
    switch (actionType) {
      case 'enrollment':
        return 'Înscriere';
      case 'payment_authorization':
        return 'Autorizare plată';
      case 'payment_confirmation':
        return 'Confirmare plată';
      case 'course_update':
        return 'Actualizare curs';
      default:
        return 'General';
    }
  }

  Color _getActionTypeColor(String actionType) {
    switch (actionType) {
      case 'enrollment':
        return Colors.green.shade100;
      case 'payment_authorization':
        return Colors.blue.shade100;
      case 'payment_confirmation':
        return Colors.purple.shade100;
      case 'course_update':
        return Colors.orange.shade100;
      default:
        return Colors.grey.shade100;
    }
  }
}
