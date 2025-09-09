import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aiu_dance/utils/logger.dart';
import 'package:intl/intl.dart';

class BarReceiptScreen extends StatefulWidget {
  final String? orderId;
  final String? receiptId;
  
  const BarReceiptScreen({
    super.key,
    this.orderId,
    this.receiptId,
  });

  @override
  State<BarReceiptScreen> createState() => _BarReceiptScreenState();
}

class _BarReceiptScreenState extends State<BarReceiptScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _receipt;
  Map<String, dynamic>? _order;

  @override
  void initState() {
    super.initState();
    _loadReceiptData();
  }

  Future<void> _loadReceiptData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.receiptId != null) {
        // Încarcă chitanța după ID
        await _loadReceiptById(widget.receiptId!);
      } else if (widget.orderId != null) {
        // Încarcă chitanța după comanda bar
        await _loadReceiptByOrderId(widget.orderId!);
      } else {
        throw Exception('Nu s-a specificat ID-ul chitanței sau comenzii');
      }
    } catch (e) {
      Logger.error('Error loading receipt: $e');
      if (mounted) {
        _showErrorSnackBar('Eroare la încărcarea chitanței: $e');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadReceiptById(String receiptId) async {
    final response = await Supabase.instance.client
        .from('bar_receipts')
        .select('''
          *,
          bar_order:bar_orders!bar_receipts_bar_order_id_fkey(
            id,
            user_id,
            product_name,
            quantity,
            total_price,
            status,
            created_at,
            user:profiles!bar_orders_user_id_fkey(full_name, email)
          )
        ''')
        .eq('id', receiptId)
        .single();

    setState(() {
      _receipt = response;
      _order = response['bar_order'];
    });
  }

  Future<void> _loadReceiptByOrderId(String orderId) async {
    final response = await Supabase.instance.client
        .from('bar_receipts')
        .select('''
          *,
          bar_order:bar_orders!bar_receipts_bar_order_id_fkey(
            id,
            user_id,
            product_name,
            quantity,
            total_price,
            status,
            created_at,
            user:profiles!bar_orders_user_id_fkey(full_name, email)
          )
        ''')
        .eq('bar_order_id', orderId)
        .single();

    setState(() {
      _receipt = response;
      _order = response['bar_order'];
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _shareReceipt() async {
    if (_receipt != null) {
      final receiptText = _generateReceiptText();
      await Clipboard.setData(ClipboardData(text: receiptText));
      _showSuccessSnackBar('Chitanța a fost copiată în clipboard');
    }
  }

  String _generateReceiptText() {
    if (_receipt == null || _order == null) return '';

    final user = _order!['user'] as Map<String, dynamic>?;
    final createdAt = DateTime.tryParse(_receipt!['created_at'] ?? '');
    final formattedDate = createdAt != null 
        ? DateFormat('dd.MM.yyyy HH:mm').format(createdAt)
        : 'Data necunoscută';

    return '''
═══════════════════════════════
         AIU DANCE BAR
═══════════════════════════════

Chitanță nr: ${_receipt!['receipt_number']}
Data: $formattedDate

Client: ${user?['full_name'] ?? 'Client necunoscut'}
Email: ${user?['email'] ?? 'N/A'}

═══════════════════════════════
PRODUSE:
═══════════════════════════════

${_order!['product_name']} x${_order!['quantity']}
Preț unitar: ${_formatCurrency(_order!['total_price'] / _order!['quantity'])}
Total: ${_formatCurrency(_order!['total_price'])}

═══════════════════════════════
TOTAL DE PLATĂ: ${_formatCurrency(_receipt!['total_amount'])}
Metoda plată: ${_getPaymentMethodLabel(_receipt!['payment_method'])}
═══════════════════════════════

Mulțumim pentru comandă!
AIU Dance Studio
''';
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '0.00 RON';
    final value = double.tryParse(amount.toString()) ?? 0.0;
    return '${value.toStringAsFixed(2)} RON';
  }

  String _getPaymentMethodLabel(String method) {
    switch (method.toLowerCase()) {
      case 'cash': return 'Numerar';
      case 'wallet': return 'Portofel Digital';
      case 'revolut': return 'Revolut';
      case 'qr': return 'QR Code';
      default: return method;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chitanță Bar'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_receipt != null)
            IconButton(
              onPressed: _shareReceipt,
              icon: const Icon(Icons.share),
              tooltip: 'Partajează chitanța',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Se încarcă chitanța...'),
                ],
              ),
            )
          : _receipt == null
              ? _buildErrorState()
              : _buildReceiptContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Chitanța nu a fost găsită',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Înapoi'),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptContent() {
    final user = _order!['user'] as Map<String, dynamic>?;
    final createdAt = DateTime.tryParse(_receipt!['created_at'] ?? '');
    final items = _receipt!['items'] as List<dynamic>? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Header
                  _buildReceiptHeader(),
                  
                  const SizedBox(height: 24),
                  
                  // Receipt Info
                  _buildReceiptInfo(),
                  
                  const SizedBox(height: 24),
                  
                  // Customer Info
                  _buildCustomerInfo(user),
                  
                  const SizedBox(height: 24),
                  
                  // Items
                  _buildItemsList(items),
                  
                  const SizedBox(height: 24),
                  
                  // Total
                  _buildTotal(),
                  
                  const SizedBox(height: 24),
                  
                  // Payment Info
                  _buildPaymentInfo(),
                  
                  const SizedBox(height: 32),
                  
                  // Footer
                  _buildReceiptFooter(),
                  
                  const SizedBox(height: 24),
                  
                  // Actions
                  _buildActions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: const Column(
            children: [
              Icon(
                Icons.local_bar,
                size: 32,
                color: Colors.orange,
              ),
              SizedBox(height: 8),
              Text(
                'AIU DANCE BAR',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              Text(
                'Chitanță Fiscală',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptInfo() {
    final createdAt = DateTime.tryParse(_receipt!['created_at'] ?? '');
    final formattedDate = createdAt != null 
        ? DateFormat('dd.MM.yyyy HH:mm').format(createdAt)
        : 'Data necunoscută';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nr. Chitanță:',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                _receipt!['receipt_number'] ?? 'N/A',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Data:',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                formattedDate,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfo(Map<String, dynamic>? user) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CLIENT:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user?['full_name'] ?? 'Client necunoscut',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (user?['email'] != null) ...[
            const SizedBox(height: 2),
            Text(
              user!['email'],
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemsList(List<dynamic> items) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PRODUSE:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map((item) => _buildItemRow(item)).toList(),
        ],
      ),
    );
  }

  Widget _buildItemRow(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              item['product_name'] ?? 'Produs necunoscut',
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'x${item['quantity'] ?? 1}',
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatCurrency(item['unit_price']),
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatCurrency(item['total_price']),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotal() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'TOTAL DE PLATĂ:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            _formatCurrency(_receipt!['total_amount']),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border.all(color: Colors.green.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text(
                'PLĂTIT:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          Text(
            _getPaymentMethodLabel(_receipt!['payment_method'] ?? ''),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptFooter() {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 8),
        Text(
          'Mulțumim pentru comandă!',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'AIU Dance Studio',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'www.aiu-dance.ro',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Înapoi'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _shareReceipt,
            icon: const Icon(Icons.share),
            label: const Text('Partajează'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
