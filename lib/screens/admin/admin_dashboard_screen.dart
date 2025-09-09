import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aiu_dance/utils/logger.dart';
import 'users/admin_users_screen.dart';
import 'courses/admin_courses_screen.dart';
import 'attendance/admin_attendance_screen.dart';
import 'finance/admin_finance_screen.dart';
import 'stats/admin_stats_screen.dart';
import 'announcements/admin_announcements_screen.dart';
import 'wallet/admin_wallet_screen.dart';
import 'reports/reports_screen.dart';
import 'settings/settings_screen.dart';
import '../../widgets/responsive_dashboard_card.dart';
import 'bar/qr_bar_menu_screen.dart';
import 'bar/bar_orders_management_screen.dart'; // QR Bar Menu Screen
import 'bar/bar_product_management_screen.dart';
// import 'bar/bar_order_admin_screen.dart'; // Fișier șters

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  
  // Statistics data
  Map<String, dynamic> _stats = {};
  Map<String, dynamic> _paymentStats = {};
  List<Map<String, dynamic>> _recentUsers = [];
  List<Map<String, dynamic>> _recentCourses = [];
  List<Map<String, dynamic>> _recentTransactions = [];
  List<Map<String, dynamic>> _recentAttendance = [];
  List<Map<String, dynamic>> _recentBarOrders = [];
  
  // User profile data
  Map<String, dynamic>? _userProfile;

  @override
  void initState() {
    super.initState();
    print('AdminDashboard: initState start');
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      print('AdminDashboard: Loading dashboard data...');
      await Future.wait([
        _loadUserProfile(),
        _loadStats(),
        _loadPaymentStats(),
        _loadRecentUsers(),
        _loadRecentCourses(),
        _loadRecentTransactions(),
        _loadRecentAttendance(),
        _loadRecentBarOrders(),
      ]);
      
      setState(() {
        _isLoading = false;
      });
      
      print('AdminDashboard: Dashboard data loaded successfully');
    } catch (e) {
      print('AdminDashboard: Error loading dashboard data: $e');
      Logger.error('Error loading dashboard data', e);
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final response = await Supabase.instance.client
            .from('profiles')
            .select('*')
            .eq('id', user.id)
            .single();
        
    setState(() {
          _userProfile = response;
        });
        print('AdminDashboard: User profile loaded: ${_userProfile?['full_name']}');
      }
    } catch (e) {
      print('AdminDashboard: Error loading user profile: $e');
      Logger.error('Error loading user profile', e);
    }
  }

  Future<void> _loadStats() async {
    try {
      print('AdminDashboard: Loading stats...');
      
      // Load users count
      final usersResponse = await Supabase.instance.client
          .from('profiles')
          .select('id, role')
          .neq('id', '00000000-0000-0000-0000-000000000000'); // Exclude null
      
      final users = usersResponse as List;
      final totalUsers = users.length;
      final totalInstructors = users.where((u) => u['role'] == 'instructor').length;
      final totalStudents = users.where((u) => u['role'] == 'student').length;
      
      // Load courses count
      final coursesResponse = await Supabase.instance.client
          .from('courses')
          .select('id, is_active');
      
      final courses = coursesResponse as List;
      final totalCourses = courses.length;
      final activeCourses = courses.where((c) => c['is_active'] == true).length;
      
      // Load transactions count and total
      final transactionsResponse = await Supabase.instance.client
          .from('wallet_transactions')
          .select('amount, type');
      
      final transactions = transactionsResponse as List;
      final totalTransactions = transactions.length;
      final totalRevenue = transactions
          .where((t) => t['type'] == 'wallet')
          .fold<double>(0, (sum, t) => sum + (double.tryParse(t['amount']?.toString() ?? '0') ?? 0));
      
      // Load attendance count
      final attendanceResponse = await Supabase.instance.client
          .from('attendance')
          .select('id');
      
      final attendance = attendanceResponse as List;
      final totalAttendance = attendance.length;
      
      // Load bar orders count
      final barOrdersResponse = await Supabase.instance.client
          .from('bar_orders')
          .select('id, status');
      
      final barOrders = barOrdersResponse as List;
      final totalBarOrders = barOrders.length;
      final activeBarOrders = barOrders.where((o) => o['status'] == 'pending').length;
      
    setState(() {
        _stats = {
          'totalUsers': totalUsers,
          'totalInstructors': totalInstructors,
          'totalStudents': totalStudents,
          'totalCourses': totalCourses,
          'activeCourses': activeCourses,
          'totalTransactions': totalTransactions,
          'totalRevenue': totalRevenue,
          'totalAttendance': totalAttendance,
          'totalBarOrders': totalBarOrders,
          'activeBarOrders': activeBarOrders,
        };
      });
      
      print('AdminDashboard: Stats loaded successfully');
      print('Users: $totalUsers, Courses: $totalCourses, Revenue: $totalRevenue');
    } catch (e) {
      print('AdminDashboard: Error loading stats: $e');
      Logger.error('Error loading stats', e);
      setState(() {
        _stats = {
          'totalUsers': 1,
          'totalInstructors': 0,
          'totalStudents': 1,
          'totalCourses': 0,
          'activeCourses': 0,
          'totalTransactions': 0,
          'totalRevenue': 0.0,
          'totalAttendance': 0,
          'totalBarOrders': 0,
          'activeBarOrders': 0,
        };
      });
    }
  }

  Future<void> _loadRecentUsers() async {
    try {
      print('AdminDashboard: Loading recent users...');
      final response = await Supabase.instance.client
          .from('profiles')
          .select('*')
          .order('created_at', ascending: false)
          .limit(5);

      print('AdminDashboard: Recent users loaded: ${response.length}');
                  setState(() {
        _recentUsers = (response as List).map((user) => {
          'name': user['full_name']?.toString() ?? 'N/A',
          'email': user['email']?.toString() ?? 'N/A',
          'role': user['role']?.toString() ?? 'user',
          'status': user['is_active'] == true ? 'active' : 'inactive',
          'created_at': user['created_at']?.toString() ?? 'N/A',
        }).toList();
      });
    } catch (e) {
      print('AdminDashboard: Error loading recent users: $e');
      Logger.error('Error loading recent users', e);
      setState(() {
        _recentUsers = [
          {
            'name': 'Admin Demo',
            'email': 'admin@demo.com',
            'role': 'admin',
            'status': 'active',
            'created_at': DateTime.now().toString(),
          }
        ];
      });
    }
  }

  Future<void> _loadRecentCourses() async {
    try {
      print('AdminDashboard: Loading recent courses...');
      final response = await Supabase.instance.client
          .from('courses')
          .select('*')
          .order('created_at', ascending: false)
          .limit(5);

      print('AdminDashboard: Recent courses loaded: ${response.length}');
      setState(() {
        _recentCourses = (response as List).map((course) => {
          'name': course['title']?.toString() ?? 'N/A',
          'category': course['category']?.toString() ?? 'N/A',
          'instructor': course['instructor_id']?.toString() ?? 'N/A',
          'students': course['max_students']?.toString() ?? '0',
          'price': course['price']?.toString() ?? '0',
          'created_at': course['created_at']?.toString() ?? 'N/A',
        }).toList();
      });
    } catch (e) {
      print('AdminDashboard: Error loading recent courses: $e');
      Logger.error('Error loading recent courses', e);
      setState(() {
        _recentCourses = [
          {
            'name': 'Bachata Începători',
            'category': 'Bachata',
            'instructor': 'Instructor Demo',
            'students': '20',
            'price': '50',
            'created_at': DateTime.now().toString(),
          }
        ];
      });
    }
  }

  Future<void> _loadRecentTransactions() async {
    try {
      print('AdminDashboard: Loading recent transactions...');
      final response = await Supabase.instance.client
          .from('wallet_transactions')
          .select('*')
          .order('created_at', ascending: false)
          .limit(5);

      print('AdminDashboard: Recent transactions loaded: ${response.length}');
      setState(() {
        _recentTransactions = (response as List).map((transaction) => {
          'amount': transaction['amount']?.toString() ?? '0',
          'type': transaction['type']?.toString() ?? 'wallet',
          'status': transaction['status']?.toString() ?? 'completed',
          'created_at': transaction['created_at']?.toString() ?? 'N/A',
        }).toList();
      });
    } catch (e) {
      print('AdminDashboard: Error loading recent transactions: $e');
      Logger.error('Error loading recent transactions', e);
      setState(() {
        _recentTransactions = [];
      });
    }
  }

  Future<void> _loadRecentAttendance() async {
    try {
      print('AdminDashboard: Loading recent attendance...');
      final response = await Supabase.instance.client
          .from('attendance')
          .select('*')
          .order('created_at', ascending: false)
          .limit(5);

      print('AdminDashboard: Recent attendance loaded: ${response.length}');
      setState(() {
        _recentAttendance = (response as List).map((attendance) => {
          'user_id': attendance['user_id']?.toString() ?? 'N/A',
          'course_id': attendance['course_id']?.toString() ?? 'N/A',
          'status': attendance['status']?.toString() ?? 'present',
          'created_at': attendance['created_at']?.toString() ?? 'N/A',
        }).toList();
      });
    } catch (e) {
      print('AdminDashboard: Error loading recent attendance: $e');
      Logger.error('Error loading recent attendance', e);
      setState(() {
        _recentAttendance = [];
      });
    }
  }

  Future<void> _loadRecentBarOrders() async {
    try {
      print('AdminDashboard: Loading recent bar orders...');
      final response = await Supabase.instance.client
          .from('bar_orders')
          .select('*')
          .order('created_at', ascending: false)
          .limit(5);

      print('AdminDashboard: Recent bar orders loaded: ${response.length}');
      setState(() {
        _recentBarOrders = (response as List).map((order) => {
          'user_id': order['user_id']?.toString() ?? 'N/A',
          'product_name': order['product_name']?.toString() ?? 'N/A',
          'quantity': order['quantity']?.toString() ?? '1',
          'total_price': order['total_price']?.toString() ?? '0',
          'status': order['status']?.toString() ?? 'pending',
          'created_at': order['created_at']?.toString() ?? 'N/A',
        }).toList();
      });
    } catch (e) {
      print('AdminDashboard: Error loading recent bar orders: $e');
      Logger.error('Error loading recent bar orders', e);
      setState(() {
        _recentBarOrders = [];
      });
    }
  }

  Future<void> _loadPaymentStats() async {
    try {
      print('AdminDashboard: Loading payment stats...');
      
      // Load payment statistics from course_payments table
      final pendingPayments = await Supabase.instance.client
          .from('course_payments')
          .select('id')
          .eq('status', 'pending');

      final completedPayments = await Supabase.instance.client
          .from('course_payments')
          .select('id')
          .eq('status', 'paid');

      final ratePayments = await Supabase.instance.client
          .from('course_payments')
          .select('id')
          .eq('method', 'rate');

      setState(() {
        _paymentStats = {
          'pending': pendingPayments.length,
          'completed': completedPayments.length,
          'rate': ratePayments.length,
        };
      });

      print('AdminDashboard: Payment stats loaded: ${_paymentStats}');
    } catch (e) {
      print('AdminDashboard: Error loading payment stats: $e');
      Logger.error('Error loading payment stats: $e');
      setState(() {
        _paymentStats = {
          'pending': 0,
          'completed': 0,
          'rate': 0,
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('AdminDashboard: build start');
    
    if (_isLoading) {
      return _buildLoading();
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
              children: [
          // Header with AppBar
          _buildHeader(),
          
          // Navigation Tabs
          _buildNavigationTabs(),
          
          // Content based on selected tab
                Expanded(
            child: _buildTabContent(),
                ),
              ],
            ),
    );
  }

  Widget _buildLoading() {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Center(
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
        children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
            ),
            SizedBox(height: 20),
            Text(
              'Se încarcă Dashboard Admin...',
              style: TextStyle(
                fontSize: 18,
                color: Colors.purple,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple, Colors.deepPurple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = constraints.maxWidth < 500;
              
              if (isSmallScreen) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Admin Dashboard',
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: _navigateToQRAttendance,
                          icon: const Icon(Icons.qr_code, color: Colors.white, size: 18),
                          padding: EdgeInsets.zero,
                          tooltip: 'QR Prezență',
                        ),
                        IconButton(
                          onPressed: _showLogoutDialog,
                          icon: const Icon(Icons.logout, color: Colors.white, size: 20),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ],
                );
              }
              
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Logo and Title
                    SizedBox(
                      width: 250,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.admin_panel_settings,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 15),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dashboard Admin',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'AIU Dance Management',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
              
              const Spacer(),
              
              // User Info and Logout
              Row(
                children: [
                  // User Avatar and Info
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.white,
                          child: Text(
                            _userProfile?['full_name']?.toString().substring(0, 1).toUpperCase() ?? 'A',
                            style: const TextStyle(
                              color: Colors.purple,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _userProfile?['full_name']?.toString() ?? 'Admin',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _userProfile?['role']?.toString().toUpperCase() ?? 'ADMIN',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 15),
                  
                  // QR Attendance Button
                  IconButton(
                    onPressed: _navigateToQRAttendance,
                    icon: const Icon(Icons.qr_code, color: Colors.white),
                    tooltip: 'Prezență QR',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                  
                  const SizedBox(width: 10),
                  
                  // Logout Button
                  IconButton(
                    onPressed: _showLogoutDialog,
                    icon: const Icon(Icons.logout, color: Colors.white),
                    tooltip: 'Deconectare',
                  ),
                ],
              ),
            ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildTabButton('Dashboard', 0, Icons.dashboard),
            _buildTabButton('Utilizatori', 1, Icons.people),
            _buildTabButton('Cursuri', 2, Icons.school),
            _buildTabButton('Anunțuri', 3, Icons.announcement),
            _buildTabButton('Prezență', 4, Icons.check_circle),
            _buildTabButton('QR Bar', 5, Icons.local_bar),
            _buildTabButton('Portofel', 6, Icons.account_balance_wallet),
            _buildTabButton('Rapoarte', 7, Icons.analytics),
            _buildTabButton('Setări', 8, Icons.settings),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String title, int index, IconData icon) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.purple : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.purple,
              size: 20,
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.purple,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardTab();
      case 1:
        return _buildUsersTab();
      case 2:
        return _buildCoursesTab();
      case 3:
        return _buildAnnouncementsTab();
      case 4:
        return _buildAttendanceTab();
      case 5:
        return _buildQRBarTab();
      case 6:
        return _buildWalletTab();
      case 7:
        return _buildReportsTab();
      case 8:
        return _buildSettingsTab();
      default:
        return _buildDashboardTab();
    }
  }

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistics Cards
          _buildStatisticsGrid(),
          
          const SizedBox(height: 30),
          
          // Recent Activity
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 800) {
                // Mobile: Stack vertical
                return Column(
                  children: [
                    _buildRecentUsersCard(),
                    const SizedBox(height: 20),
                    _buildRecentCoursesCard(),
                  ],
                );
              } else {
                // Desktop: Side by side
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildRecentUsersCard()),
                    const SizedBox(width: 20),
                    Expanded(child: _buildRecentCoursesCard()),
                  ],
                );
              }
            },
          ),
          
          const SizedBox(height: 30),
          
          // Financial Overview
          _buildFinancialOverviewCard(),
          
          const SizedBox(height: 30),
          
          // Quick Actions
          _buildQuickActionsCard(),
          _buildPaymentStatsCard(),
        ],
      ),
    );
  }

  Widget _buildStatisticsGrid() {
    return ResponsiveDashboardGrid(
      spacing: 16,
      runSpacing: 16,
      cards: [
        DashboardCardBuilder.buildUserCard(
          _stats['totalUsers'] ?? 0,
          onTap: () => setState(() => _selectedIndex = 1), // Navigate to Users tab
        ),
        DashboardCardBuilder.buildCoursesCard(
          _stats['totalCourses'] ?? 0,
          onTap: () => setState(() => _selectedIndex = 2), // Navigate to Courses tab
        ),
        DashboardCardBuilder.buildRevenueCard(
          _stats['totalRevenue']?.toDouble() ?? 0.0,
          onTap: () => setState(() => _selectedIndex = 5), // Navigate to Wallet tab
        ),
        DashboardCardBuilder.buildAttendanceCard(
          _stats['totalAttendance'] ?? 0,
          onTap: () => setState(() => _selectedIndex = 3), // Navigate to Attendance tab
        ),
        DashboardCardBuilder.buildBarOrdersCard(
          _stats['totalBarOrders'] ?? 0,
          onTap: () => setState(() => _selectedIndex = 4), // Navigate to QR Bar tab
        ),
        DashboardCardBuilder.buildPaymentsCard(
          _stats['totalTransactions'] ?? 0,
          onTap: () => setState(() => _selectedIndex = 6), // Navigate to Reports tab
        ),
      ],
    );
  }

  Widget _buildStatCard(Map<String, dynamic> stat) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: (stat['color'] as Color).withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(stat['icon'] as IconData, color: stat['color'] as Color, size: 30),
            const Spacer(),
            Text(
              stat['value'] as String,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: stat['color'] as Color,
              ),
            ),
            Text(
              stat['title'] as String,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              stat['subtitle'] as String,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentUsersCard() {
    return _buildSectionCard(
      'Utilizatori Recenți',
      Icons.people,
      _buildRecentUsersList(),
    );
  }

  Widget _buildRecentCoursesCard() {
    return _buildSectionCard(
      'Cursuri Recente',
      Icons.school,
      _buildRecentCoursesList(),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, Widget content) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.purple, size: 24),
                const SizedBox(width: 10),
            Text(
              title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildRecentUsersList() {
    if (_recentUsers.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            'Nu există utilizatori recenți',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ),
      );
    }
    
    return SizedBox(
      height: 300, // Fixed height to prevent overflow
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _recentUsers.length,
        itemBuilder: (context, index) {
          final user = _recentUsers[index];
        final userName = user['name']?.toString() ?? 'Utilizator necunoscut';
        final userEmail = user['email']?.toString() ?? 'Email necunoscut';
        final userRole = user['role']?.toString() ?? 'student';
        final userStatus = user['status']?.toString() ?? 'inactive';
        
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: _getRoleColor(userRole),
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      userEmail,
          style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getRoleColor(userRole).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            userRole.toUpperCase(),
                            style: TextStyle(
                              color: _getRoleColor(userRole),
                              fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getStatusColor(userStatus).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            userStatus.toUpperCase(),
                            style: TextStyle(
                              color: _getStatusColor(userStatus),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
        },
      ),
    );
  }

  Widget _buildRecentCoursesList() {
    if (_recentCourses.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            'Nu există cursuri recente',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ),
      );
    }
    
    return SizedBox(
      height: 300, // Fixed height to prevent overflow
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _recentCourses.length,
        itemBuilder: (context, index) {
          final course = _recentCourses[index];
        final courseName = course['name']?.toString() ?? 'Curs necunoscut';
        final courseCategory = course['category']?.toString() ?? 'N/A';
        final courseInstructor = course['instructor']?.toString() ?? 'N/A';
        final courseStudents = course['students']?.toString() ?? '0';
        final coursePrice = course['price']?.toString() ?? '0';
        
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
          children: [
              Icon(Icons.school, color: Colors.purple, size: 24),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      courseName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Categorie: $courseCategory',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Instructor: $courseInstructor',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '${courseStudents} studenți',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Text(
                          '${coursePrice} RON',
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
        },
      ),
    );
  }

  Widget _buildFinancialOverviewCard() {
    return _buildSectionCard(
      'Prezentare Financiară',
      Icons.attach_money,
      Column(
        children: [
          ResponsiveDashboardGrid(
            spacing: 16,
            runSpacing: 16,
            cards: [
              DashboardCardBuilder.buildRevenueCard(
                _stats['totalRevenue']?.toDouble() ?? 0.0,
                onTap: () => setState(() => _selectedIndex = 5),
              ),
              DashboardCardBuilder.buildCustomCard(
                icon: Icons.receipt,
                title: '${_stats['totalTransactions'] ?? 0}',
                subtitle: 'Tranzacții',
                color: Colors.blue,
                onTap: () => setState(() => _selectedIndex = 6),
              ),
              DashboardCardBuilder.buildBarOrdersCard(
                _stats['totalBarOrders'] ?? 0,
                onTap: () => setState(() => _selectedIndex = 4),
              ),
              DashboardCardBuilder.buildAttendanceCard(
                _stats['totalAttendance'] ?? 0,
                onTap: () => setState(() => _selectedIndex = 3),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialItem(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 10),
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
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            ),
          ],
        ),
    );
  }

  Widget _buildQuickActionsCard() {
    return _buildSectionCard(
      'Acțiuni Rapide',
      Icons.flash_on,
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 1.2,
        children: [
          _buildQuickActionButton('Adaugă Utilizator', Icons.person_add, Colors.blue, () => _navigateToUsers()),
          _buildQuickActionButton('Creează Curs', Icons.add_circle, Colors.green, () => _navigateToCourses()),
          _buildQuickActionButton('Prezență QR', Icons.qr_code, Colors.teal, () => _navigateToQRAttendance()),
          _buildQuickActionButton('Plăți Cursuri', Icons.payment, Colors.purple, () => _navigateToCoursePayments()),
          _buildQuickActionButton('Portofel Admin', Icons.account_balance_wallet, Colors.indigo, () => _navigateToWallet()),
          _buildQuickActionButton('Generează Raport', Icons.description, Colors.orange, () => _navigateToReports()),
          _buildQuickActionButton('Setări', Icons.settings, Colors.grey, () => _navigateToSettings()),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Tab Content Methods
  Widget _buildUsersTab() {
    return const AdminUsersScreen();
  }

  Widget _buildCoursesTab() {
    return const AdminCoursesScreen();
  }

  Widget _buildAnnouncementsTab() {
    return const AdminAnnouncementsScreen();
  }

  Widget _buildAttendanceTab() {
    return const AdminAttendanceScreen();
  }

  Widget _buildQRBarTab() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.orange.shade50,
            child: TabBar(
              labelColor: Colors.orange.shade600,
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: Colors.orange.shade600,
              tabs: const [
                Tab(
                  icon: Icon(Icons.restaurant_menu),
                  text: 'Meniu Produse',
                ),
                Tab(
                  icon: Icon(Icons.receipt_long),
                  text: 'Comenzi & QR Plăți',
                ),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                QRBarMenuScreen(),
                BarOrdersManagementScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletTab() {
    return const AdminWalletScreen();
  }

  Widget _buildReportsTab() {
    return const ReportsScreen();
  }

  Widget _buildSettingsTab() {
    return const SettingsScreen();
  }

  Widget _buildSettingsItem(String title, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
            color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  // Navigation Methods
  void _navigateToUsers() {
    setState(() => _selectedIndex = 1);
  }

  void _navigateToCourses() {
    setState(() => _selectedIndex = 2);
  }

  void _navigateToReports() {
    setState(() => _selectedIndex = 7);
  }

  void _navigateToSettings() {
    setState(() => _selectedIndex = 8);
  }

  void _navigateToCoursePayments() {
    Navigator.pushNamed(context, '/admin/courses/payments');
  }

  void _navigateToWallet() {
    setState(() => _selectedIndex = 6); // Wallet screen index
  }

  void _navigateToQRAttendance() {
    Navigator.pushNamed(context, '/admin/qr/attendance');
  }

  Widget _buildPaymentStatsCard() {
    return _buildSectionCard(
      'Statistici Plăți',
      Icons.analytics,
      Column(
              children: [
          ResponsiveDashboardGrid(
              spacing: 12,
              runSpacing: 12,
              cards: [
                DashboardCardBuilder.buildCustomCard(
                  icon: Icons.hourglass_empty,
                  title: '${_paymentStats['pending'] ?? 0}',
                  subtitle: 'În Așteptare',
                  color: Colors.orange,
                ),
                DashboardCardBuilder.buildCustomCard(
                  icon: Icons.check_circle,
                  title: '${_paymentStats['completed'] ?? 0}',
                  subtitle: 'Efectuate',
                  color: Colors.green,
                ),
                DashboardCardBuilder.buildCustomCard(
                  icon: Icons.credit_card,
                  title: '${_paymentStats['rate'] ?? 0}',
                  subtitle: 'În Rate',
                  color: Colors.blue,
                ),
              ],
            ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => _navigateToCoursePayments(),
                icon: const Icon(Icons.payment, size: 16),
                label: const Text('Gestionează Plăți'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _navigateToWallet(),
                icon: const Icon(Icons.account_balance_wallet, size: 16),
                label: const Text('Portofel Admin'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
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
    );
  }

  // Utility Methods
  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'instructor':
        return Colors.blue;
      case 'student':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'inactive':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature va fi disponibil în curând!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  // App Configuration Methods
  void _showStripeSettings() => _showSettingsDialog('Configurare Stripe', [
    'Chei API Stripe (Test/Live)',
    'Configurare Webhook-uri',
    'Setări Plăți Recurente',
    'Taxe și Comisioane',
    'Monede Acceptate',
  ]);

  void _showSupabaseSettings() => _showSettingsDialog('Configurare Supabase', [
    'URL Proiect Supabase',
    'Chei API (anon/service)',
    'Configurare RLS',
    'Backup Automat',
    'Migrări Schema',
  ]);

  void _showQRSettings() => _showSettingsDialog('Configurare QR', [
    'Template-uri QR Code',
    'Setări Expirare',
    'Design și Logo',
    'Tracking Scanări',
    'Securitate QR',
  ]);

  void _showAppUrlSettings() => _showSettingsDialog('URL-uri Aplicație', [
    'URL Website Principal',
    'URL-uri Deep Link',
    'URL-uri Rețele Sociale',
    'URL-uri API',
    'Redirecturi OAuth',
  ]);

  // User Management Methods
  void _showRoleManagement() => _showSettingsDialog('Management Roluri', [
    'Definire Roluri Custom',
    'Permisiuni per Rol',
    'Ierarhie Roluri',
    'Schimbare Roluri',
    'Audit Trail',
  ]);

  void _showPermissionsSettings() => _showSettingsDialog('Permisiuni', [
    'Permisiuni Modulare',
    'Restricții Acces',
    'Permisiuni Temporare',
    'Loguri Permisiuni',
    'Setări Securitate',
  ]);

  void _showAuthSettings() => _showSettingsDialog('Autentificare', [
    'Metode Autentificare',
    '2FA/MFA Settings',
    'Password Policies',
    'Session Management',
    'OAuth Providers',
  ]);

  void _showAccountPolicies() => _showSettingsDialog('Politici Cont', [
    'Politici Parolă',
    'Expirare Conturi',
    'Blocare Conturi',
    'Recuperare Cont',
    'GDPR Compliance',
  ]);

  // Business Settings Methods
  void _showStudioInfo() => _showSettingsDialog('Informații Studio', [
    'Nume și Logo Studio',
    'Adresă și Contact',
    'Program Funcționare',
    'Instructori și Staff',
    'Facilități Studio',
  ]);

  void _showCoursePrograms() => _showSettingsDialog('Programe Cursuri', [
    'Tipuri de Cursuri',
    'Nivele Dificultate',
    'Durata Cursuri',
    'Capacitate Săli',
    'Programe Speciale',
  ]);

  void _showPricingSettings() => _showSettingsDialog('Prețuri & Pachete', [
    'Lista Prețuri',
    'Pachete Abonament',
    'Reduceri și Promoții',
    'Prețuri Grup vs Individual',
    'Politici Rambursare',
  ]);

  void _showCancellationPolicies() => _showSettingsDialog('Politici Anulare', [
    'Termene Anulare',
    'Taxe Anulare',
    'Reprogramări',
    'Politici Refund',
    'Excepții Speciale',
  ]);

  // Communication Methods
  void _showEmailTemplates() => _showSettingsDialog('Template-uri Email', [
    'Email Confirmare',
    'Reminder-uri Curs',
    'Newsletter',
    'Email Marketing',
    'Notificări Sistem',
  ]);

  void _showPushNotifications() => _showSettingsDialog('Notificări Push', [
    'Setări Firebase',
    'Template-uri Notificări',
    'Programare Notificări',
    'Segmentare Utilizatori',
    'Analytics Notificări',
  ]);

  void _showSocialMediaSettings() => _showSettingsDialog('Rețele Sociale', [
    'Linkuri Social Media',
    'API Keys (Facebook, Instagram)',
    'Auto-posting Settings',
    'Hashtag-uri Default',
    'Cross-platform Sharing',
  ]);

  void _showAutoMessaging() => _showSettingsDialog('Mesagerie Automată', [
    'Chatbot Settings',
    'Răspunsuri Automate',
    'Workflow-uri Mesaje',
    'Integrare WhatsApp',
    'AI Response Settings',
  ]);

  // System & Data Methods
  void _showBackupSettings() => _showSettingsDialog('Backup Date', [
    'Programare Backup-uri',
    'Locații Stocare',
    'Retenție Date',
    'Restore Procedures',
    'Verificare Integritate',
  ]);

  void _showSystemLogs() => _showSettingsDialog('Logs Sistem', [
    'Nivele Logging',
    'Rotație Log-uri',
    'Monitorizare Erori',
    'Alerting System',
    'Performance Logs',
  ]);

  void _showPerformanceAnalytics() => _showSettingsDialog('Analiză Performanță', [
    'Metrici Performanță',
    'Monitoring Server',
    'Usage Analytics',
    'Rapoarte Performanță',
    'Optimizări Automate',
  ]);

  void _showSecuritySettings() => _showSettingsDialog('Securitate', [
    'Firewall Settings',
    'Rate Limiting',
    'IP Whitelisting',
    'Audit Logs',
    'Vulnerability Scanning',
  ]);

  // App Settings Methods
  void _showLanguageSettings() => _showSettingsDialog('Limba Aplicație', [
    'Limbi Disponibile',
    'Traduceri Custom',
    'Localizare Date',
    'RTL Support',
    'Font Settings',
  ]);

  void _showThemeSettings() => _showSettingsDialog('Tema & Culori', [
    'Paleta Culori',
    'Dark/Light Mode',
    'Brand Colors',
    'Teme Custom',
    'Accessibility Colors',
  ]);

  void _showLayoutSettings() => _showSettingsDialog('Layout & UI', [
    'Layout Responsive',
    'Component Styling',
    'Navigation Settings',
    'Mobile/Desktop Views',
    'Custom CSS',
  ]);

  void _showUpdateSettings() => _showSettingsDialog('Actualizări', [
    'Verificare Actualizări',
    'Auto-update Settings',
    'Release Notes',
    'Beta Testing',
    'Rollback Procedures',
  ]);

  void _showSettingsDialog(String title, List<String> features) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.settings, color: Colors.purple),
            const SizedBox(width: 10),
            Expanded(child: Text(title)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Text(
                'Funcționalități disponibile:',
                  style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 10),
              ...features.map((feature) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, 
                         color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(feature)),
                  ],
                ),
              )).toList(),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Această secțiune va fi implementată în versiunile viitoare.',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Închide'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deconectare'),
        content: const Text('Ești sigur că vrei să te deconectezi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anulează'),
          ),
          ElevatedButton(
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Deconectare'),
          ),
        ],
      ),
    );
  }
}