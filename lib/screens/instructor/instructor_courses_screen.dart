import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InstructorCoursesScreen extends StatefulWidget {
  const InstructorCoursesScreen({super.key});

  @override
  State<InstructorCoursesScreen> createState() => _InstructorCoursesScreenState();
}

class _InstructorCoursesScreenState extends State<InstructorCoursesScreen> {
  List<Map<String, dynamic>> _courses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
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
      });
    } catch (e) {
      print('Error loading courses: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteCourse(String courseId) async {
    try {
      await Supabase.instance.client
          .from('courses')
          .delete()
          .eq('id', courseId);

      await _loadCourses();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Curs șters cu succes')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare la ștergere: $e')),
        );
      }
    }
  }

  void _showDeleteDialog(String courseId, String courseTitle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Șterge curs'),
        content: Text('Sigur doriți să ștergeți cursul "$courseTitle"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anulează'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteCourse(courseId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Șterge'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> course) {
    final titleController = TextEditingController(text: course['title'] ?? '');
    final descriptionController = TextEditingController(text: course['description'] ?? '');
    final categoryController = TextEditingController(text: course['category'] ?? '');
    final capacityController = TextEditingController(text: course['capacity']?.toString() ?? '');
    final priceController = TextEditingController(text: course['price']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editează curs'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Titlu'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Descriere'),
                maxLines: 3,
              ),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: 'Categorie'),
              ),
              TextField(
                controller: capacityController,
                decoration: const InputDecoration(labelText: 'Capacitate'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Preț (RON)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anulează'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await Supabase.instance.client
                    .from('courses')
                    .update({
                      'title': titleController.text,
                      'description': descriptionController.text,
                      'category': categoryController.text,
                      'capacity': int.tryParse(capacityController.text),
                      'price': double.tryParse(priceController.text),
                    })
                    .eq('id', course['id']);

                await _loadCourses();
                Navigator.pop(context);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Curs actualizat cu succes')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Eroare la actualizare: $e')),
                  );
                }
              }
            },
            child: const Text('Salvează'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cursurile Mele'),
        backgroundColor: const Color(0xFF9C0033),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.pushNamed(context, '/instructor/courses/create');
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCourses,
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
                        'Nu aveți cursuri create',
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
                                PopupMenuButton<String>(
                                  onSelected: (value) {
                                    switch (value) {
                                      case 'edit':
                                        _showEditDialog(course);
                                        break;
                                      case 'delete':
                                        _showDeleteDialog(
                                          course['id'],
                                          course['title'] ?? 'Curs fără titlu',
                                        );
                                        break;
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit),
                                          SizedBox(width: 8),
                                          Text('Editează'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Șterge', style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ],
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
                                Icon(Icons.category, size: 16, color: const Color(0xFF9C0033)),
                                const SizedBox(width: 4),
                                Text(course['category'] ?? 'Fără categorie'),
                                const SizedBox(width: 16),
                                Icon(Icons.access_time, size: 16, color: const Color(0xFF9C0033)),
                                const SizedBox(width: 4),
                                Text(_formatTime(course['start_time'])),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.people, size: 16, color: const Color(0xFF9C0033)),
                                const SizedBox(width: 4),
                                Text('Capacitate: ${course['capacity'] ?? 'N/A'}'),
                                const SizedBox(width: 16),
                                Icon(Icons.euro, size: 16, color: const Color(0xFF9C0033)),
                                const SizedBox(width: 4),
                                Text('${course['price'] ?? 0} RON'),
                              ],
                            ),
                            const SizedBox(height: 12),
                            FutureBuilder(
                              future: _getEnrollmentCount(course['id']),
                              builder: (context, snapshot) {
                                final enrollmentCount = snapshot.data ?? 0;
                                return Row(
                                  children: [
                                    Icon(Icons.person_add, size: 16, color: Colors.green),
                                    const SizedBox(width: 4),
                                    Text('Studenți înscriși: $enrollmentCount'),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Future<int> _getEnrollmentCount(String courseId) async {
    try {
      final response = await Supabase.instance.client
          .from('enrollments')
          .select('id')
          .eq('course_id', courseId);

      return response.length;
    } catch (e) {
      return 0;
    }
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
