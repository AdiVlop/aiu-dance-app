import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentsEnrolledScreen extends StatefulWidget {
  const StudentsEnrolledScreen({super.key});

  @override
  State<StudentsEnrolledScreen> createState() => _StudentsEnrolledScreenState();
}

class _StudentsEnrolledScreenState extends State<StudentsEnrolledScreen> {
  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _enrolledStudents = [];
  String? _selectedCourseId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInstructorCourses();
  }

  Future<void> _loadInstructorCourses() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('courses')
          .select('*')
          .eq('instructor_id', user.id)
          .order('start_time', ascending: true);

      setState(() {
        _courses = List<Map<String, dynamic>>.from(response);
        if (_courses.isNotEmpty) {
          _selectedCourseId = _courses.first['id'];
          _loadEnrolledStudents(_courses.first['id']);
        }
      });
    } catch (e) {
      print('Error loading courses: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadEnrolledStudents(String courseId) async {
    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client
          .from('enrollments')
          .select('''
            id,
            enrolled_at,
            user_id,
            profiles!inner(
              id,
              full_name,
              email,
              phone
            )
          ''')
          .eq('course_id', courseId)
          .order('enrolled_at', ascending: false);

      setState(() {
        _enrolledStudents = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print('Error loading enrolled students: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Studenți Înscriși'),
        backgroundColor: const Color(0xFF9C0033),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadInstructorCourses();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Selector cursuri
          if (_courses.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              child: DropdownButtonFormField<String>(
                value: _selectedCourseId,
                decoration: const InputDecoration(
                  labelText: 'Selectează cursul',
                  border: OutlineInputBorder(),
                ),
                items: _courses.map((course) {
                  return DropdownMenuItem<String>(
                    value: course['id'],
                    child: Text(course['title'] ?? 'Curs fără titlu'),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedCourseId = newValue;
                    });
                    _loadEnrolledStudents(newValue);
                  }
                },
              ),
            ),
          
          // Lista studenți
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _enrolledStudents.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 100, color: Colors.grey),
                            SizedBox(height: 20),
                            Text(
                              'Nu există studenți înscriși',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _enrolledStudents.length,
                        itemBuilder: (context, index) {
                          final enrollment = _enrolledStudents[index];
                          final profile = enrollment['profiles'] as Map<String, dynamic>;
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF9C0033),
                                child: Text(
                                  profile['full_name']?.substring(0, 1).toUpperCase() ?? '?',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                profile['full_name'] ?? 'Nume necunoscut',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(profile['email'] ?? 'Email necunoscut'),
                                  if (profile['phone'] != null)
                                    Text(profile['phone']),
                                  Text(
                                    'Înscris: ${_formatDate(enrollment['enrolled_at'])}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.visibility),
                                onPressed: () {
                                  _showStudentDetails(profile, enrollment);
                                },
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

  void _showStudentDetails(Map<String, dynamic> profile, Map<String, dynamic> enrollment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(profile['full_name'] ?? 'Detalii student'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Email', profile['email']),
            _buildDetailRow('Telefon', profile['phone'] ?? 'Nu este specificat'),
            _buildDetailRow('Data înscrierii', _formatDate(enrollment['enrolled_at'])),
            const SizedBox(height: 16),
            const Text(
              'Statistici curs:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            FutureBuilder(
              future: _getStudentStats(profile['id']),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (snapshot.hasData) {
                  final stats = snapshot.data as Map<String, dynamic>;
                  return Column(
                    children: [
                      _buildDetailRow('Prezențe', '${stats['attendance_count']}'),
                      _buildDetailRow('Ultima prezență', stats['last_attendance'] ?? 'Niciodată'),
                    ],
                  );
                }
                return const Text('Nu s-au putut încărca statisticile');
              },
            ),
          ],
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _getStudentStats(String userId) async {
    try {
      final attendanceResponse = await Supabase.instance.client
          .from('attendance')
          .select('scanned_at')
          .eq('user_id', userId)
          .eq('course_id', _selectedCourseId!)
          .order('scanned_at', ascending: false);

      final attendanceCount = attendanceResponse.length;
      final lastAttendance = attendanceResponse.isNotEmpty
          ? _formatDate(attendanceResponse.first['scanned_at'])
          : null;

      return {
        'attendance_count': attendanceCount,
        'last_attendance': lastAttendance,
      };
    } catch (e) {
      return {
        'attendance_count': 0,
        'last_attendance': 'Eroare la încărcare',
      };
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Data necunoscută';
    try {
      final dateTime = DateTime.parse(dateString);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Data necunoscută';
    }
  }
}
