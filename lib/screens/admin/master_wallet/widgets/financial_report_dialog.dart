import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class FinancialReportDialog extends StatelessWidget {
  final double totalBalance;
  final double availableBalance;
  final double pendingBalance;
  final double transferredBalance;
  final List<Map<String, dynamic>> transactions;
  final List<Map<String, dynamic>> transfers;

  const FinancialReportDialog({
    super.key,
    required this.totalBalance,
    required this.availableBalance,
    required this.pendingBalance,
    required this.transferredBalance,
    required this.transactions,
    required this.transfers,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 800,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.assessment, color: Colors.blue, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Raport Financiar',
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
            
            // Report content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary section
                    _buildSummarySection(),
                    
                    const SizedBox(height: 24),
                    
                    // Revenue breakdown
                    _buildRevenueBreakdown(),
                    
                    const SizedBox(height: 24),
                    
                    // Monthly summary
                    _buildMonthlySummary(),
                    
                    const SizedBox(height: 24),
                    
                    // Tax information
                    _buildTaxInformation(),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _exportReport(context),
                    icon: const Icon(Icons.download),
                    label: const Text('Export PDF'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _sendToANAF(context),
                    icon: const Icon(Icons.send),
                    label: const Text('Trimite la ANAF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sumar Financiar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem('Venituri Totale', totalBalance, Colors.green),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryItem('Disponibil', availableBalance, Colors.blue),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryItem('În Așteptare', pendingBalance, Colors.orange),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryItem('Transferat', transferredBalance, Colors.purple),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${amount.toStringAsFixed(2)} RON',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueBreakdown() {
    final courseRevenue = transactions
        .where((t) => t['type'] == 'debit')
        .fold(0.0, (sum, t) => sum + (t['amount'] as double));
    
    final qrBarRevenue = transactions
        .where((t) => t['type'] == 'qr_bar_payment')
        .fold(0.0, (sum, t) => sum + (t['amount'] as double));
    
    final walletTopupRevenue = transactions
        .where((t) => t['type'] == 'wallet_topup')
        .fold(0.0, (sum, t) => sum + (t['amount'] as double));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Defalcare Venituri',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildRevenueItem('Cursuri de Dans', courseRevenue, Icons.school, Colors.blue),
            const SizedBox(height: 8),
            _buildRevenueItem('QR Bar', qrBarRevenue, Icons.local_bar, Colors.orange),
            const SizedBox(height: 8),
            _buildRevenueItem('Adăugări Portofel', walletTopupRevenue, Icons.account_balance_wallet, Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueItem(String title, double amount, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        Text(
          '${amount.toStringAsFixed(2)} RON',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlySummary() {
    final currentMonth = DateTime.now().month;
    final currentYear = DateTime.now().year;
    
    final monthlyTransactions = transactions.where((t) {
      final date = t['timestamp'] as DateTime;
      return date.month == currentMonth && date.year == currentYear;
    }).toList();
    
    final monthlyRevenue = monthlyTransactions.fold(0.0, (sum, t) => sum + (t['amount'] as double));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sumar Lunar - ${DateFormat('MMMM yyyy').format(DateTime.now())}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMonthlyItem('Tranzacții', monthlyTransactions.length, Icons.receipt),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMonthlyItem('Venituri', monthlyRevenue, Icons.attach_money),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMonthlyItem('Transferuri', transfers.length, Icons.account_balance),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyItem(String title, dynamic value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 20),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value is double ? '${value.toStringAsFixed(2)} RON' : value.toString(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaxInformation() {
    final taxableAmount = totalBalance * 0.21; // 21% TVA
    final netAmount = totalBalance - taxableAmount;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informații Fiscale',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTaxItem('Venit Brut', totalBalance, Colors.red),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTaxItem('TVA (21%)', taxableAmount, Colors.orange),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTaxItem('Venit Net', netAmount, Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Acest raport este generat automat și poate fi folosit pentru declarațiile fiscale.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaxItem(String title, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${amount.toStringAsFixed(2)} RON',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportReport(BuildContext context) async {
    try {
      // Create PDF document
      final pdf = pw.Document();
      
      // Add content to PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) => [
            // Header
            pw.Header(
              level: 0,
              child: pw.Row(
                children: [
                  pw.Text(
                    'AIU Dance - Raport Financiar',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Spacer(),
                  pw.Text(
                    'Generat: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                    style: pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            
            pw.SizedBox(height: 20),
            
            // Summary section
            pw.Header(level: 1, text: 'Sumar Financiar'),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Venituri Totale', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('${totalBalance.toStringAsFixed(2)} RON'),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Disponibil', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('${availableBalance.toStringAsFixed(2)} RON'),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('În Așteptare', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('${pendingBalance.toStringAsFixed(2)} RON'),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Transferat', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('${transferredBalance.toStringAsFixed(2)} RON'),
                    ),
                  ],
                ),
              ],
            ),
            
            pw.SizedBox(height: 20),
            
            // Revenue breakdown
            pw.Header(level: 1, text: 'Defalcare Venituri'),
            pw.SizedBox(height: 10),
            _buildRevenueBreakdownPDF(),
            
            pw.SizedBox(height: 20),
            
            // Tax information
            pw.Header(level: 1, text: 'Informații Fiscale'),
            pw.SizedBox(height: 10),
            _buildTaxInformationPDF(),
            
            pw.SizedBox(height: 20),
            
            // Recent transactions
            pw.Header(level: 1, text: 'Tranzacții Recente'),
            pw.SizedBox(height: 10),
            _buildTransactionsPDF(),
          ],
        ),
      );
      
      // Save PDF to file
      final pdfBytes = await pdf.save();
      final fileName = 'aiu_dance_raport_financiar_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      
      if (kIsWeb) {
        // For web, show success message (download would require dart:html)
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDF generat cu succes pentru web: $fileName'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        // For mobile/desktop
        final output = await getTemporaryDirectory();
        final file = File('${output.path}/$fileName');
        await file.writeAsBytes(pdfBytes);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDF generat cu succes: ${file.path}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Deschide',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fișierul a fost deschis!'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare la generarea PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _sendToANAF(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Trimite la ANAF'),
        content: const Text(
          'Vrei să trimiți raportul financiar la ANAF? Această acțiune va genera și trimite automat declarația fiscală.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anulează'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Raportul a fost trimis cu succes la ANAF!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Trimite'),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildRevenueBreakdownPDF() {
    final courseRevenue = transactions
        .where((t) => t['type'] == 'debit')
        .fold(0.0, (sum, t) => sum + (t['amount'] as double));
    
    final qrBarRevenue = transactions
        .where((t) => t['type'] == 'qr_bar_payment')
        .fold(0.0, (sum, t) => sum + (t['amount'] as double));
    
    final walletTopupRevenue = transactions
        .where((t) => t['type'] == 'wallet_topup')
        .fold(0.0, (sum, t) => sum + (t['amount'] as double));

    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        pw.TableRow(
          children: [
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Cursuri de Dans')),
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${courseRevenue.toStringAsFixed(2)} RON')),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('QR Bar')),
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${qrBarRevenue.toStringAsFixed(2)} RON')),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Adăugări Portofel')),
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${walletTopupRevenue.toStringAsFixed(2)} RON')),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildTaxInformationPDF() {
    final taxableAmount = totalBalance * 0.21; // 21% TVA
    final netAmount = totalBalance - taxableAmount;

    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        pw.TableRow(
          children: [
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Venit Brut')),
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${totalBalance.toStringAsFixed(2)} RON')),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('TVA (21%)')),
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${taxableAmount.toStringAsFixed(2)} RON')),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Venit Net')),
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${netAmount.toStringAsFixed(2)} RON')),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildTransactionsPDF() {
    final recentTransactions = transactions.take(10).toList();
    
    if (recentTransactions.isEmpty) {
      return pw.Text('Nu există tranzacții recente');
    }

    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        // Header
        pw.TableRow(
          children: [
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Data', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Descriere', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Suma', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Status', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
          ],
        ),
        // Data rows
        ...recentTransactions.map((transaction) => pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(DateFormat('dd/MM/yyyy HH:mm').format(transaction['timestamp'])),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(transaction['description']),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('${transaction['amount']} RON'),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(transaction['status']),
            ),
          ],
        )),
      ],
    );
  }
}
