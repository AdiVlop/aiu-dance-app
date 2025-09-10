import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../utils/logger.dart';

class AdminCoursePaymentsScreen extends StatefulWidget {
  const AdminCoursePaymentsScreen({Key? key}) : super(key: key);

  @override
  State<AdminCoursePaymentsScreen> createState() => _AdminCoursePaymentsScreenState();
}

class _AdminCoursePaymentsScreenState extends State<AdminCoursePaymentsScreen> {
  List<Map<String, dynamic>> _payments = [];
  List<Map<String, dynamic>> _filteredPayments = [];
  bool _isLoading = true;
  String _selectedStatus = 'all';
  String _selectedMethod = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadPayments() async {
    try {
      setState(() => _isLoading = true);
      
      final response = await Supabase.instance.client
          .from('course_payments')
          .select('''
            id,
            method,
            authorized,
            status,
            amount,
            proof_url,
            admin_note,
            created_at,
            authorized_at,
            user_id,
            course_id,
            profiles!course_payments_user_id_fkey(full_name, email),
            courses!course_payments_course_id_fkey(title, category),
            authorized_profile:profiles!course_payments_authorized_by_fkey(full_name)
          ''')
          .order('created_at', ascending: false);

      setState(() {
        _payments = List<Map<String, dynamic>>.from(response);
        _filteredPayments = _payments;
        _isLoading = false;
      });
      
      Logger.info('Loaded ${_payments.length} course payments');
    } catch (e) {
      Logger.error('Error loading course payments: $e');
      _showErrorSnackBar('Eroare la încărcarea plăților');
      setState(() => _isLoading = false);
    }
  }

