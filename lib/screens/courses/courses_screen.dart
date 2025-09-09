import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _enrolledCourses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCourses();
    _loadEnrolledCourses();
  }

  Future<void> _loadCourses() async {
    try {
      final response = await Supabase.instance.client
          .from('courses')
          .select('*')
          .order('start_time', ascending: true);

      setState(() {
        _courses = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print('Error loading courses: $e');
    }
  }

  Future<void> _loadEnrolledCourses() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('enrollments')
          .select('course_id')
          .eq('user_id', user.id);

      setState(() {
        _enrolledCourses = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print('Error loading enrolled courses: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _enrollInCourse(String courseId) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      await Supabase.instance.client.from('enrollments').insert({
        'user_id': user.id,
        'course_id': courseId,
        'enrolled_at': DateTime.now().toIso8601String(),
      });

      await _loadEnrolledCourses();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Te-ai înscris cu succes la curs!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare la înscriere: $e')),
        );
      }
    }
  }

  bool _isEnrolled(String courseId) {
    return _enrolledCourses.any((enrollment) => enrollment['course_id'] == courseId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cursurile Mele'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadCourses();
              _loadEnrolledCourses();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _courses.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.school, size: 100, color: Colors.grey),
                      SizedBox(height: 20),
                      Text(
                        'Nu există cursuri disponibile',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _courses.length,
                  itemBuilder: (context, index) {
                    final course = _courses[index];
                    final isEnrolled = _isEnrolled(course['id']);
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    course['title'] ?? 'Curs fără titlu',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (isEnrolled)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'Înscris',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (course['description'] != null)
                              Text(
                                course['description'],
                                style: const TextStyle(color: Colors.grey),
                              ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.category, size: 16, color: Colors.purple),
                                const SizedBox(width: 4),
                                Text(course['category'] ?? 'Fără categorie'),
                                const SizedBox(width: 16),
                                Icon(Icons.access_time, size: 16, color: Colors.purple),
                                const SizedBox(width: 4),
                                Text(_formatTime(course['start_time'])),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.people, size: 16, color: Colors.purple),
                                const SizedBox(width: 4),
                                Text('Capacitate: ${course['capacity'] ?? 'N/A'}'),
                                const SizedBox(width: 16),
                                Icon(Icons.euro, size: 16, color: Colors.purple),
                                const SizedBox(width: 4),
                                Text('${course['price'] ?? 0} RON'),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (!isEnrolled)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => _enrollInCourse(course['id']),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.purple,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Înscrie-te la curs'),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  String _formatTime(String? timeString) {
    if (timeString == null) return 'Ora necunoscută';
    try {
      final dateTime = DateTime.parse(timeString);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Ora necunoscută';
    }
  }
}
