import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aiu_dance/utils/logger.dart';
// import 'package:pdf/pdf.dart'; // Temporar eliminat pentru optimizare APK
// import 'package:pdf/widgets.dart' as pw; // Temporar eliminat pentru optimizare APK
// import 'package:printing/printing.dart';

class AdminFinanceScreen extends StatefulWidget {
  const AdminFinanceScreen({super.key});

  @override
  State<AdminFinanceScreen> createState() => _AdminFinanceScreenState();
}

class _AdminFinanceScreenState extends State<AdminFinanceScreen> {
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _wallets = [];
  bool _isLoading = true;
  double _totalBalance = 0.0;
  double _totalIncome = 0.0;
  double _totalExpenses = 0.0;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadFinancialData();
  }

  Future<void> _loadFinancialData() async {
    try {
      setState(() => _isLoading = true);
      
      // Load wallets
      final walletsResponse = await Supabase.instance.client
          .from('wallets')
          .select('*')
          .order('created_at', ascending: false);

      // Load transactions
      final transactionsResponse = await Supabase.instance.client
          .from('wallet_transactions')
          .select('''
            *,
            user:profiles!wallet_transactions_user_id_fkey(full_name, email)
          ''')
          .gte('created_at', _startDate.toIso8601String())
          .lte('created_at', _endDate.toIso8601String())
          .order('created_at', ascending: false);

      setState(() {
        _wallets = List<Map<String, dynamic>>.from(walletsResponse);
        _transactions = List<Map<String, dynamic>>.from(transactionsResponse);
        
        // Calculate totals
        _totalBalance = _wallets.fold(0.0, (sum, wallet) => sum + (wallet['balance'] ?? 0.0));
        _totalIncome = _transactions
            .where((t) => t['type'] == 'credit')
            .fold(0.0, (sum, t) => sum + (t['amount'] ?? 0.0));
        _totalExpenses = _transactions
            .where((t) => t['type'] == 'debit')
            .fold(0.0, (sum, t) => sum + (t['amount'] ?? 0.0));
        
        _isLoading = false;
      });
      
      Logger.info('Loaded ${_wallets.length} wallets and ${_transactions.length} transactions');
    } catch (e) {
      Logger.error('Error loading financial data: $e');
      setState(() => _isLoading = false);
      _showErrorSnackBar('Eroare la încărcarea datelor financiare');
    }
  }

  Future<void> _exportToPDF() async {
    try {
      // PDF generation temporarily disabled for APK optimization
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generarea PDF este temporar dezactivată pentru optimizarea aplicației')),
      );
      return;
      
      // final pdf = pw.Document();
      /*
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Text(
                    'Raport Financiar AIU Dance',
                    style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Perioada: ${_formatDate(_startDate)} - ${_formatDate(_endDate)}'),
                    pw.Text('Generat pe: ${_formatDate(DateTime.now())}'),
                  ],
                ),
                pw.SizedBox(height: 20),
                
                // Summary
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'Sumar Financiar',
                        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 16),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                        children: [
                          pw.Column(
                            children: [
                              pw.Text('Sold Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                              pw.Text('${_totalBalance.toStringAsFixed(2)} RON', 
                                style: pw.TextStyle(fontSize: 16, color: PdfColors.blue)),
                            ],
                          ),
                          pw.Column(
                            children: [
                              pw.Text('Venituri', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                              pw.Text('${_totalIncome.toStringAsFixed(2)} RON', 
                                style: pw.TextStyle(fontSize: 16, color: PdfColors.green)),
                            ],
                          ),
                          pw.Column(
                            children: [
                              pw.Text('Cheltuieli', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                              pw.Text('${_totalExpenses.toStringAsFixed(2)} RON', 
                                style: pw.TextStyle(fontSize: 16, color: PdfColors.red)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                
                // Transactions Table
                pw.Text(
                  'Tranzacții Recente',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 10),
                pw.Table(
                  border: pw.TableBorder.all(),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1),
                    1: const pw.FlexColumnWidth(2),
                    2: const pw.FlexColumnWidth(2),
                    3: const pw.FlexColumnWidth(1.5),
                    4: const pw.FlexColumnWidth(1.5),
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Tip', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Utilizator', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Descriere', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Sumă', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Data', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),
                    ..._transactions.take(50).map((transaction) {
                      final user = transaction['user'];
                      
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              transaction['type'] == 'credit' ? 'Credit' : 'Debit',
                              style: pw.TextStyle(
                                color: transaction['type'] == 'credit' ? PdfColors.green : PdfColors.red,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(user?['full_name'] ?? 'Necunoscut'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(transaction['description'] ?? ''),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              '${transaction['amount']?.toStringAsFixed(2) ?? '0.00'} RON',
                              style: pw.TextStyle(
                                color: transaction['type'] == 'credit' ? PdfColors.green : PdfColors.red,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(_formatDate(DateTime.parse(transaction['created_at']))),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ],
            );
          },
        ),
      );

      // await Printing.layoutPdf(
      //   onLayout: (PdfPageFormat format) async => pdf.save(),
      //   name: 'raport_financiar_${_formatDate(DateTime.now())}.pdf',
      // );

      _showSuccessSnackBar('Raportul financiar a fost generat cu succes');
      */
    } catch (e) {
      Logger.error('Error generating PDF: $e');
      _showErrorSnackBar('Eroare la generarea raportului');
    }
  }

  Future<void> _exportToCSV() async {
    // For CSV export, we would need to implement file writing
    // This is a placeholder for future implementation
    _showSuccessSnackBar('Export CSV va fi implementat în curând');
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapoarte Financiare'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportToPDF,
            tooltip: 'Export PDF',
          ),
          IconButton(
            icon: const Icon(Icons.table_chart),
            onPressed: _exportToCSV,
            tooltip: 'Export CSV',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFinancialData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Date Range Selector
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _startDate,
                              firstDate: DateTime.now().subtract(const Duration(days: 365)),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() => _startDate = date);
                              _loadFinancialData();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16),
                                const SizedBox(width: 8),
                                Text('De la: ${_formatDate(_startDate)}'),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _endDate,
                              firstDate: _startDate,
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() => _endDate = date);
                              _loadFinancialData();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16),
                                const SizedBox(width: 8),
                                Text('Până la: ${_formatDate(_endDate)}'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Financial Summary Cards
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Card(
                          color: Colors.blue.withOpacity(0.1),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Icon(Icons.account_balance_wallet, color: Colors.blue, size: 32),
                                const SizedBox(height: 8),
                                const Text('Sold Total', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text(
                                  '${_totalBalance.toStringAsFixed(2)} RON',
                                  style: const TextStyle(fontSize: 20, color: Colors.blue, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Card(
                          color: Colors.green.withOpacity(0.1),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Icon(Icons.trending_up, color: Colors.green, size: 32),
                                const SizedBox(height: 8),
                                const Text('Venituri', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text(
                                  '${_totalIncome.toStringAsFixed(2)} RON',
                                  style: const TextStyle(fontSize: 20, color: Colors.green, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Card(
                          color: Colors.red.withOpacity(0.1),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Icon(Icons.trending_down, color: Colors.red, size: 32),
                                const SizedBox(height: 8),
                                const Text('Cheltuieli', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text(
                                  '${_totalExpenses.toStringAsFixed(2)} RON',
                                  style: const TextStyle(fontSize: 20, color: Colors.red, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Transactions List
                Expanded(
                  child: _transactions.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'Nu există tranzacții pentru această perioadă',
                                style: TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            ],
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
                                      _formatDate(DateTime.parse(transaction['created_at'])),
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
                ),
              ],
            ),
    );
  }
}
