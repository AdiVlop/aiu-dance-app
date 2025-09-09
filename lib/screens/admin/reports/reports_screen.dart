import 'package:flutter/material.dart';

// import 'package:fl_chart/fl_chart.dart'; // Temporar eliminat pentru optimizare APK
import '../../../services/qr_service.dart';
import '../../../utils/logger.dart';
import '../../../widgets/web_optimized_button.dart';
import '../../../widgets/responsive_dashboard_card.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _userStats = {};
  Map<String, dynamic> _qrStats = {};
  Map<String, dynamic> _financialStats = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load QR statistics
      final qrService = QRService();
      final qrData = await qrService.getQRStatistics();
      
      // Mock data for other statistics
      _userStats = {
        'totalUsers': 150,
        'activeUsers': 120,
        'newUsers': 25,
        'userGrowth': [10, 15, 20, 25, 30, 35],
      };
      
      _financialStats = {
        'totalRevenue': 15000.0,
        'monthlyRevenue': 2500.0,
        'expenses': 8000.0,
        'profit': 7000.0,
        'monthlyTrend': [2000, 2200, 2100, 2400, 2300, 2500],
      };
      
      setState(() {
        _qrStats = qrData;
        _isLoading = false;
      });
      
    } catch (e) {
      Logger.error('Error loading reports data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapoarte și Analize'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Stats
                    const Text(
                      'Statistici Rapide',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    
                    ResponsiveDashboardGrid(
                      cards: [
                        ResponsiveDashboardCard(
                          icon: Icons.people,
                          title: 'Utilizatori Totali',
                          subtitle: '${_userStats['totalUsers'] ?? 0}',
                          color: Colors.blue,
                        ),
                        ResponsiveDashboardCard(
                          icon: Icons.people_outline,
                          title: 'Utilizatori Activi',
                          subtitle: '${_userStats['activeUsers'] ?? 0}',
                          color: Colors.green,
                        ),
                        ResponsiveDashboardCard(
                          icon: Icons.person_add,
                          title: 'Utilizatori Noi',
                          subtitle: '${_userStats['newUsers'] ?? 0}',
                          color: Colors.orange,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Financial Stats
                    const Text(
                      'Statistici Financiare',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    
                    ResponsiveDashboardGrid(
                      cards: [
                        ResponsiveDashboardCard(
                          icon: Icons.attach_money,
                          title: 'Venituri Totale',
                          subtitle: '${_financialStats['totalRevenue']?.toStringAsFixed(0) ?? '0'} RON',
                          color: Colors.green,
                        ),
                        ResponsiveDashboardCard(
                          icon: Icons.trending_up,
                          title: 'Venituri Lunare',
                          subtitle: '${_financialStats['monthlyRevenue']?.toStringAsFixed(0) ?? '0'} RON',
                          color: Colors.blue,
                        ),
                        ResponsiveDashboardCard(
                          icon: Icons.trending_down,
                          title: 'Cheltuieli',
                          subtitle: '${_financialStats['expenses']?.toStringAsFixed(0) ?? '0'} RON',
                          color: Colors.red,
                        ),
                        ResponsiveDashboardCard(
                          icon: Icons.account_balance_wallet,
                          title: 'Profit',
                          subtitle: '${_financialStats['profit']?.toStringAsFixed(0) ?? '0'} RON',
                          color: Colors.purple,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // QR Statistics
                    const Text(
                      'Statistici QR',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    
                    ResponsiveDashboardGrid(
                      cards: [
                        ResponsiveDashboardCard(
                          icon: Icons.qr_code,
                          title: 'Total Scanări',
                          subtitle: '${_qrStats['totalScans'] ?? 0}',
                          color: Colors.indigo,
                        ),
                        ResponsiveDashboardCard(
                          icon: Icons.qr_code_scanner,
                          title: 'Scanări Astăzi',
                          subtitle: '${_qrStats['todayScans'] ?? 0}',
                          color: Colors.teal,
                        ),
                        ResponsiveDashboardCard(
                          icon: Icons.trending_up,
                          title: 'Scanări Luna',
                          subtitle: '${_qrStats['monthScans'] ?? 0}',
                          color: Colors.cyan,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Charts Section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Grafice și Analize',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            const Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.bar_chart,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Graficele sunt temporar dezactivate\npentru optimizarea aplicației',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 16, color: Colors.grey),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Vor fi reactivate în versiunea viitoare',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: WebOptimizedButton(
                            onPressed: _showMessage,
                            icon: Icons.file_download,
                            text: 'Export PDF',
                            backgroundColor: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: WebOptimizedButton(
                            onPressed: _showMessage,
                            icon: Icons.email,
                            text: 'Trimite Email',
                            backgroundColor: Colors.green,
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

  void _showMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcționalitatea este temporar dezactivată pentru optimizarea aplicației'),
      ),
    );
  }
}

// ResponsiveDashboardGrid is imported from widgets/responsive_dashboard_card.dart
