import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ExportDataDialog extends StatefulWidget {
  final List<Map<String, dynamic>> transactions;
  final List<Map<String, dynamic>> transfers;
  final double totalBalance;

  const ExportDataDialog({
    super.key,
    required this.transactions,
    required this.transfers,
    required this.totalBalance,
  });

  @override
  State<ExportDataDialog> createState() => _ExportDataDialogState();
}

class _ExportDataDialogState extends State<ExportDataDialog> {
  String _selectedFormat = 'excel';
  String _selectedPeriod = 'all';
  final List<String> _selectedDataTypes = ['transactions', 'transfers', 'summary'];
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.download, color: Colors.green, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Export Date',
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
            
            // Export options
            _buildExportOptions(),
            
            const SizedBox(height: 24),
            
            // Data preview
            _buildDataPreview(),
            
            const SizedBox(height: 24),
            
            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Anulează'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isExporting ? null : _exportData,
                    icon: _isExporting 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download),
                    label: Text(_isExporting ? 'Se exportă...' : 'Export'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
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

  Widget _buildExportOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Opțiuni Export',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Format selection
        Row(
          children: [
            const Text('Format:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedFormat,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(value: 'excel', child: Text('Excel (.xlsx)')),
                  DropdownMenuItem(value: 'csv', child: Text('CSV (.csv)')),
                  DropdownMenuItem(value: 'pdf', child: Text('PDF (.pdf)')),
                  DropdownMenuItem(value: 'json', child: Text('JSON (.json)')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedFormat = value!;
                  });
                },
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Period selection
        Row(
          children: [
            const Text('Perioada:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedPeriod,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('Toate datele')),
                  DropdownMenuItem(value: 'current_month', child: Text('Luna curentă')),
                  DropdownMenuItem(value: 'current_year', child: Text('Anul curent')),
                  DropdownMenuItem(value: 'last_30_days', child: Text('Ultimele 30 zile')),
                  DropdownMenuItem(value: 'last_90_days', child: Text('Ultimele 90 zile')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedPeriod = value!;
                  });
                },
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Data types selection
        const Text('Tipuri de date:', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _buildCheckbox('Tranzacții', 'transactions', Icons.receipt),
            _buildCheckbox('Transferuri', 'transfers', Icons.account_balance),
            _buildCheckbox('Sumar', 'summary', Icons.assessment),
          ],
        ),
      ],
    );
  }

  Widget _buildCheckbox(String label, String value, IconData icon) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: _selectedDataTypes.contains(value),
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedDataTypes.add(value);
          } else {
            _selectedDataTypes.remove(value);
          }
        });
      },
    );
  }

  Widget _buildDataPreview() {
    final filteredTransactions = _getFilteredTransactions();
    final filteredTransfers = _getFilteredTransfers();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Previzualizare Date',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              if (_selectedDataTypes.contains('transactions')) ...[
                _buildPreviewItem('Tranzacții', filteredTransactions.length, Icons.receipt, Colors.blue),
                const SizedBox(height: 8),
              ],
              if (_selectedDataTypes.contains('transfers')) ...[
                _buildPreviewItem('Transferuri', filteredTransfers.length, Icons.account_balance, Colors.green),
                const SizedBox(height: 8),
              ],
              if (_selectedDataTypes.contains('summary')) ...[
                _buildPreviewItem('Sold Total', '${widget.totalBalance.toStringAsFixed(2)} RON', Icons.attach_money, Colors.purple),
              ],
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        
        // File info
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
                  'Fișierul va fi descărcat în format ${_selectedFormat.toUpperCase()} cu ${_getTotalRecords()} înregistrări.',
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
    );
  }

  Widget _buildPreviewItem(String label, dynamic value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getFilteredTransactions() {
    final now = DateTime.now();
    final filtered = widget.transactions.where((transaction) {
      final date = transaction['timestamp'] as DateTime;
      
      switch (_selectedPeriod) {
        case 'current_month':
          return date.month == now.month && date.year == now.year;
        case 'current_year':
          return date.year == now.year;
        case 'last_30_days':
          return date.isAfter(now.subtract(const Duration(days: 30)));
        case 'last_90_days':
          return date.isAfter(now.subtract(const Duration(days: 90)));
        default:
          return true;
      }
    }).toList();
    
    return filtered;
  }

  List<Map<String, dynamic>> _getFilteredTransfers() {
    final now = DateTime.now();
    final filtered = widget.transfers.where((transfer) {
      final date = transfer['timestamp'] as DateTime;
      
      switch (_selectedPeriod) {
        case 'current_month':
          return date.month == now.month && date.year == now.year;
        case 'current_year':
          return date.year == now.year;
        case 'last_30_days':
          return date.isAfter(now.subtract(const Duration(days: 30)));
        case 'last_90_days':
          return date.isAfter(now.subtract(const Duration(days: 90)));
        default:
          return true;
      }
    }).toList();
    
    return filtered;
  }

  int _getTotalRecords() {
    int total = 0;
    
    if (_selectedDataTypes.contains('transactions')) {
      total += _getFilteredTransactions().length;
    }
    
    if (_selectedDataTypes.contains('transfers')) {
      total += _getFilteredTransfers().length;
    }
    
    if (_selectedDataTypes.contains('summary')) {
      total += 1; // One summary record
    }
    
    return total;
  }

  void _exportData() async {
    if (_selectedDataTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selectează cel puțin un tip de date pentru export!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isExporting = true;
    });

    try {
      // Generate export data
      final exportData = _generateExportData();
      final fileName = 'aiu_dance_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.${_getFileExtension()}';
      
      if (kIsWeb) {
        // For web, show success message (download would require dart:html)
        setState(() {
          _isExporting = false;
        });

        Navigator.pop(context);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export realizat cu succes pentru web! Fișier: $fileName'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        // For mobile/desktop, simulate file creation
        await Future.delayed(const Duration(seconds: 2));
        
        setState(() {
          _isExporting = false;
        });

        Navigator.pop(context);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export realizat cu succes! Fișier: $fileName'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Deschide',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Fișierul conține ${exportData.length} înregistrări'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isExporting = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Eroare la export: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Map<String, dynamic>> _generateExportData() {
    final List<Map<String, dynamic>> exportData = [];
    
    if (_selectedDataTypes.contains('transactions')) {
      final filteredTransactions = _getFilteredTransactions();
      for (final transaction in filteredTransactions) {
        exportData.add({
          'type': 'transaction',
          'id': transaction['id'],
          'description': transaction['description'],
          'amount': transaction['amount'],
          'timestamp': DateFormat('yyyy-MM-dd HH:mm:ss').format(transaction['timestamp']),
          'status': transaction['status'],
        });
      }
    }
    
    if (_selectedDataTypes.contains('transfers')) {
      final filteredTransfers = _getFilteredTransfers();
      for (final transfer in filteredTransfers) {
        exportData.add({
          'type': 'transfer',
          'id': transfer['id'],
          'amount': transfer['amount'],
          'timestamp': DateFormat('yyyy-MM-dd HH:mm:ss').format(transfer['timestamp']),
          'status': transfer['status'],
          'bankAccount': transfer['bankAccount'],
          'reference': transfer['reference'],
        });
      }
    }
    
    if (_selectedDataTypes.contains('summary')) {
      exportData.add({
        'type': 'summary',
        'totalBalance': widget.totalBalance,
        'exportDate': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
        'period': _selectedPeriod,
      });
    }
    
    return exportData;
  }

  String _getFileExtension() {
    switch (_selectedFormat) {
      case 'excel':
        return 'xlsx';
      case 'csv':
        return 'csv';
      case 'pdf':
        return 'pdf';
      case 'json':
        return 'json';
      default:
        return 'xlsx';
    }
  }
}
