import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aiu_dance/utils/logger.dart';

class AdminWalletScreen extends StatefulWidget {
  const AdminWalletScreen({super.key});

  @override
  State<AdminWalletScreen> createState() => _AdminWalletScreenState();
}

class _AdminWalletScreenState extends State<AdminWalletScreen> {
  List<Map<String, dynamic>> _wallets = [];
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _adminTransactions = [];
  bool _isLoading = true;
  double _totalBalance = 0.0;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadWalletData() async {
    try {
      setState(() => _isLoading = true);
      
      // Load wallets with user info
      final walletsResponse = await Supabase.instance.client
          .from('wallets')
          .select('''
            *,
            user:profiles!wallets_user_id_fkey(full_name, email, role)
          ''')
          .order('balance', ascending: false);

      // Load recent transactions
      final transactionsResponse = await Supabase.instance.client
          .from('wallet_transactions')
          .select('''
            *,
            user:profiles!wallet_transactions_user_id_fkey(full_name, email)
          ''')
          .order('created_at', ascending: false)
          .limit(50);

      // Load admin transactions
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      final adminTransactionsResponse = await Supabase.instance.client
          .from('admin_transactions')
          .select('*')
          .eq('admin_id', currentUserId ?? '')
          .order('created_at', ascending: false)
          .limit(20);

      setState(() {
        _wallets = List<Map<String, dynamic>>.from(walletsResponse);
        _transactions = List<Map<String, dynamic>>.from(transactionsResponse);
        _adminTransactions = List<Map<String, dynamic>>.from(adminTransactionsResponse);
        
        // Calculate total balance
        _totalBalance = _wallets.fold(0.0, (sum, wallet) => sum + (wallet['balance'] ?? 0.0));
        
        _isLoading = false;
      });
      
      Logger.info('Loaded ${_wallets.length} wallets, ${_transactions.length} transactions, and ${_adminTransactions.length} admin transactions');
    } catch (e) {
      Logger.error('Error loading wallet data: $e');
      setState(() => _isLoading = false);
      _showErrorSnackBar('Eroare la încărcarea datelor portofelului');
    }
  }

  List<Map<String, dynamic>> get _filteredWallets {
    if (_searchQuery.isEmpty) return _wallets;
    
    return _wallets.where((wallet) {
      final userName = wallet['user']?['full_name']?.toString().toLowerCase() ?? '';
      final userEmail = wallet['user']?['email']?.toString().toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      
      return userName.contains(query) || userEmail.contains(query);
    }).toList();
  }

  Future<void> _transferToUser(String userId, double amount) async {
    await _showTransferDialog(userId: userId, amount: amount);
  }

  Future<void> _showTransferDialog({String? userId, double? amount}) async {
    final amountController = TextEditingController(text: amount?.toString() ?? '');
    String? selectedUserId = userId;
    final descriptionController = TextEditingController();
    String transferType = 'internal'; // internal, external, bank

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Transfer Bani'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Transfer Type Selection
                DropdownButtonFormField<String>(
                  value: transferType,
                  decoration: const InputDecoration(
                    labelText: 'Tip Transfer',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'internal', child: Text('Transfer Intern (către utilizator)')),
                    DropdownMenuItem(value: 'external', child: Text('Transfer Extern (IBAN/Cont bancar)')),
                    DropdownMenuItem(value: 'bank', child: Text('Transfer Bancar (Revolut, N26, etc.)')),
                  ],
                  onChanged: (value) {
                    setDialogState(() => transferType = value!);
                  },
                ),
                const SizedBox(height: 16),
                
                // Internal Transfer - User Selection
                if (transferType == 'internal') ...[
                  DropdownButtonFormField<String>(
                    value: selectedUserId,
                    decoration: const InputDecoration(
                      labelText: 'Utilizator Destinatar',
                      border: OutlineInputBorder(),
                    ),
                    items: _wallets.map<DropdownMenuItem<String>>((wallet) => DropdownMenuItem<String>(
                      value: wallet['user_id'],
                      child: Text('${wallet['user']?['full_name']} (${wallet['user']?['email']})'),
                    )).toList(),
                    onChanged: (value) {
                      setDialogState(() => selectedUserId = value);
                    },
                  ),
                ],
                
