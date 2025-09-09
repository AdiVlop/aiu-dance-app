import 'package:flutter/material.dart';

import 'package:fl_chart/fl_chart.dart';
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
                            // User Growth Chart
                            _buildUserGrowthChart(),
                            const SizedBox(height: 24),
                            
                            // Revenue Trend Chart
                            _buildRevenueChart(),
                            const SizedBox(height: 24),
                            
                            // QR Scans Chart
                            _buildQRScansChart(),
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
                            onPressed: _exportToPDF,
                            icon: Icons.file_download,
                            text: 'Export PDF',
                            backgroundColor: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: WebOptimizedButton(
                            onPressed: _sendEmailReport,
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

  // Export to PDF functionality
  void _exportToPDF() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Simulate PDF generation (in real app, use pdf package)
      await Future.delayed(const Duration(seconds: 2));

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Raportul PDF a fost generat cu succes!'),
          backgroundColor: Colors.green,
        ),
      );

      // In a real app, you would:
      // 1. Generate PDF with charts and data
      // 2. Save to device or share
      // 3. Use packages like: pdf, printing, share_plus
      
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Eroare la generarea PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Send email report functionality
  void _sendEmailReport() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Simulate email sending
      await Future.delayed(const Duration(seconds: 2));

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Raportul a fost trimis prin email cu succes!'),
          backgroundColor: Colors.green,
        ),
      );

      // In a real app, you would:
      // 1. Generate report data
      // 2. Send email using email service
      // 3. Use packages like: mailer, flutter_email_sender
      
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Eroare la trimiterea email: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Build User Growth Chart
  Widget _buildUserGrowthChart() {
    final userGrowth = _userStats['userGrowth'] as List<int>? ?? [];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Creșterea Utilizatorilor (Ultimele 6 luni)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const months = ['Ian', 'Feb', 'Mar', 'Apr', 'Mai', 'Iun'];
                          if (value.toInt() < months.length) {
                            return Text(months[value.toInt()]);
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: userGrowth.asMap().entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
                          .toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build Revenue Chart
  Widget _buildRevenueChart() {
    final monthlyTrend = _financialStats['monthlyTrend'] as List<dynamic>? ?? [];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tendința Veniturilor (Ultimele 6 luni)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (monthlyTrend.isNotEmpty ? monthlyTrend.map((e) => e.toDouble()).reduce((a, b) => a > b ? a : b) : 0) + 500,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const months = ['Ian', 'Feb', 'Mar', 'Apr', 'Mai', 'Iun'];
                          if (value.toInt() < months.length) {
                            return Text(months[value.toInt()]);
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  barGroups: monthlyTrend.asMap().entries
                      .map((e) => BarChartGroupData(
                            x: e.key,
                            barRods: [
                              BarChartRodData(
                                toY: e.value.toDouble(),
                                color: Colors.green,
                                width: 20,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                              ),
                            ],
                          ))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build QR Scans Chart
  Widget _buildQRScansChart() {
    final qrStats = _qrStats['scansByType'] as Map<String, dynamic>? ?? {};
    
    if (qrStats.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Statistici QR Scans',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('Nu există date disponibile pentru QR scans'),
            ],
          ),
        ),
      );
    }

    final entries = qrStats.entries.toList();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Distribuția QR Scans pe Tipuri',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: entries.asMap().entries.map((e) {
                    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red];
                    return PieChartSectionData(
                      color: colors[e.key % colors.length],
                      value: e.value.value.toDouble(),
                      title: '${e.value.key}\n${e.value.value}',
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ResponsiveDashboardGrid is imported from widgets/responsive_dashboard_card.dart
