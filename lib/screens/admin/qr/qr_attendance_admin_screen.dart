import 'package:flutter/material.dart';
import 'package:aiu_dance/services/qr_attendance_service.dart';
import 'package:aiu_dance/widgets/qr_generator_widget.dart';
import 'package:aiu_dance/utils/logger.dart';

class QRAttendanceAdminScreen extends StatefulWidget {
  const QRAttendanceAdminScreen({super.key});

  @override
  State<QRAttendanceAdminScreen> createState() => _QRAttendanceAdminScreenState();
}

class _QRAttendanceAdminScreenState extends State<QRAttendanceAdminScreen> {
  List<Map<String, dynamic>> _courses = [];
  Map<String, dynamic>? _selectedCourse;
  bool _isLoading = true;
  bool _showQRGenerator = false;
  Map<String, dynamic> _attendanceStats = {};
  List<Map<String, dynamic>> _recentAttendance = [];

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final courses = await QRAttendanceService.getActiveCourses();
      setState(() {
        _courses = courses;
        _isLoading = false;
      });

      Logger.info('Loaded ${courses.length} active courses');
    } catch (e) {
      Logger.error('Error loading courses: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        _showErrorSnackBar('Eroare la încărcarea cursurilor: $e');
      }
    }
  }

  Future<void> _loadCourseStats(String courseId) async {
    try {
      final stats = await QRAttendanceService.getCourseAttendanceStats(courseId);
      final attendanceList = await QRAttendanceService.getCourseAttendanceList(courseId);
      
      setState(() {
        _attendanceStats = stats;
        _recentAttendance = attendanceList.take(10).toList();
      });
    } catch (e) {
      Logger.error('Error loading course stats: $e');
    }
  }

  void _onCourseSelected(Map<String, dynamic>? course) {
    setState(() {
      _selectedCourse = course;
      _showQRGenerator = false;
      _attendanceStats = {};
      _recentAttendance = [];
    });

    if (course != null) {
      _loadCourseStats(course['id']);
    }
  }

  void _generateQRForCourse() {
    if (_selectedCourse != null) {
      setState(() {
        _showQRGenerator = true;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prezență prin QR'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadCourses,
            icon: const Icon(Icons.refresh),
            tooltip: 'Reîncarcă cursurile',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Se încarcă cursurile...'),
                ],
              ),
            )
          : _courses.isEmpty
              ? _buildEmptyState()
              : _buildMainContent(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Nu există cursuri active',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Creează un curs activ pentru a genera QR-uri de prezență',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadCourses,
            icon: const Icon(Icons.refresh),
            label: const Text('Reîncarcă'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course Selection Card
          _buildCourseSelectionCard(),
          
          const SizedBox(height: 20),

          // Course Stats (if course selected)
          if (_selectedCourse != null) ...[
            _buildCourseStatsCard(),
            const SizedBox(height: 20),
          ],

          // QR Generator Button
          if (_selectedCourse != null && !_showQRGenerator)
            _buildGenerateQRButton(),

          // QR Generator Widget
          if (_showQRGenerator && _selectedCourse != null) ...[
            QRGeneratorWidget(
              courseId: _selectedCourse!['id'],
              courseTitle: _selectedCourse!['title'],
              onGenerated: () {
                _showSuccessSnackBar('QR generat cu succes pentru ${_selectedCourse!['title']}');
              },
            ),
            const SizedBox(height: 20),
          ],

          // Recent Attendance (if course selected)
          if (_selectedCourse != null && _recentAttendance.isNotEmpty)
            _buildRecentAttendanceCard(),
        ],
      ),
    );
  }

  Widget _buildCourseSelectionCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.school, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Selectează Cursul',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Map<String, dynamic>>(
              value: _selectedCourse,
              decoration: InputDecoration(
                labelText: 'Curs Activ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.class_),
              ),
              items: _courses.map((course) {
                return DropdownMenuItem<Map<String, dynamic>>(
                  value: course,
                  child: Text(
                    '${course['title'] ?? 'Curs fără nume'} - ${course['category'] ?? 'Fără categorie'}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: _onCourseSelected,
              validator: (value) {
                if (value == null) {
                  return 'Selectează un curs';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseStatsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Statistici Prezență',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Prezențe',
                    '${_attendanceStats['total_attendance'] ?? 0}',
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Participanți Unici',
                    '${_attendanceStats['unique_attendees'] ?? 0}',
                    Icons.person,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Azi',
                    '${_attendanceStats['recent_attendance'] ?? 0}',
                    Icons.today,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateQRButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _generateQRForCourse,
        icon: const Icon(Icons.qr_code, size: 24),
        label: const Text(
          'Generează QR pentru Prezență',
          style: TextStyle(fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentAttendanceCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.history, color: const Color(0xFF9C0033)),
                SizedBox(width: 8),
                Text(
                  'Prezențe Recente',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentAttendance.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final attendance = _recentAttendance[index];
                final user = attendance['user'];
                final checkInTime = DateTime.tryParse(attendance['check_in_time'] ?? '');
                
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.shade100,
                    child: Text(
                      user?['full_name']?.toString().substring(0, 1).toUpperCase() ?? '?',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    user?['full_name'] ?? 'Utilizator necunoscut',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    user?['email'] ?? 'Email necunoscut',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  trailing: Text(
                    checkInTime != null 
                        ? '${checkInTime.day.toString().padLeft(2, '0')}.${checkInTime.month.toString().padLeft(2, '0')} ${checkInTime.hour.toString().padLeft(2, '0')}:${checkInTime.minute.toString().padLeft(2, '0')}'
                        : 'Data necunoscută',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
