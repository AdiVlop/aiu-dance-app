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
  final QRService _qrService = QRService();

  
  bool _isLoading = false;
  Map<String, dynamic> _qrStats = {};
  Map<String, dynamic> _financialStats = {};
  Map<String, dynamic> _courseStats = {};
  Map<String, dynamic> _userStats = {};

  @override
  void initState() {
    super.initState();
    _loadAllReports();
  }

  Future<void> _loadAllReports() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load all reports in parallel
      await Future.wait([
        _loadQRStats(),
        _loadFinancialStats(),
        _loadCourseStats(),
        _loadUserStats(),
      ]);
    } catch (e) {
      Logger.error('Error loading reports', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare la încărcarea rapoartelor: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadQRStats() async {
    try {
      final stats = await _qrService.getQRStatistics();
      setState(() {
        _qrStats = stats;
      });
    } catch (e) {
      Logger.error('Error loading QR stats', e);
    }
  }

  Future<void> _loadFinancialStats() async {
    try {
      // Mock financial data for now
      setState(() {
        _financialStats = {
          'totalRevenue': 15000.0,
          'monthlyRevenue': 3500.0,
          'pendingPayments': 2500.0,
          'paymentMethods': {
            'stripe': 8000.0,
            'cash': 5000.0,
            'wallet': 2000.0,
          },
          'monthlyTrend': [2800, 3200, 3500, 3800, 4200, 3500],
        };
      });
    } catch (e) {
      Logger.error('Error loading financial stats', e);
    }
  }

  Future<void> _loadCourseStats() async {
    try {
      // Mock course data for now
      setState(() {
        _courseStats = {
          'totalCourses': 12,
          'activeCourses': 8,
          'totalEnrollments': 156,
          'averageAttendance': 85.5,
          'popularCourses': [
            {'name': 'Salsa pentru începători', 'enrollments': 45},
            {'name': 'Bachata intermediar', 'enrollments': 32},
            {'name': 'Kizomba avansat', 'enrollments': 28},
          ],
        };
      });
    } catch (e) {
      Logger.error('Error loading course stats', e);
    }
  }

  Future<void> _loadUserStats() async {
    try {
      // Mock user data for now
      setState(() {
        _userStats = {
          'totalUsers': 234,
          'activeUsers': 189,
          'newUsersThisMonth': 23,
          'userGrowth': [180, 195, 210, 220, 234],
          'userTypes': {
            'students': 156,
            'instructors': 8,
            'admins': 3,
            'guests': 67,
          },
        };
      });
    } catch (e) {
      Logger.error('Error loading user stats', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapoarte și Analize'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllReports,
            tooltip: 'Reîmprospătează rapoartele',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dashboard Rapoarte',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Quick Stats Cards
                  _buildQuickStatsRow(),
                  const SizedBox(height: 24),
                  
                  // Detailed Reports Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                    children: [
                      _buildReportCard(
                        'Raport Financiar',
                        Icons.account_balance_wallet,
                        Colors.blue,
                        'Analizează veniturile și cheltuielile',
                        () => _showFinancialReport(),
                      ),
                      _buildReportCard(
                        'Raport Cursuri',
                        Icons.school,
                        Colors.green,
                        'Statistici despre cursuri și participanți',
                        () => _showCourseReport(),
                      ),
                      _buildReportCard(
                        'Raport Utilizatori',
                        Icons.people,
                        Colors.orange,
                        'Analizează activitatea utilizatorilor',
                        () => _showUserReport(),
                      ),
                      _buildReportCard(
                        'Raport QR Bar',
                        Icons.qr_code,
                        Colors.purple,
                        'Statistici despre produsele QR Bar',
                        () => _showQRReport(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildQuickStatsRow() {
    return ResponsiveDashboardGrid(
      spacing: 12,
      runSpacing: 12,
      cards: [
        ResponsiveDashboardCard(
          icon: Icons.account_balance_wallet,
          title: '${_financialStats['totalRevenue']?.toStringAsFixed(0) ?? '0'} RON',
          subtitle: 'Venit Total',
          color: Colors.blue,
        ),
        ResponsiveDashboardCard(
          icon: Icons.people,
          title: '${_userStats['activeUsers'] ?? '0'}',
          subtitle: 'Utilizatori Activi',
          color: Colors.green,
        ),
        ResponsiveDashboardCard(
          icon: Icons.school,
          title: '${_courseStats['activeCourses'] ?? '0'}',
          subtitle: 'Cursuri Active',
          color: Colors.orange,
        ),
        ResponsiveDashboardCard(
          icon: Icons.qr_code,
          title: '${_qrStats['totalScans'] ?? '0'}',
          subtitle: 'QR Scans',
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildQuickStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(String title, IconData icon, Color color, String description, VoidCallback onTap) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Vezi Raport',
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFinancialReport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Raport Financiar'),
        content: SizedBox(
          width: 600,
          height: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Revenue Chart
                const Text(
                  'Evoluția Veniturilor (Ultimele 6 luni)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: const Center(
                    child: Text(
                      'Graficele sunt temporar dezactivate\npentru optimizarea aplicației',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                  // child: LineChart(
                  //   LineChartData(
                  //     gridData: FlGridData(show: true),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                          ),
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
                      ),
                      borderData: FlBorderData(show: true),
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(6, (index) {
                            return FlSpot(index.toDouble(), _financialStats['monthlyTrend']?[index]?.toDouble() ?? 0);
                          }),
                          isCurved: true,
                          color: Colors.blue,
                          barWidth: 3,
                          dotData: FlDotData(show: true),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Payment Methods
                const Text(
                  'Metode de Plată',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: const Center(
                    child: Text(
                      'Graficele sunt temporar dezactivate\npentru optimizarea aplicației',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                  // child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          value: _financialStats['paymentMethods']?['stripe']?.toDouble() ?? 0,
                          title: 'Stripe\n${_financialStats['paymentMethods']?['stripe']?.toStringAsFixed(0) ?? '0'} RON',
                          color: Colors.blue,
                          radius: 60,
                        ),
                        PieChartSectionData(
                          value: _financialStats['paymentMethods']?['cash']?.toDouble() ?? 0,
                          title: 'Numerar\n${_financialStats['paymentMethods']?['cash']?.toStringAsFixed(0) ?? '0'} RON',
                          color: Colors.green,
                          radius: 60,
                        ),
                        PieChartSectionData(
                          value: _financialStats['paymentMethods']?['wallet']?.toDouble() ?? 0,
                          title: 'Wallet\n${_financialStats['paymentMethods']?['wallet']?.toStringAsFixed(0) ?? '0'} RON',
                          color: Colors.orange,
                          radius: 60,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          WebOptimizedButton(
            text: 'Export PDF',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export PDF - în dezvoltare')),
              );
            },
            backgroundColor: Colors.blue,
          ),
          WebOptimizedButton(
            text: 'Închide',
            onPressed: () => Navigator.of(context).pop(),
            backgroundColor: Colors.grey,
          ),
        ],
      ),
    );
  }

  void _showCourseReport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Raport Cursuri'),
        content: SizedBox(
          width: 600,
          height: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Course Statistics
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Cursuri',
                        '${_courseStats['totalCourses'] ?? '0'}',
                        Icons.school,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Cursuri Active',
                        '${_courseStats['activeCourses'] ?? '0'}',
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Total Înscrieri',
                        '${_courseStats['totalEnrollments'] ?? '0'}',
                        Icons.people,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Popular Courses
                const Text(
                  'Cursuri Populare',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...List.generate(
                  _courseStats['popularCourses']?.length ?? 0,
                  (index) {
                    final course = _courseStats['popularCourses'][index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: Text('${index + 1}'),
                        ),
                        title: Text(course['name']),
                        trailing: Text(
                          '${course['enrollments']} înscrieri',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          WebOptimizedButton(
            text: 'Export PDF',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export PDF - în dezvoltare')),
              );
            },
            backgroundColor: Colors.green,
          ),
          WebOptimizedButton(
            text: 'Închide',
            onPressed: () => Navigator.of(context).pop(),
            backgroundColor: Colors.grey,
          ),
        ],
      ),
    );
  }

  void _showUserReport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Raport Utilizatori'),
        content: SizedBox(
          width: 600,
          height: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Growth Chart
                const Text(
                  'Creșterea Utilizatorilor (Ultimele 5 luni)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: const Center(
                    child: Text(
                      'Graficele sunt temporar dezactivate\npentru optimizarea aplicației',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                  // child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: (_userStats['userGrowth'] is List ? 
                        (_userStats['userGrowth'] as List).fold<double>(0, (max, value) => value > max ? value.toDouble() : max) * 1.2 : 
                        250.0),
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const months = ['Ian', 'Feb', 'Mar', 'Apr', 'Mai'];
                              if (value.toInt() < months.length) {
                                return Text(months[value.toInt()]);
                              }
                              return const Text('');
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: true),
                      barGroups: List.generate(5, (index) {
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: _userStats['userGrowth']?[index]?.toDouble() ?? 0,
                              color: Colors.orange,
                              width: 20,
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // User Types
                const Text(
                  'Tipuri de Utilizatori',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: const Center(
                    child: Text(
                      'Graficele sunt temporar dezactivate\npentru optimizarea aplicației',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                  // child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          value: _userStats['userTypes']?['students']?.toDouble() ?? 0,
                          title: 'Studenți\n${_userStats['userTypes']?['students'] ?? '0'}',
                          color: Colors.blue,
                          radius: 60,
                        ),
                        PieChartSectionData(
                          value: _userStats['userTypes']?['instructors']?.toDouble() ?? 0,
                          title: 'Instructori\n${_userStats['userTypes']?['instructors'] ?? '0'}',
                          color: Colors.green,
                          radius: 60,
                        ),
                        PieChartSectionData(
                          value: _userStats['userTypes']?['admins']?.toDouble() ?? 0,
                          title: 'Admini\n${_userStats['userTypes']?['admins'] ?? '0'}',
                          color: Colors.red,
                          radius: 60,
                        ),
                        PieChartSectionData(
                          value: _userStats['userTypes']?['guests']?.toDouble() ?? 0,
                          title: 'Vizitatori\n${_userStats['userTypes']?['guests'] ?? '0'}',
                          color: Colors.orange,
                          radius: 60,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          WebOptimizedButton(
            text: 'Export PDF',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export PDF - în dezvoltare')),
              );
            },
            backgroundColor: Colors.orange,
          ),
          WebOptimizedButton(
            text: 'Închide',
            onPressed: () => Navigator.of(context).pop(),
            backgroundColor: Colors.grey,
          ),
        ],
      ),
    );
  }

  void _showQRReport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Raport QR Bar'),
        content: SizedBox(
          width: 600,
          height: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // QR Statistics
                  ResponsiveDashboardGrid(
                    spacing: 12,
                    runSpacing: 12,
                    cards: [
                      ResponsiveDashboardCard(
                        icon: Icons.qr_code,
                        title: '${_qrStats['totalQRCodes'] ?? '0'}',
                        subtitle: 'Total QR-uri',
                        color: Colors.purple,
                      ),
                      ResponsiveDashboardCard(
                        icon: Icons.check_circle,
                        title: '${_qrStats['activeQRCodes'] ?? '0'}',
                        subtitle: 'QR-uri Active',
                        color: Colors.green,
                      ),
                      ResponsiveDashboardCard(
                        icon: Icons.visibility,
                        title: '${_qrStats['totalScans'] ?? '0'}',
                        subtitle: 'Total Scans',
                        color: Colors.blue,
                      ),
                    ],
                  ),
                const SizedBox(height: 24),
                
                // Scans by Type
                const Text(
                  'Scans pe Tipuri de QR',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...(_qrStats['scansByType']?.entries.map((entry) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getQRTypeColor(entry.key).withValues(alpha: 0.1),
                        child: Icon(_getQRTypeIcon(entry.key), color: _getQRTypeColor(entry.key)),
                      ),
                      title: Text(_getQRTypeLabel(entry.key)),
                      trailing: Text(
                        '${entry.value} scans',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }).toList() ?? []),
              ],
            ),
          ),
        ),
        actions: [
          WebOptimizedButton(
            text: 'Export PDF',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export PDF - în dezvoltare')),
              );
            },
            backgroundColor: Colors.purple,
          ),
          WebOptimizedButton(
            text: 'Închide',
            onPressed: () => Navigator.of(context).pop(),
            backgroundColor: Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getQRTypeLabel(String type) {
    switch (type) {
      case 'bar':
        return 'Bar';
      case 'course':
        return 'Cursuri';
      case 'event':
        return 'Evenimente';
      case 'discount':
        return 'Discount-uri';
      case 'attendance':
        return 'Prezență';
      default:
        return 'Necunoscut';
    }
  }

  IconData _getQRTypeIcon(String type) {
    switch (type) {
      case 'bar':
        return Icons.local_bar;
      case 'course':
        return Icons.school;
      case 'event':
        return Icons.event;
      case 'discount':
        return Icons.discount;
      case 'attendance':
        return Icons.check_circle;
      default:
        return Icons.qr_code;
    }
  }

  Color _getQRTypeColor(String type) {
    switch (type) {
      case 'bar':
        return Colors.blue;
      case 'course':
        return Colors.green;
      case 'event':
        return Colors.purple;
      case 'discount':
        return Colors.orange;
      case 'attendance':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
