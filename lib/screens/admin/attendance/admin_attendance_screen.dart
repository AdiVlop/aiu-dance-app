import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aiu_dance/utils/logger.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:qr_flutter/qr_flutter.dart';

class AdminAttendanceScreen extends StatefulWidget {
  const AdminAttendanceScreen({super.key});

  @override
  State<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends State<AdminAttendanceScreen> {
  List<Map<String, dynamic>> _attendance = [];
  List<Map<String, dynamic>> _courses = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCourseId = '';
  DateTime _selectedDate = DateTime.now();
  String _selectedStatus = '';
  final TextEditingController _searchController = TextEditingController();
  String? _generatedQRCode;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      
      // Load courses
      final coursesResponse = await Supabase.instance.client
          .from('courses')
          .select('*')
          .eq('is_active', true)
          .order('title');

      // Load attendance with user and course info
      final attendanceResponse = await Supabase.instance.client
          .from('attendance')
          .select('''
            *,
            user:profiles!attendance_user_id_fkey(full_name, email),
            course:courses!attendance_course_id_fkey(title, category)
          ''')
          .order('created_at', ascending: false)
          .limit(100);

      setState(() {
        _courses = List<Map<String, dynamic>>.from(coursesResponse);
        _attendance = List<Map<String, dynamic>>.from(attendanceResponse);
        _isLoading = false;
      });
      
      Logger.info('Loaded ${_attendance.length} attendance records and ${_courses.length} courses');
    } catch (e) {
      Logger.error('Error loading attendance data: $e');
      setState(() => _isLoading = false);
      _showErrorSnackBar('Eroare la încărcarea datelor de prezență');
    }
  }

  List<Map<String, dynamic>> get _filteredAttendance {
    var filtered = _attendance;
    
    // Filter by course
    if (_selectedCourseId.isNotEmpty) {
      filtered = filtered.where((record) => record['course_id'] == _selectedCourseId).toList();
    }
    
    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((record) {
        final userName = record['user']?['full_name']?.toString().toLowerCase() ?? '';
        final userEmail = record['user']?['email']?.toString().toLowerCase() ?? '';
        final courseName = record['course']?['title']?.toString().toLowerCase() ?? '';
        final status = record['status']?.toString().toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();
        
        return userName.contains(query) || 
               userEmail.contains(query) || 
               courseName.contains(query) ||
               status.contains(query);
      }).toList();
    }
    
    return filtered;
  }

  Future<void> _showAttendanceDetails(Map<String, dynamic> record) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalii Prezență'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Utilizator:', record['user']?['full_name'] ?? 'N/A'),
              _buildDetailRow('Email:', record['user']?['email'] ?? 'N/A'),
              _buildDetailRow('Curs:', record['course']?['title'] ?? 'N/A'),
              _buildDetailRow('Categorie:', record['course']?['category'] ?? 'N/A'),
              _buildDetailRow('Status:', _getStatusText(record['status'])),
              _buildDetailRow('Note:', record['notes'] ?? 'N/A'),
              _buildDetailRow('Data înregistrării:', _formatDate(record['created_at'])),
              if (record['check_in_time'] != null)
                _buildDetailRow('Ora check-in:', _formatTime(record['check_in_time'])),
              if (record['check_out_time'] != null)
                _buildDetailRow('Ora check-out:', _formatTime(record['check_out_time'])),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Închide'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _editAttendance(record);
            },
            child: const Text('Editează'),
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
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(date.toString());
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatTime(dynamic time) {
    if (time == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(time.toString());
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'present':
        return 'Prezent';
      case 'absent':
        return 'Absent';
      case 'late':
        return 'Întârziat';
      case 'excused':
        return 'Scuzat';
      default:
        return status ?? 'N/A';
    }
  }

  Future<void> _editAttendance(Map<String, dynamic> record) async {
    final notesController = TextEditingController(text: record['notes'] ?? '');
    String selectedStatus = record['status'] ?? 'present';
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editează Prezența'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Utilizator: ${record['user']?['full_name'] ?? 'N/A'}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Curs: ${record['course']?['title'] ?? 'N/A'}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status Prezență',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'present', child: Text('Prezent')),
                  DropdownMenuItem(value: 'absent', child: Text('Absent')),
                  DropdownMenuItem(value: 'late', child: Text('Întârziat')),
                  DropdownMenuItem(value: 'excused', child: Text('Scuzat')),
                ],
                onChanged: (value) {
                  selectedStatus = value!;
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Note',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anulează'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await Supabase.instance.client
                    .from('attendance')
                    .update({
                      'status': selectedStatus,
                      'notes': notesController.text,
                      'updated_at': DateTime.now().toIso8601String(),
                    })
                    .eq('id', record['id']);

                _showSuccessSnackBar('Prezența a fost actualizată');
                Navigator.pop(context);
                await _loadData();
              } catch (e) {
                Logger.error('Error updating attendance: $e');
                _showErrorSnackBar('Eroare la actualizarea prezenței');
              }
            },
            child: const Text('Salvează'),
          ),
        ],
      ),
    );
  }

  Future<void> _addAttendance() async {
    String selectedUserId = '';
    String selectedCourseId = '';
    String selectedStatus = 'present';
    final notesController = TextEditingController();

    // Load users for selection
    final usersResponse = await Supabase.instance.client
        .from('profiles')
        .select('*')
        .order('full_name');
    
    final users = List<Map<String, dynamic>>.from(usersResponse);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adaugă Prezență'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedUserId.isNotEmpty ? selectedUserId : null,
                decoration: const InputDecoration(
                  labelText: 'Utilizator',
                  border: OutlineInputBorder(),
                ),
                items: users.map<DropdownMenuItem<String>>((user) => 
                  DropdownMenuItem<String>(
                    value: user['id'],
                    child: Text('${user['full_name']} (${user['email']})'),
                  ),
                ).toList(),
                onChanged: (value) {
                  selectedUserId = value!;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedCourseId.isNotEmpty ? selectedCourseId : null,
                decoration: const InputDecoration(
                  labelText: 'Curs',
                  border: OutlineInputBorder(),
                ),
                items: _courses.map<DropdownMenuItem<String>>((course) => 
                  DropdownMenuItem<String>(
                    value: course['id'],
                    child: Text('${course['title']} (${course['category']})'),
                  ),
                ).toList(),
                onChanged: (value) {
                  selectedCourseId = value!;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status Prezență',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'present', child: Text('Prezent')),
                  DropdownMenuItem(value: 'absent', child: Text('Absent')),
                  DropdownMenuItem(value: 'late', child: Text('Întârziat')),
                  DropdownMenuItem(value: 'excused', child: Text('Scuzat')),
                ],
                onChanged: (value) {
                  selectedStatus = value!;
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Note',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anulează'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (selectedUserId.isEmpty || selectedCourseId.isEmpty) {
                _showErrorSnackBar('Selectează utilizatorul și cursul');
                return;
              }

              try {
                await Supabase.instance.client
                    .from('attendance')
                    .insert({
                      'user_id': selectedUserId,
                      'course_id': selectedCourseId,
                      'status': selectedStatus,
                      'notes': notesController.text,
                      'created_at': DateTime.now().toIso8601String(),
                      'updated_at': DateTime.now().toIso8601String(),
                    });

                _showSuccessSnackBar('Prezența a fost înregistrată');
                Navigator.pop(context);
                await _loadData();
              } catch (e) {
                Logger.error('Error creating attendance: $e');
                _showErrorSnackBar('Eroare la înregistrarea prezenței');
              }
            },
            child: const Text('Adaugă'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAttendance(Map<String, dynamic> record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Șterge Prezența'),
        content: Text('Ești sigur că vrei să ștergi această înregistrare de prezență?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anulează'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Șterge'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await Supabase.instance.client
            .from('attendance')
            .delete()
            .eq('id', record['id']);

        _showSuccessSnackBar('Prezența a fost ștearsă');
        await _loadData();
      } catch (e) {
        Logger.error('Error deleting attendance: $e');
        _showErrorSnackBar('Eroare la ștergerea prezenței');
      }
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'late':
        return Colors.orange;
      case 'excused':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'present':
        return Icons.check_circle;
      case 'absent':
        return Icons.cancel;
      case 'late':
        return Icons.schedule;
      case 'excused':
        return Icons.info;
      default:
        return Icons.help_outline;
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

  Future<void> _generateAttendanceQR(String courseId) async {
    try {
      final course = _courses.firstWhere((c) => c['id'] == courseId);
      final userId = Supabase.instance.client.auth.currentUser?.id;
      
      if (userId == null) return;

      // Generate QR payload
      final qrData = {
        'type': 'attendance',
        'course_id': courseId,
        'course_title': course['title'],
        'instructor_id': userId,
        'timestamp': DateTime.now().toIso8601String(),
        'valid_until': DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
      };

      // Save QR code to database
      await Supabase.instance.client
          .from('qr_codes')
          .insert({
            'code': 'ATTENDANCE_${courseId}_${DateTime.now().millisecondsSinceEpoch}',
            'type': 'attendance',
            'title': 'Prezență ${course['title']}',
            'data': qrData,
            'is_active': true,
            'expires_at': DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
            'created_by': userId,
            'course_id': courseId,
          });

      setState(() {
        _generatedQRCode = jsonEncode(qrData);
      });

      _showQRDialog(course['title']);
      Logger.info('QR code generated for course: $courseId');
    } catch (e) {
      Logger.error('Error generating QR code: $e');
      _showErrorSnackBar('Eroare la generarea QR code-ului');
    }
  }

  void _showQRDialog(String courseTitle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('QR Code - $courseTitle'),
        content: SizedBox(
          width: 300,
          height: 350,
          child: Column(
            children: [
              if (_generatedQRCode != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: QrImageView(
                    data: _generatedQRCode!,
                    version: QrVersions.auto,
                    size: 200.0,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Studenții pot scana acest cod pentru prezență',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  'Valabil până la: ${DateFormat('HH:mm dd/MM/yyyy').format(DateTime.now().add(const Duration(hours: 2)))}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
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

  Future<void> _exportAttendanceReport() async {
    try {
      // Get filtered attendance data
      final filteredAttendance = _getFilteredAttendance();
      
      if (filteredAttendance.isEmpty) {
        _showErrorSnackBar('Nu există date pentru export');
        return;
      }

      // Generate CSV-like report
      String report = 'Raport Prezență AIU Dance\n';
      report += 'Generat: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}\n\n';
      
      if (_selectedCourseId.isNotEmpty) {
        final course = _courses.firstWhere((c) => c['id'] == _selectedCourseId);
        report += 'Curs: ${course['title']}\n';
      }
      
      report += 'Data: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}\n\n';
      report += 'Nume,Email,Status,Ora Check-in,Note\n';

      for (final attendance in filteredAttendance) {
        final user = attendance['user'] ?? {};
        report += '${user['full_name'] ?? 'N/A'},';
        report += '${user['email'] ?? 'N/A'},';
        report += '${attendance['status'] ?? 'N/A'},';
        report += '${attendance['check_in_time'] != null ? DateFormat('HH:mm').format(DateTime.parse(attendance['check_in_time'])) : 'N/A'},';
        report += '${attendance['notes'] ?? ''}\n';
      }

      // Show report in dialog (în producție, ar trebui salvat ca fișier)
      _showReportDialog(report);
      
    } catch (e) {
      Logger.error('Error exporting report: $e');
      _showErrorSnackBar('Eroare la exportul raportului');
    }
  }

  void _showReportDialog(String report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Raport Prezență'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Text(
              report,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Închide'),
          ),
          ElevatedButton(
            onPressed: () {
              // În producție: salvează fișierul
              Navigator.pop(context);
              _showSuccessSnackBar('Raport generat cu succes!');
            },
            child: const Text('Salvează'),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredAttendance() {
    return _attendance.where((attendance) {
      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final user = attendance['user'] ?? {};
        final name = (user['full_name'] ?? '').toLowerCase();
        final email = (user['email'] ?? '').toLowerCase();
        if (!name.contains(_searchQuery.toLowerCase()) && 
            !email.contains(_searchQuery.toLowerCase())) {
          return false;
        }
      }

      // Filter by course
      if (_selectedCourseId.isNotEmpty && attendance['course_id'] != _selectedCourseId) {
        return false;
      }

      // Filter by status
      if (_selectedStatus.isNotEmpty && attendance['status'] != _selectedStatus) {
        return false;
      }

      // Filter by date
      if (attendance['session_date'] != null) {
        final sessionDate = DateTime.parse(attendance['session_date']);
        final selectedDateOnly = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
        final sessionDateOnly = DateTime(sessionDate.year, sessionDate.month, sessionDate.day);
        if (!sessionDateOnly.isAtSameMomentAs(selectedDateOnly)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadData();
    }
  }


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Icon(Icons.how_to_reg, size: 28, color: Colors.purple),
                const SizedBox(width: 12),
                const Text(
                  'Gestionare Prezență',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 20),
              // QR Code Generation
              if (_selectedCourseId.isNotEmpty) ...[
                ElevatedButton.icon(
                  onPressed: () => _generateAttendanceQR(_selectedCourseId),
                  icon: const Icon(Icons.qr_code),
                  label: const Text('Generează QR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              // Export Report
              ElevatedButton.icon(
                onPressed: _exportAttendanceReport,
                icon: const Icon(Icons.file_download),
                label: const Text('Export'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _addAttendance,
                icon: const Icon(Icons.add),
                label: const Text('Adaugă'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Actualizează'),
              ),
            ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Filters
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Caută prezența...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            icon: const Icon(Icons.clear),
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedCourseId.isNotEmpty ? _selectedCourseId : null,
                  decoration: InputDecoration(
                    labelText: 'Filtrează după curs',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: '',
                      child: Text('Toate cursurile'),
                    ),
                    ..._courses.map<DropdownMenuItem<String>>((course) => 
                      DropdownMenuItem<String>(
                        value: course['id'],
                        child: Text(course['title'] ?? 'N/A'),
                      ),
                    ).toList(),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedCourseId = value ?? '');
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Additional Filters Row
          Row(
            children: [
              // Date Filter
              Expanded(
                child: InkWell(
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          'Data: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Status Filter
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus.isNotEmpty ? _selectedStatus : null,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem<String>(
                      value: '',
                      child: Text('Toate statusurile'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'present',
                      child: Text('Prezent'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'absent',
                      child: Text('Absent'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'late',
                      child: Text('Întârziat'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'excused',
                      child: Text('Scuzat'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedStatus = value ?? '');
                  },
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Clear Filters Button
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedCourseId = '';
                    _selectedStatus = '';
                    _selectedDate = DateTime.now();
                    _searchController.clear();
                    _searchQuery = '';
                  });
                  _loadData();
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('Resetează'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Attendance List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _getFilteredAttendance().isEmpty
                    ? const Center(
                        child: Text(
                          'Nu s-au găsit înregistrări de prezență',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _getFilteredAttendance().length,
                        itemBuilder: (context, index) {
                          final filteredAttendance = _getFilteredAttendance();
                          final record = filteredAttendance[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getStatusColor(record['status']).withOpacity(0.1),
                                child: Icon(
                                  _getStatusIcon(record['status']),
                                  color: _getStatusColor(record['status']),
                                ),
                              ),
                              title: Text(
                                record['user']?['full_name'] ?? 'N/A',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(record['course']?['title'] ?? 'N/A'),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(record['status']).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          _getStatusText(record['status']),
                                          style: TextStyle(
                                            color: _getStatusColor(record['status']),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _formatDate(record['created_at']),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton(
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'view',
                                    child: Row(
                                      children: [
                                        Icon(Icons.visibility),
                                        SizedBox(width: 8),
                                        Text('Vezi detalii'),
                                      ],
                                    ),
                                  ),
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
                                onSelected: (value) {
                                  switch (value) {
                                    case 'view':
                                      _showAttendanceDetails(record);
                                      break;
                                    case 'edit':
                                      _editAttendance(record);
                                      break;
                                    case 'delete':
                                      _deleteAttendance(record);
                                      break;
                                  }
                                },
                              ),
                              onTap: () => _showAttendanceDetails(record),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}