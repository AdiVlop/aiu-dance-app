import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import '../../../utils/logger.dart';

class CourseDetailScreen extends StatefulWidget {
  const CourseDetailScreen({super.key});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  Map<String, dynamic>? course;
  bool _isEnrolled = false;
  bool _isInstructor = false;
  bool _isLoading = true;
  String? _attendanceQR;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        setState(() {
          course = args;
        });
        _loadCourseDetails();
      }
    });
  }

  Future<void> _loadCourseDetails() async {
    if (course == null) return;

    try {
      setState(() => _isLoading = true);
      
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // Check enrollment
      final enrollment = await Supabase.instance.client
          .from('enrollments')
          .select('*')
          .eq('user_id', userId)
          .eq('course_id', course!['id'])
          .eq('status', 'active')
          .maybeSingle();

      // Check if user is instructor/admin
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .single();

      setState(() {
        _isEnrolled = enrollment != null;
        _isInstructor = ['admin', 'instructor'].contains(profile['role']);
        _isLoading = false;
      });

      Logger.info('Course details loaded - Enrolled: $_isEnrolled, Instructor: $_isInstructor');
    } catch (e) {
      Logger.error('Error loading course details: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateAttendanceQR() async {
    if (course == null) return;

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // Generate QR payload
      final qrData = {
        'type': 'attendance',
        'course_id': course!['id'],
        'instructor_id': userId,
        'timestamp': DateTime.now().toIso8601String(),
        'valid_until': DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
      };

      // Save QR code to database
      final qrResponse = await Supabase.instance.client
          .from('qr_codes')
          .insert({
            'code': 'ATTENDANCE_${course!['id']}_${DateTime.now().millisecondsSinceEpoch}',
            'type': 'attendance',
            'title': 'Prezență ${course!['title']}',
            'data': qrData,
            'is_active': true,
            'expires_at': DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
            'created_by': userId,
            'course_id': course!['id'],
          })
          .select()
          .single();

      setState(() {
        _attendanceQR = jsonEncode(qrData);
      });

      _showSuccessSnackBar('QR code generat cu succes!');
      Logger.info('Attendance QR generated: ${qrResponse['id']}');
    } catch (e) {
      Logger.error('Error generating attendance QR: $e');
      _showErrorSnackBar('Eroare la generarea QR code-ului');
    }
  }

  Future<void> _scanAttendance() async {
    Navigator.pushNamed(context, '/scanner');
  }

  @override
  Widget build(BuildContext context) {
    if (course == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalii Curs')),
        body: const Center(child: Text('Curs nu a fost găsit')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(course!['title'] ?? 'Detalii Curs'),
        backgroundColor: const Color(0xFF9C0033),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Course Info Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course!['title'] ?? 'Fără titlu',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            course!['category'] ?? 'Categorie necunoscută',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (course!['description'] != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              course!['description'],
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                          const SizedBox(height: 16),
                          
                          // Course Details
                          _buildInfoRow('Instructor', course!['instructor'] ?? 'N/A'),
                          _buildInfoRow('Capacitate', '${course!['capacity'] ?? 'N/A'} persoane'),
                          _buildInfoRow('Preț', course!['price'] == null 
                              ? 'Gratuit' 
                              : '${course!['price']} RON'),
                          _buildInfoRow('Locație', course!['location'] ?? 'N/A'),
                          
                          if (course!['start_time'] != null && course!['end_time'] != null) ...[
                            _buildInfoRow('Program', 
                              '${_formatTime(course!['start_time'])} - ${_formatTime(course!['end_time'])}'),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Enrollment Status
                  if (_isEnrolled) ...[
                    Card(
                      color: Colors.green.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Ești înscris la acest curs',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Instructor Actions
                  if (_isInstructor) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Acțiuni Instructor',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _generateAttendanceQR,
                                icon: const Icon(Icons.qr_code),
                                label: const Text('Generează QR Prezență'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 8),
                            
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => Navigator.pushNamed(
                                  context, 
                                  '/admin/attendance',
                                  arguments: course!['id'],
                                ),
                                icon: const Icon(Icons.list),
                                label: const Text('Vezi Lista Prezență'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Student Actions
                  if (_isEnrolled && !_isInstructor) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Prezență',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _scanAttendance,
                                icon: const Icon(Icons.qr_code_scanner),
                                label: const Text('Scanează pentru Prezență'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // QR Code Display (for instructors)
                  if (_attendanceQR != null && _isInstructor) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text(
                              'QR Code pentru Prezență',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.3),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                              child: QrImageView(
                                data: _attendanceQR!,
                                version: QrVersions.auto,
                                size: 200.0,
                                backgroundColor: Colors.white,
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            const Text(
                              'Studenții pot scana acest cod pentru a-și marca prezența',
                              style: TextStyle(color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(timeStr);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timeStr;
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}
