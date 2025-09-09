import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aiu_dance/utils/logger.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminStatsScreen extends StatefulWidget {
  const AdminStatsScreen({super.key});

  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {
  bool _isLoading = true;
  
  // Statistics data
  int _totalUsers = 0;
  int _totalCourses = 0;
  int _totalInstructors = 0;
  int _totalStudents = 0;
  int _totalAttendance = 0;
  double _totalRevenue = 0.0;
  
  // Role distribution
  Map<String, int> _roleDistribution = {};
  
  // Course categories
  Map<String, int> _categoryDistribution = {};
  
  // Monthly attendance
  List<Map<String, dynamic>> _monthlyAttendance = [];
  
  // Recent activity
  List<Map<String, dynamic>> _recentUsers = [];
  List<Map<String, dynamic>> _recentCourses = [];

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      setState(() => _isLoading = true);
      
      // Load user statistics
      final usersResponse = await Supabase.instance.client
          .from('profiles')
          .select('role, created_at');
      
      // Load course statistics
      final coursesResponse = await Supabase.instance.client
          .from('courses')
          .select('category, created_at');
      
      // Load attendance statistics
      final attendanceResponse = await Supabase.instance.client
          .from('attendance')
          .select('scanned_at');
      
      // Load revenue statistics
      final revenueResponse = await Supabase.instance.client
          .from('wallet_transactions')
          .select('amount, type, created_at')
          .eq('type', 'credit');
      
      // Process user data
      final users = List<Map<String, dynamic>>.from(usersResponse);
      _totalUsers = users.length;
      _roleDistribution = {};
      for (final user in users) {
        final role = user['role'] ?? 'unknown';
        _roleDistribution[role] = (_roleDistribution[role] ?? 0) + 1;
      }
      _totalInstructors = _roleDistribution['instructor'] ?? 0;
      _totalStudents = _roleDistribution['student'] ?? 0;
      
      // Process course data
      final courses = List<Map<String, dynamic>>.from(coursesResponse);
      _totalCourses = courses.length;
      _categoryDistribution = {};
      for (final course in courses) {
        final category = course['category'] ?? 'unknown';
        _categoryDistribution[category] = (_categoryDistribution[category] ?? 0) + 1;
      }
      
      // Process attendance data
      final attendance = List<Map<String, dynamic>>.from(attendanceResponse);
      _totalAttendance = attendance.length;
      
      // Process revenue data
      final revenue = List<Map<String, dynamic>>.from(revenueResponse);
      _totalRevenue = revenue.fold(0.0, (sum, t) => sum + (t['amount'] ?? 0.0));
      
      // Load recent users
      final recentUsersResponse = await Supabase.instance.client
          .from('profiles')
          .select('full_name, email, role, created_at')
          .order('created_at', ascending: false)
          .limit(5);
      
      // Load recent courses
      final recentCoursesResponse = await Supabase.instance.client
          .from('courses')
          .select('title, category, created_at')
          .order('created_at', ascending: false)
          .limit(5);
      
      setState(() {
        _recentUsers = List<Map<String, dynamic>>.from(recentUsersResponse);
        _recentCourses = List<Map<String, dynamic>>.from(recentCoursesResponse);
        _isLoading = false;
      });
      
      Logger.info('Loaded statistics: $_totalUsers users, $_totalCourses courses, $_totalAttendance attendance');
    } catch (e) {
      Logger.error('Error loading statistics: $e');
      setState(() => _isLoading = false);
      _showErrorSnackBar('Eroare la încărcarea statisticilor');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // Charts activated for admin dashboard
  List<PieChartSectionData> _getRolePieChartData() {
    final colors = [Colors.blue, Colors.green, Colors.red, Colors.orange];
    int colorIndex = 0;
    
    return _roleDistribution.entries.map((entry) {
      final color = colors[colorIndex % colors.length];
      colorIndex++;
      
      return PieChartSectionData(
        color: color,
        value: entry.value.toDouble(),
        title: '${entry.key}\n${entry.value}',
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  List<BarChartGroupData> _getCategoryBarChartData() {
    final colors = [Colors.purple, Colors.blue, Colors.green, Colors.orange, Colors.red];
    int colorIndex = 0;
    
    return _categoryDistribution.entries.map((entry) {
      final color = colors[colorIndex % colors.length];
      colorIndex++;
      
      return BarChartGroupData(
        x: colorIndex - 1,
        barRods: [
          BarChartRodData(
            toY: entry.value.toDouble(),
            color: color,
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistici Globale'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatistics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Utilizatori',
                          _totalUsers.toString(),
                          Icons.people,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          'Cursuri',
                          _totalCourses.toString(),
                          Icons.school,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Instructori',
                          _totalInstructors.toString(),
                          Icons.person,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          'Studenți',
                          _totalStudents.toString(),
                          Icons.school,
                          Colors.purple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Prezențe',
                          _totalAttendance.toString(),
                          Icons.check_circle,
                          Colors.teal,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          'Venituri',
                          '${_totalRevenue.toStringAsFixed(2)} RON',
                          Icons.attach_money,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Role Distribution Chart
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Distribuția Utilizatorilor pe Roluri',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 200,
                            child: PieChart(
                              PieChartData(
                                sections: _getRolePieChartData(),
                                centerSpaceRadius: 40,
                                sectionsSpace: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Course Categories Chart
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Distribuția Cursurilor pe Categorii',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 200,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: _categoryDistribution.values.isEmpty 
                                    ? 10 
                                    : _categoryDistribution.values.reduce((a, b) => a > b ? a : b).toDouble() + 2,
                                barGroups: _getCategoryBarChartData(),
                                titlesData: FlTitlesData(
                                  leftTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: true),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        final categories = _categoryDistribution.keys.toList();
                                        if (value.toInt() < categories.length) {
                                          return Text(
                                            categories[value.toInt()],
                                            style: const TextStyle(fontSize: 10),
                                          );
                                        }
                                        return const Text('');
                                      },
                                    ),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Recent Activity
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Utilizatori Recenti',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 12),
                                ..._recentUsers.map((user) => ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.blue,
                                    child: Text(
                                      user['full_name']?.toString().substring(0, 1).toUpperCase() ?? 'U',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  title: Text(user['full_name'] ?? 'Necunoscut'),
                                  subtitle: Text(user['role']?.toString().toUpperCase() ?? 'UNKNOWN'),
                                  dense: true,
                                )),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Cursuri Recente',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 12),
                                ..._recentCourses.map((course) => ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: Colors.green,
                                    child: Icon(Icons.school, color: Colors.white),
                                  ),
                                  title: Text(course['title'] ?? 'Necunoscut'),
                                  subtitle: Text(course['category']?.toString().toUpperCase() ?? 'UNKNOWN'),
                                  dense: true,
                                )),
                              ],
                            ),
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

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
