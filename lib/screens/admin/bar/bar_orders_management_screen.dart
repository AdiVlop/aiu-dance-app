import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/bar_service.dart';
import '../../../utils/logger.dart';
import 'dart:convert';

class BarOrdersManagementScreen extends StatefulWidget {
  const BarOrdersManagementScreen({super.key});

  @override
  State<BarOrdersManagementScreen> createState() => _BarOrdersManagementScreenState();
}

class _BarOrdersManagementScreenState extends State<BarOrdersManagementScreen> {
  final BarService _barService = BarService();
  
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    
    try {
      // Mock orders pentru demonstrație
      final orders = [
        {
          'id': 'order-1',
          'user_id': 'user-1',
          'product_name': 'Cafea Latte',
          'quantity': 2,
          'unit_price': 12.0,
          'total_price': 24.0,
          'status': 'pending',
          'payment_status': 'unpaid',
          'created_at': DateTime.now().subtract(const Duration(minutes: 10)).toIso8601String(),
          'user': {'full_name': 'Adrian Student', 'email': 'adrian@student.com'},
          'qr_code_id': null,
        },
        {
          'id': 'order-2',
          'user_id': 'user-2',
          'product_name': 'Sandwich Club',
          'quantity': 1,
          'unit_price': 18.0,
          'total_price': 18.0,
          'status': 'pending',
          'payment_status': 'unpaid',
          'created_at': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
          'user': {'full_name': 'Maria Popescu', 'email': 'maria@student.com'},
          'qr_code_id': null,
        },
        {
          'id': 'order-3',
          'user_id': 'user-3',
          'product_name': 'Apă Minerală',
          'quantity': 3,
          'unit_price': 5.0,
          'total_price': 15.0,
          'status': 'completed',
          'payment_status': 'paid',
          'created_at': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
          'user': {'full_name': 'Ion Georgescu', 'email': 'ion@student.com'},
          'qr_code_id': 'qr-123',
        },
      ];
      
      if (mounted) {
        setState(() {
          _orders = orders;
          _isLoading = false;
        });
      }
    } catch (e) {
      Logger.error('Error loading bar orders: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare la încărcarea comenzilor: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredOrders {
    if (_selectedStatus == 'all') return _orders;
    return _orders.where((order) => order['status'] == _selectedStatus).toList();
  }

  Future<void> _generatePaymentQR(Map<String, dynamic> order) async {
    try {
      // Generează QR payload pentru plată
      final qrPayload = {
        'type': 'bar_payment',
        'order_id': order['id'],
        'amount': order['total_price'],
        'currency': 'RON',
        'product_name': order['product_name'],
        'quantity': order['quantity'],
        'customer_name': order['user']['full_name'],
        'expires_at': DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
        'generated_at': DateTime.now().toIso8601String(),
      };

      // Afișează QR code-ul în dialog
      _showPaymentQRDialog(order, qrPayload);

    } catch (e) {
      Logger.error('Error generating payment QR: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare la generarea QR: $e')),
      );
    }
  }

  void _showPaymentQRDialog(Map<String, dynamic> order, Map<String, dynamic> qrPayload) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.qr_code, color: Colors.orange.shade600, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'QR Code pentru Plată',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Order details
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Comandă #${order['id']}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Client: ${order['user']['full_name']}'),
                    Text('Produs: ${order['product_name']}'),
                    Text('Cantitate: ${order['quantity']}'),
                    const SizedBox(height: 8),
                    Text(
                      'Total: ${order['total_price'].toStringAsFixed(2)} RON',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // QR Code
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Scanează pentru a plăti:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    QrImageView(
                      data: jsonEncode(qrPayload),
                      version: QrVersions.auto,
                      size: 200.0,
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Expiră în 2 ore',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Actions
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Închide'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _markAsPaid(order);
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Marchează Plătit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _markAsPaid(Map<String, dynamic> order) async {
    try {
      // Simulează marcarea ca plătită
      setState(() {
        final index = _orders.indexWhere((o) => o['id'] == order['id']);
        if (index != -1) {
          _orders[index]['payment_status'] = 'paid';
          _orders[index]['status'] = 'preparing';
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Comanda #${order['id']} marcată ca plătită!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Logger.error('Error marking as paid: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare: $e')),
      );
    }
  }

  Future<void> _updateOrderStatus(Map<String, dynamic> order, String newStatus) async {
    try {
      setState(() {
        final index = _orders.indexWhere((o) => o['id'] == order['id']);
        if (index != -1) {
          _orders[index]['status'] = newStatus;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Statusul comenzii #${order['id']} actualizat!'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      Logger.error('Error updating order status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionare Comenzi Bar'),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: Column(
        children: [
          // Status filter
          Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStatusChip('all', 'Toate'),
                  const SizedBox(width: 8),
                  _buildStatusChip('pending', 'În așteptare'),
                  const SizedBox(width: 8),
                  _buildStatusChip('preparing', 'În pregătire'),
                  const SizedBox(width: 8),
                  _buildStatusChip('completed', 'Finalizate'),
                ],
              ),
            ),
          ),

          // Orders list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredOrders.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadOrders,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredOrders.length,
                          itemBuilder: (context, index) {
                            final order = _filteredOrders[index];
                            return _buildOrderCard(order);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String value, String label) {
    final isSelected = _selectedStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedStatus = value);
      },
      backgroundColor: Colors.white,
      selectedColor: Colors.orange.shade100,
      checkmarkColor: Colors.orange.shade600,
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] ?? 'pending';
    final paymentStatus = order['payment_status'] ?? 'unpaid';
    final isPaid = paymentStatus == 'paid';
    
    Color statusColor = Colors.orange;
    if (status == 'completed') statusColor = Colors.green;
    if (status == 'preparing') statusColor = Colors.blue;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Comandă #${order['id']}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPaid ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isPaid ? 'PLĂTIT' : 'NEPLĂTIT',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Order details
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Client: ${order['user']['full_name']}'),
                      Text('Produs: ${order['product_name']}'),
                      Text('Cantitate: ${order['quantity']}'),
                      const SizedBox(height: 8),
                      Text(
                        'Total: ${order['total_price'].toStringAsFixed(2)} RON',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Text(
                      _formatTime(order['created_at']),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                // Generate QR button
                if (!isPaid) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _generatePaymentQR(order),
                      icon: const Icon(Icons.qr_code),
                      label: const Text('Generează QR Plată'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade600,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                
                // Status update button
                Expanded(
                  child: PopupMenuButton<String>(
                    onSelected: (newStatus) => _updateOrderStatus(order, newStatus),
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'pending', child: Text('În așteptare')),
                      const PopupMenuItem(value: 'preparing', child: Text('În pregătire')),
                      const PopupMenuItem(value: 'ready', child: Text('Gata')),
                      const PopupMenuItem(value: 'completed', child: Text('Finalizată')),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit, size: 16, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            'Status',
                            style: TextStyle(color: statusColor),
                          ),
                          Icon(Icons.arrow_drop_down, color: statusColor),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Mark as paid button
                if (!isPaid) ...[
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _markAsPaid(order),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Plătit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Nu există comenzi',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Comenzile vor apărea aici când sunt plasate',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inMinutes < 60) {
        return 'acum ${difference.inMinutes}m';
      } else if (difference.inHours < 24) {
        return 'acum ${difference.inHours}h';
      } else {
        return '${date.day}/${date.month}';
      }
    } catch (e) {
      return '';
    }
  }
}