  void _filterPayments() {
    setState(() {
      _filteredPayments = _payments.where((payment) {
        final matchesStatus = _selectedStatus == 'all' || payment['status'] == _selectedStatus;
        final matchesMethod = _selectedMethod == 'all' || payment['method'] == _selectedMethod;
        final matchesSearch = _searchQuery.isEmpty ||
            payment['profiles']['full_name']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) == true ||
            payment['profiles']['email']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) == true ||
            payment['courses']['title']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) == true;
        
        return matchesStatus && matchesMethod && matchesSearch;
      }).toList();
    });
  }

  Future<void> _updatePaymentMethod(String paymentId, String method) async {
    try {
      await Supabase.instance.client
          .from('course_payments')
          .update({'method': method})
          .eq('id', paymentId);

      _showSuccessSnackBar('Metoda de plată actualizată');
      _loadPayments();
    } catch (e) {
      Logger.error('Error updating payment method: $e');
      _showErrorSnackBar('Eroare la actualizarea metodei de plată');
    }
  }

  Future<void> _authorizePayment(String paymentId, bool authorize) async {
    try {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      
      await Supabase.instance.client
          .from('course_payments')
          .update({
            'authorized': authorize,
            'authorized_by': authorize ? currentUserId : null,
            'authorized_at': authorize ? DateTime.now().toIso8601String() : null,
            'status': authorize ? 'authorized' : 'pending'
          })
          .eq('id', paymentId);

      _showSuccessSnackBar(authorize ? 'Plată autorizată' : 'Autorizare anulată');
      _loadPayments();
    } catch (e) {
      Logger.error('Error authorizing payment: $e');
      _showErrorSnackBar('Eroare la autorizarea plății');
    }
  }

  Future<void> _markAsPaid(String paymentId) async {
    try {
      await Supabase.instance.client
          .from('course_payments')
          .update({'status': 'paid'})
          .eq('id', paymentId);

      _showSuccessSnackBar('Plată marcată ca efectuată');
      _loadPayments();
    } catch (e) {
      Logger.error('Error marking payment as paid: $e');
      _showErrorSnackBar('Eroare la marcarea plății');
    }
  }

  Future<void> _addAdminNote(String paymentId, String currentNote) async {
    _noteController.text = currentNote ?? '';
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adaugă notă admin'),
        content: TextField(
          controller: _noteController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Introduceți nota...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anulează'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, _noteController.text),
            child: const Text('Salvează'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        await Supabase.instance.client
            .from('course_payments')
            .update({'admin_note': result})
            .eq('id', paymentId);

        _showSuccessSnackBar('Nota admin actualizată');
        _loadPayments();
      } catch (e) {
        Logger.error('Error updating admin note: $e');
        _showErrorSnackBar('Eroare la actualizarea notei');
      }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plăți Cursuri'),
        backgroundColor: const Color(0xFF5C001F),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPayments,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredPayments.isEmpty
                    ? const Center(
                        child: Text(
                          'Nu există plăți',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : _buildPaymentsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade50,
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Caută utilizator, email sau curs...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              _searchQuery = value;
              _filterPayments();
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Toate')),
                    DropdownMenuItem(value: 'pending', child: Text('În așteptare')),
                    DropdownMenuItem(value: 'authorized', child: Text('Autorizat')),
                    DropdownMenuItem(value: 'paid', child: Text('Plătit')),
                    DropdownMenuItem(value: 'declined', child: Text('Refuzat')),
                  ],
                  onChanged: (value) {
                    _selectedStatus = value!;
                    _filterPayments();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedMethod,
                  decoration: const InputDecoration(
                    labelText: 'Metodă',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Toate')),
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'wallet', child: Text('Wallet')),
                    DropdownMenuItem(value: 'revolut', child: Text('Revolut')),
                    DropdownMenuItem(value: 'rate', child: Text('Rate')),
                  ],
                  onChanged: (value) {
                    _selectedMethod = value!;
                    _filterPayments();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsList() {
    return ListView.builder(
      itemCount: _filteredPayments.length,
      itemBuilder: (context, index) {
        final payment = _filteredPayments[index];
        return _buildPaymentCard(payment);
      },
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    final userProfile = payment['profiles'] as Map<String, dynamic>?;
    final course = payment['courses'] as Map<String, dynamic>?;
    final authorizedProfile = payment['authorized_profile'] as Map<String, dynamic>?;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userProfile?['full_name'] ?? 'Necunoscut',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        userProfile?['email'] ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(payment['status']),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.school, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    course?['title'] ?? 'Curs necunoscut',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.payment, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  _getMethodDisplayName(payment['method']),
                  style: const TextStyle(fontSize: 14),
                ),
                const Spacer(),
                Text(
                  '${payment['amount']} RON',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            if (payment['admin_note'] != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(Icons.note, size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        payment['admin_note'],
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (payment['authorized'] == true && authorizedProfile != null) ...[
              const SizedBox(height: 8),
              Text(
                'Autorizat de: ${authorizedProfile['full_name']}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green.shade700,
                ),
              ),
            ],
            const SizedBox(height: 12),
            _buildActionButtons(payment),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    
    switch (status) {
      case 'paid':
        color = Colors.green;
        label = 'Plătit';
        break;
      case 'authorized':
        color = Colors.blue;
        label = 'Autorizat';
        break;
      case 'declined':
        color = Colors.red;
        label = 'Refuzat';
        break;
      default:
        color = Colors.orange;
        label = 'În așteptare';
    }
    
    return Chip(
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> payment) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Schimbă metoda de plată
        PopupMenuButton<String>(
          child: const Chip(
            label: Text('Schimbă metoda'),
            avatar: Icon(Icons.edit, size: 16),
          ),
          onSelected: (method) => _updatePaymentMethod(payment['id'], method),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'cash', child: Text('Cash')),
            const PopupMenuItem(value: 'wallet', child: Text('Wallet')),
            const PopupMenuItem(value: 'revolut', child: Text('Revolut')),
            const PopupMenuItem(value: 'rate', child: Text('Rate')),
          ],
        ),
        
        // Autorizează/Anulează autorizarea (doar pentru rate)
        if (payment['method'] == 'rate')
          InkWell(
            onTap: () => _authorizePayment(payment['id'], !payment['authorized']),
            child: Chip(
              label: Text(payment['authorized'] ? 'Anulează autorizarea' : 'Autorizează'),
              avatar: Icon(
                payment['authorized'] ? Icons.cancel : Icons.check,
                size: 16,
              ),
              backgroundColor: payment['authorized'] ? Colors.red.shade100 : Colors.green.shade100,
            ),
          ),
        
        // Marchează ca plătit
        if (payment['status'] != 'paid')
          InkWell(
            onTap: () => _markAsPaid(payment['id']),
            child: const Chip(
              label: Text('Marchează plătit'),
              avatar: Icon(Icons.check_circle, size: 16),
              backgroundColor: Colors.green,
            ),
          ),
        
        // Adaugă/Editează notă
        InkWell(
          onTap: () => _addAdminNote(payment['id'], payment['admin_note'] ?? ''),
          child: const Chip(
            label: Text('Notă admin'),
            avatar: Icon(Icons.note_add, size: 16),
          ),
        ),
      ],
    );
  }

  String _getMethodDisplayName(String? method) {
    switch (method) {
      case 'cash':
        return 'Cash';
      case 'wallet':
        return 'Wallet';
      case 'revolut':
        return 'Revolut';
      case 'rate':
        return 'Rate';
      default:
        return 'Necunoscut';
    }
  }
}