                // External Transfer - Bank Details
                if (transferType == 'external') ...[
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'IBAN Destinatar',
                      border: OutlineInputBorder(),
                      hintText: 'RO49 AAAA 1B31 0075 9384 0000',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Nume Destinatar',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                
                // Bank Transfer - Bank Selection
                if (transferType == 'bank') ...[
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Bancă Destinatar',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'revolut', child: Text('Revolut')),
                      DropdownMenuItem(value: 'n26', child: Text('N26')),
                      DropdownMenuItem(value: 'wise', child: Text('Wise')),
                      DropdownMenuItem(value: 'other', child: Text('Altă bancă')),
                    ],
                    onChanged: (value) {},
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Cont Destinatar',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Sumă (RON)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descriere',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Anulează'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (amountController.text.isEmpty) {
                  _showErrorSnackBar('Introdu suma pentru transfer');
                  return;
                }

                final amount = double.tryParse(amountController.text);
                if (amount == null || amount <= 0) {
                  _showErrorSnackBar('Introdu o sumă validă');
                  return;
                }

                try {
                  String successMessage = '';
                  
                  switch (transferType) {
                    case 'internal':
                      if (selectedUserId == null) {
                        _showErrorSnackBar('Selectează utilizatorul destinatar');
                        return;
                      }
                      
                      // Create credit transaction
                      await Supabase.instance.client
                          .from('wallet_transactions')
                          .insert({
                            'user_id': selectedUserId,
                            'type': 'credit',
                            'amount': amount,
                            'description': descriptionController.text.isNotEmpty 
                                ? descriptionController.text 
                                : 'Transfer intern de la admin',
                            'created_at': DateTime.now().toIso8601String(),
                          });

                      // Update wallet balance
                      final currentWallet = _wallets.firstWhere((w) => w['user_id'] == selectedUserId);
                      final newBalance = (currentWallet['balance'] ?? 0.0) + amount;
                      
                      await Supabase.instance.client
                          .from('wallets')
                          .update({'balance': newBalance})
                          .eq('user_id', selectedUserId!);
                      
                      successMessage = 'Transferul intern a fost efectuat cu succes';
                      break;
                      
                    case 'external':
                      // For external transfers, we would integrate with banking APIs
                      // For now, we'll create a transaction record
                      await Supabase.instance.client
                          .from('wallet_transactions')
                          .insert({
                            'user_id': '9195288e-d88b-4178-b970-b13a7ed445cf', // Admin user
                            'type': 'debit',
                            'amount': amount,
                            'description': descriptionController.text.isNotEmpty 
                                ? '${descriptionController.text} (Transfer extern IBAN)'
                                : 'Transfer extern către IBAN',
                            'created_at': DateTime.now().toIso8601String(),
                          });
                      
                      successMessage = 'Transferul extern a fost inițiat. Verifică contul bancar.';
                      break;
                      
                    case 'bank':
                      // For bank transfers (Revolut, N26, etc.)
                      await Supabase.instance.client
                          .from('wallet_transactions')
                          .insert({
                            'user_id': '9195288e-d88b-4178-b970-b13a7ed445cf', // Admin user
                            'type': 'debit',
                            'amount': amount,
                            'description': descriptionController.text.isNotEmpty 
                                ? '${descriptionController.text} (Transfer bancar)'
                                : 'Transfer bancar către cont extern',
                            'created_at': DateTime.now().toIso8601String(),
                          });
                      
                      successMessage = 'Transferul bancar a fost inițiat. Verifică contul bancar.';
                      break;
                  }

                  _showSuccessSnackBar(successMessage);
                  Navigator.pop(context);
                  await _loadWalletData();
                } catch (e) {
                  Logger.error('Error processing transfer: $e');
                  _showErrorSnackBar('Eroare la procesarea transferului');
                }
              },
              child: const Text('Transferă'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Necunoscut';
    
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Necunoscut';
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin': return Colors.red;
      case 'instructor': return Colors.blue;
      case 'student': return Colors.green;
      default: return Colors.grey;
    }
  }

  Future<void> _showManualPaymentDialog() async {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    final proofController = TextEditingController();
    String? selectedUserId;
    String? selectedCourseId;
    String paymentMethod = 'cash';
    List<Map<String, dynamic>> users = [];
    List<Map<String, dynamic>> courses = [];

    // Load users and courses
    try {
      final usersResponse = await Supabase.instance.client
          .from('profiles')
          .select('id, full_name, email')
          .order('full_name');
      
      final coursesResponse = await Supabase.instance.client
          .from('courses')
          .select('id, title, price')
          .eq('is_active', true)
          .order('title');

      users = List<Map<String, dynamic>>.from(usersResponse);
      courses = List<Map<String, dynamic>>.from(coursesResponse);
    } catch (e) {
      Logger.error('Error loading data for manual payment: $e');
      _showErrorSnackBar('Eroare la încărcarea datelor');
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Înregistrare Plată Manuală'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // User selection
                  DropdownButtonFormField<String>(
                    value: selectedUserId,
                    decoration: const InputDecoration(
                      labelText: 'Selectează utilizatorul',
                      border: OutlineInputBorder(),
                    ),
                    items: users.map((user) {
                      return DropdownMenuItem<String>(
                        value: user['id'],
                        child: Text('${user['full_name']} (${user['email']})'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() => selectedUserId = value);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Course selection
                  DropdownButtonFormField<String>(
                    value: selectedCourseId,
                    decoration: const InputDecoration(
                      labelText: 'Selectează cursul',
                      border: OutlineInputBorder(),
                    ),
                    items: courses.map((course) {
                      return DropdownMenuItem<String>(
                        value: course['id'],
                        child: Text('${course['title']} (${course['price']} RON)'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedCourseId = value;
                        // Auto-fill amount with course price
                        final course = courses.firstWhere((c) => c['id'] == value, orElse: () => {});
                        if (course['price'] != null) {
                          amountController.text = course['price'].toString();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Payment method
                  DropdownButtonFormField<String>(
                    value: paymentMethod,
                    decoration: const InputDecoration(
                      labelText: 'Metoda de plată',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'cash', child: Text('Cash')),
                      DropdownMenuItem(value: 'revolut', child: Text('Revolut')),
                      DropdownMenuItem(value: 'bank', child: Text('Transfer bancar')),
                    ],
                    onChanged: (value) {
                      setDialogState(() => paymentMethod = value!);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Amount
                  TextField(
                    controller: amountController,
                    decoration: const InputDecoration(
                      labelText: 'Suma (RON)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  // Proof URL (optional)
                  TextField(
                    controller: proofController,
                    decoration: const InputDecoration(
                      labelText: 'Link dovadă plată (opțional)',
                      hintText: 'URL către chitanță, screenshot Revolut, etc.',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Admin note
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: 'Notă admin',
                      hintText: 'Detalii despre plată...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Anulează'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedUserId == null || selectedCourseId == null || amountController.text.isEmpty) {
                  _showErrorSnackBar('Te rog completează toate câmpurile obligatorii');
                  return;
                }

                final amount = double.tryParse(amountController.text);
                if (amount == null || amount <= 0) {
                  _showErrorSnackBar('Suma trebuie să fie un număr pozitiv');
                  return;
                }

                Navigator.pop(context);
                await _processManualPayment(
                  userId: selectedUserId!,
                  courseId: selectedCourseId!,
                  method: paymentMethod,
                  amount: amount,
                  proofUrl: proofController.text.isEmpty ? null : proofController.text,
                  adminNote: noteController.text.isEmpty ? null : noteController.text,
                );
              },
              child: const Text('Înregistrează Plata'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processManualPayment({
    required String userId,
    required String courseId,
    required String method,
    required double amount,
    String? proofUrl,
    String? adminNote,
  }) async {
    try {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      
      // Create payment record
      await Supabase.instance.client
          .from('course_payments')
          .insert({
            'user_id': userId,
            'course_id': courseId,
            'method': method,
            'amount': amount,
            'status': 'paid',
            'authorized': true,
            'authorized_by': currentUserId,
            'authorized_at': DateTime.now().toIso8601String(),
            'proof_url': proofUrl,
            'admin_note': adminNote,
          });

      // Create or update enrollment
      final existingEnrollment = await Supabase.instance.client
          .from('enrollments')
          .select('id')
          .eq('user_id', userId)
          .eq('course_id', courseId)
          .maybeSingle();

      if (existingEnrollment == null) {
        await Supabase.instance.client
            .from('enrollments')
            .insert({
              'user_id': userId,
              'course_id': courseId,
              'status': 'active',
              'payment_method': method,
              'payment_status': 'paid',
              'created_at': DateTime.now().toIso8601String(),
            });
      } else {
        await Supabase.instance.client
            .from('enrollments')
            .update({
              'payment_method': method,
              'payment_status': 'paid',
            })
            .eq('id', existingEnrollment['id']);
      }

      // Create wallet transaction for tracking
      await Supabase.instance.client
          .from('wallet_transactions')
          .insert({
            'user_id': userId,
            'type': 'debit',
            'amount': -amount,
            'description': 'Plată curs - înregistrare manuală',
            'metadata': {
              'course_id': courseId,
              'payment_method': method,
              'manual_entry': true,
              'admin_id': currentUserId,
            },
            'created_at': DateTime.now().toIso8601String(),
          });

      _showSuccessSnackBar('Plata a fost înregistrată cu succes!');
      _loadWalletData(); // Refresh data
    } catch (e) {
      Logger.error('Error processing manual payment: $e');
      _showErrorSnackBar('Eroare la înregistrarea plății');
    }
  }

  // ===============================================
  // NEW ADMIN WALLET EXTENDED FUNCTIONALITY
  // ===============================================

  Future<void> _showWithdrawFundsDialog() async {
    final amountController = TextEditingController();
    final targetController = TextEditingController();
    final descriptionController = TextEditingController();
    String method = 'cash';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.money_off, color: Colors.red),
              SizedBox(width: 8),
              Text('Retragere Fonduri'),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Method selection
                  DropdownButtonFormField<String>(
                    value: method,
                    decoration: const InputDecoration(
                      labelText: 'Metoda de retragere',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.payment),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'cash', child: Text('Cash')),
                      DropdownMenuItem(value: 'revolut', child: Text('Revolut')),
                      DropdownMenuItem(value: 'iban', child: Text('Transfer IBAN')),
                    ],
                    onChanged: (value) => setDialogState(() => method = value!),
                  ),
                  const SizedBox(height: 16),

                  // Target field (IBAN/Revolut tag)
                  if (method != 'cash') ...[
                    TextField(
                      controller: targetController,
                      decoration: InputDecoration(
                        labelText: method == 'revolut' ? 'Revolut tag (ex: @username)' : 'IBAN',
                        hintText: method == 'revolut' ? '@adi.ro' : 'RO49 AAAA 1B31 0075 9384 0000',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.account_balance),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Amount
                  TextField(
                    controller: amountController,
                    decoration: const InputDecoration(
                      labelText: 'Sumă (RON)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.euro),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  // Description
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Observații (opțional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.note),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Anulează'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (amountController.text.isEmpty) {
                  _showErrorSnackBar('Introdu suma pentru retragere');
                  return;
                }

                final amount = double.tryParse(amountController.text);
                if (amount == null || amount <= 0) {
                  _showErrorSnackBar('Introdu o sumă validă');
                  return;
                }

                if (method != 'cash' && targetController.text.isEmpty) {
                  _showErrorSnackBar('Introdu ${method == 'revolut' ? 'Revolut tag-ul' : 'IBAN-ul'}');
                  return;
                }

                Navigator.pop(context);
                await _processWithdrawFunds(
                  amount: amount,
                  method: method,
                  target: method == 'cash' ? 'Cash' : targetController.text,
                  description: descriptionController.text,
                );
              },
              child: const Text('Confirmă Retragerea'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processWithdrawFunds({
    required double amount,
    required String method,
    required String target,
    required String description,
  }) async {
    try {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId == null) {
        _showErrorSnackBar('Utilizator neautentificat');
        return;
      }

      // Record admin transaction
      await Supabase.instance.client
          .from('admin_transactions')
          .insert({
            'admin_id': currentUserId,
            'type': 'withdraw',
            'direction': 'out',
            'amount': amount,
            'method': method,
            'target': target,
            'description': description.isEmpty 
                ? 'Retragere fonduri $method' 
                : description,
            'status': 'completed',
            'metadata': {
              'withdrawal_type': method,
              'processed_at': DateTime.now().toIso8601String(),
            },
          });

      _showSuccessSnackBar('Retragerea de ${amount.toStringAsFixed(2)} RON a fost înregistrată cu succes!');
      await _loadWalletData();
    } catch (e) {
      Logger.error('Error processing withdraw funds: $e');
      _showErrorSnackBar('Eroare la procesarea retragerii');
    }
  }

  Future<void> _showTransferToUserDialog() async {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    String? selectedUserId;
    List<Map<String, dynamic>> users = [];

    // Load users
    try {
      final usersResponse = await Supabase.instance.client
          .from('profiles')
          .select('id, full_name, email, role')
          .neq('role', 'admin')
          .order('full_name');
      
      users = List<Map<String, dynamic>>.from(usersResponse);
    } catch (e) {
      Logger.error('Error loading users: $e');
      _showErrorSnackBar('Eroare la încărcarea utilizatorilor');
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.send, color: Colors.blue),
              SizedBox(width: 8),
              Text('Transfer către Utilizator'),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // User selection
                  DropdownButtonFormField<String>(
                    value: selectedUserId,
                    decoration: const InputDecoration(
                      labelText: 'Selectează utilizatorul',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    items: users.map((user) {
                      return DropdownMenuItem<String>(
                        value: user['id'],
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: _getRoleColor(user['role']),
                              child: Text(
                                user['full_name']?.toString().substring(0, 1).toUpperCase() ?? 'U',
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(user['full_name'] ?? 'Nume necunoscut'),
                                  Text(
                                    user['email'] ?? '',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) => setDialogState(() => selectedUserId = value),
                  ),
                  const SizedBox(height: 16),

                  // Amount
                  TextField(
                    controller: amountController,
                    decoration: const InputDecoration(
                      labelText: 'Sumă (RON)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.euro),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  // Description
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Observații',
                      hintText: 'Bonus performanță, rambursare, etc.',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.note),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Anulează'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (selectedUserId == null) {
                  _showErrorSnackBar('Selectează utilizatorul destinatar');
                  return;
                }

                if (amountController.text.isEmpty) {
                  _showErrorSnackBar('Introdu suma pentru transfer');
                  return;
                }

                final amount = double.tryParse(amountController.text);
                if (amount == null || amount <= 0) {
                  _showErrorSnackBar('Introdu o sumă validă');
                  return;
                }

                Navigator.pop(context);
                await _processTransferToUser(
                  userId: selectedUserId!,
                  amount: amount,
                  description: descriptionController.text,
                );
              },
              child: const Text('Transferă'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processTransferToUser({
    required String userId,
    required double amount,
    required String description,
  }) async {
    try {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId == null) {
        _showErrorSnackBar('Utilizator neautentificat');
        return;
      }

      // Get user info for notification
      final userInfo = await Supabase.instance.client
          .from('profiles')
          .select('full_name')
          .eq('id', userId)
          .single();

      // Record admin transaction (outgoing)
      await Supabase.instance.client
          .from('admin_transactions')
          .insert({
            'admin_id': currentUserId,
            'type': 'transfer',
            'direction': 'out',
            'amount': amount,
            'method': 'internal',
            'target': userId,
            'description': description.isEmpty 
                ? 'Transfer către ${userInfo['full_name']}' 
                : description,
            'status': 'completed',
          });

      // Add funds to user's wallet
      final existingWallet = await Supabase.instance.client
          .from('wallets')
          .select('balance')
          .eq('user_id', userId)
          .maybeSingle();

      if (existingWallet != null) {
        final newBalance = (existingWallet['balance'] ?? 0.0) + amount;
        await Supabase.instance.client
            .from('wallets')
            .update({'balance': newBalance})
            .eq('user_id', userId);
      } else {
        await Supabase.instance.client
            .from('wallets')
            .insert({
              'user_id': userId,
              'balance': amount,
            });
      }

      // Record user transaction (incoming)
      await Supabase.instance.client
          .from('wallet_transactions')
          .insert({
            'user_id': userId,
            'type': 'credit',
            'amount': amount,
            'description': description.isEmpty 
                ? 'Transfer de la administrator' 
                : description,
            'metadata': {
              'transfer_type': 'admin_to_user',
              'admin_id': currentUserId,
            },
          });

      // Send notification to user
      await Supabase.instance.client
          .from('notifications')
          .insert({
            'user_id': userId,
            'title': 'Transfer primit',
            'body': 'Ai primit ${amount.toStringAsFixed(2)} RON de la administrator${description.isNotEmpty ? ': $description' : ''}',
            'type': 'success',
          });

      _showSuccessSnackBar('Transferul de ${amount.toStringAsFixed(2)} RON către ${userInfo['full_name']} a fost efectuat cu succes!');
      await _loadWalletData();
    } catch (e) {
      Logger.error('Error processing transfer to user: $e');
      _showErrorSnackBar('Eroare la procesarea transferului');
    }
  }

  Future<void> _showPayVendorDialog() async {
    final vendorController = TextEditingController();
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    String method = 'cash';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.business, color: Colors.orange),
              SizedBox(width: 8),
              Text('Plată Furnizor'),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Vendor name
                  TextField(
                    controller: vendorController,
                    decoration: const InputDecoration(
                      labelText: 'Nume furnizor',
                      hintText: 'SC Furnizor SRL, Salon Dans, etc.',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.business),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Payment method
                  DropdownButtonFormField<String>(
                    value: method,
                    decoration: const InputDecoration(
                      labelText: 'Metoda de plată',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.payment),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'cash', child: Text('Cash')),
                      DropdownMenuItem(value: 'revolut', child: Text('Revolut')),
                      DropdownMenuItem(value: 'iban', child: Text('Transfer IBAN')),
                    ],
                    onChanged: (value) => setDialogState(() => method = value!),
                  ),
                  const SizedBox(height: 16),

                  // Amount
                  TextField(
                    controller: amountController,
                    decoration: const InputDecoration(
                      labelText: 'Sumă (RON)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.euro),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  // Description
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Descriere',
                      hintText: 'Chirie sală, echipamente, servicii, etc.',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Anulează'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (vendorController.text.isEmpty || amountController.text.isEmpty) {
                  _showErrorSnackBar('Completează furnizorul și suma');
                  return;
                }

                final amount = double.tryParse(amountController.text);
                if (amount == null || amount <= 0) {
                  _showErrorSnackBar('Introdu o sumă validă');
                  return;
                }

                Navigator.pop(context);
                await _processPayVendor(
                  vendor: vendorController.text,
                  amount: amount,
                  method: method,
                  description: descriptionController.text,
                );
              },
              child: const Text('Efectuează Plata'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processPayVendor({
    required String vendor,
    required double amount,
    required String method,
    required String description,
  }) async {
    try {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId == null) {
        _showErrorSnackBar('Utilizator neautentificat');
        return;
      }

      // Record admin transaction
      await Supabase.instance.client
          .from('admin_transactions')
          .insert({
            'admin_id': currentUserId,
            'type': 'payment',
            'direction': 'out',
            'amount': amount,
            'method': method,
            'target': vendor,
            'description': description.isEmpty 
                ? 'Plată către $vendor' 
                : description,
            'status': 'completed',
            'metadata': {
              'vendor': vendor,
              'payment_method': method,
              'category': 'vendor_payment',
            },
          });

      _showSuccessSnackBar('Plata de ${amount.toStringAsFixed(2)} RON către $vendor a fost înregistrată cu succes!');
      await _loadWalletData();
    } catch (e) {
      Logger.error('Error processing vendor payment: $e');
      _showErrorSnackBar('Eroare la procesarea plății');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Master Wallet Management'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWalletData,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'withdraw_funds':
                  _showWithdrawFundsDialog();
                  break;
                case 'transfer_user':
                  _showTransferToUserDialog();
                  break;
                case 'pay_vendor':
                  _showPayVendorDialog();
                  break;
                case 'manual_payment':
                  _showManualPaymentDialog();
                  break;
                case 'course_payments':
                  Navigator.pushNamed(context, '/admin/courses/payments');
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'withdraw_funds',
                child: Row(
                  children: [
                    Icon(Icons.money_off, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Retrage fonduri'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'transfer_user',
                child: Row(
                  children: [
                    Icon(Icons.send, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Transfer către utilizator'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'pay_vendor',
                child: Row(
                  children: [
                    Icon(Icons.business, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Plată furnizor'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'manual_payment',
                child: Row(
                  children: [
                    Icon(Icons.payment),
                    SizedBox(width: 8),
                    Text('Plată manuală cursuri'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'course_payments',
                child: Row(
                  children: [
                    Icon(Icons.school),
                    SizedBox(width: 8),
                    Text('Plăți cursuri'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Total Balance Summary
          Container(
            padding: const EdgeInsets.all(16),
            child: Card(
              color: Colors.purple.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Icon(Icons.account_balance_wallet, color: Colors.purple, size: 32),
                        const SizedBox(height: 8),
                        const Text('Sold Total', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          '${_totalBalance.toStringAsFixed(2)} RON',
                          style: const TextStyle(fontSize: 24, color: Colors.purple, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        const Icon(Icons.people, color: Colors.blue, size: 32),
                        const SizedBox(height: 8),
                        const Text('Portofele Active', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          '${_wallets.length}',
                          style: const TextStyle(fontSize: 24, color: Colors.blue, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Caută utilizatori...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Tabs
          Expanded(
            child: DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  const TabBar(
                    labelColor: Colors.purple,
                    unselectedLabelColor: Colors.grey,
                    isScrollable: true,
                    tabs: [
                      Tab(text: 'Portofele Utilizatori', icon: Icon(Icons.account_balance_wallet)),
                      Tab(text: 'Tranzacții Utilizatori', icon: Icon(Icons.history)),
                      Tab(text: 'Tranzacții Admin', icon: Icon(Icons.admin_panel_settings)),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Wallets Tab
                        _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _filteredWallets.isEmpty
                                ? const Center(
                                    child: Text(
                                      'Nu s-au găsit portofele',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: _filteredWallets.length,
                                    itemBuilder: (context, index) {
                                      final wallet = _filteredWallets[index];
                                      final user = wallet['user'];
                                      final balance = wallet['balance'] ?? 0.0;
                                      
                                      return Card(
                                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: _getRoleColor(user?['role'] ?? ''),
                                            child: Text(
                                              user?['full_name']?.toString().substring(0, 1).toUpperCase() ?? 'U',
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          title: Text(
                                            user?['full_name'] ?? 'Utilizator necunoscut',
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(user?['email'] ?? 'Email necunoscut'),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: _getRoleColor(user?['role'] ?? '').withOpacity(0.2),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Text(
                                                      user?['role']?.toString().toUpperCase() ?? 'UNKNOWN',
                                                      style: TextStyle(
                                                        color: _getRoleColor(user?['role'] ?? ''),
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          trailing: SizedBox(
                                            width: 100,
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  '${balance.toStringAsFixed(2)} RON',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.green,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 2),
                                                SizedBox(
                                                  height: 24,
                                                  child: TextButton(
                                                    onPressed: () => _transferToUser(wallet['user_id'], 0),
                                                    style: TextButton.styleFrom(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      minimumSize: Size.zero,
                                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                    ),
                                                    child: const Text(
                                                      'Transfer', 
                                                      style: TextStyle(fontSize: 10),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                        
                        // User Transactions Tab
                        _transactions.isEmpty
                            ? const Center(
                                child: Text(
                                  'Nu există tranzacții utilizatori',
                                  style: TextStyle(fontSize: 16),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _transactions.length,
                                itemBuilder: (context, index) {
                                  final transaction = _transactions[index];
                                  final user = transaction['user'];
                                  final isCredit = transaction['type'] == 'credit';
                                  
                                  return Card(
                                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: isCredit ? Colors.green : Colors.red,
                                        child: Icon(
                                          isCredit ? Icons.add : Icons.remove,
                                          color: Colors.white,
                                        ),
                                      ),
                                      title: Text(
                                        user?['full_name'] ?? 'Utilizator necunoscut',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(transaction['description'] ?? 'Fără descriere'),
                                          const SizedBox(height: 4),
                                          Text(
                                            _formatDate(transaction['created_at']),
                                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                      trailing: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${transaction['amount']?.toStringAsFixed(2) ?? '0.00'} RON',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: isCredit ? Colors.green : Colors.red,
                                            ),
                                          ),
                                          Text(
                                            isCredit ? 'Credit' : 'Debit',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isCredit ? Colors.green : Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),

                        // Admin Transactions Tab
                        _adminTransactions.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.admin_panel_settings, size: 64, color: Colors.grey),
                                    SizedBox(height: 16),
                                    Text(
                                      'Nu există tranzacții admin',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Folosește meniul pentru retrageri, transferuri sau plăți',
                                      style: TextStyle(fontSize: 12, color: Colors.grey),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: _adminTransactions.length,
                                itemBuilder: (context, index) {
                                  final transaction = _adminTransactions[index];
                                  final type = transaction['type'] ?? '';
                                  final direction = transaction['direction'] ?? 'out';
                                  final method = transaction['method'] ?? '';
                                  final target = transaction['target'] ?? '';
                                  final amount = transaction['amount'] ?? 0.0;
                                  
                                  Color getTypeColor() {
                                    switch (type) {
                                      case 'withdraw': return Colors.red;
                                      case 'transfer': return Colors.blue;
                                      case 'payment': return Colors.orange;
                                      default: return Colors.grey;
                                    }
                                  }

                                  IconData getTypeIcon() {
                                    switch (type) {
                                      case 'withdraw': return Icons.money_off;
                                      case 'transfer': return Icons.send;
                                      case 'payment': return Icons.business;
                                      default: return Icons.help;
                                    }
                                  }

                                  String getTypeLabel() {
                                    switch (type) {
                                      case 'withdraw': return 'Retragere';
                                      case 'transfer': return 'Transfer';
                                      case 'payment': return 'Plată';
                                      default: return 'Necunoscut';
                                    }
                                  }

                                  String getMethodLabel() {
                                    switch (method) {
                                      case 'cash': return 'Cash';
                                      case 'revolut': return 'Revolut';
                                      case 'iban': return 'IBAN';
                                      case 'internal': return 'Intern';
                                      default: return method;
                                    }
                                  }
                                  
                                  return Card(
                                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: getTypeColor(),
                                        child: Icon(
                                          getTypeIcon(),
                                          color: Colors.white,
                                        ),
                                      ),
                                      title: Row(
                                        children: [
                                          Text(
                                            getTypeLabel(),
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: getTypeColor().withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              getMethodLabel(),
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: getTypeColor(),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (target.isNotEmpty) ...[
                                            Text(
                                              type == 'transfer' ? 'Către: $target' : 
                                              type == 'payment' ? 'Furnizor: $target' : 
                                              'Destinație: $target',
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                            ),
                                            const SizedBox(height: 2),
                                          ],
                                          Text(transaction['description'] ?? 'Fără descriere'),
                                          const SizedBox(height: 4),
                                          Text(
                                            _formatDate(transaction['created_at']),
                                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                      trailing: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${amount.toStringAsFixed(2)} RON',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: direction == 'out' ? Colors.red : Colors.green,
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                direction == 'out' ? Icons.arrow_upward : Icons.arrow_downward,
                                                size: 12,
                                                color: direction == 'out' ? Colors.red : Colors.green,
                                              ),
                                              Text(
                                                direction == 'out' ? 'Ieșire' : 'Intrare',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: direction == 'out' ? Colors.red : Colors.green,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
