import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/supabase_service.dart';
import '../../../utils/logger.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class AttendanceOverviewScreen extends StatefulWidget {
  const AttendanceOverviewScreen({super.key});

  @override
  State<AttendanceOverviewScreen> createState() => _AttendanceOverviewScreenState();
}

class _AttendanceOverviewScreenState extends State<AttendanceOverviewScreen> {
  final _supabaseService = SupabaseService();
  
  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _attendance = [];
  Map<String, dynamic>? _selectedCourse;
  DateTime? _selectedDate;
  bool _isLoading = false;
  
  // Statistics
  int _totalEnrolled = 0;
  int _totalPresent = 0;
  int _totalAbsent = 0;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await Supabase.instance.client
          .from('courses')
          .select()
          .order('start_time', ascending: true);

      setState(() {
        _courses = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      Logger.error('Error loading courses', e);
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAttendance() async {
    if (_selectedCourse == null || _selectedDate == null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final courseId = _selectedCourse!['id'];
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);

      // Get enrollments for the course
      final enrollmentsResponse = await Supabase.instance.client
          .from('enrollments')
          .select('user_id, profiles(full_name, email)')
          .eq('course_id', courseId)
          .eq('status', 'active');

      // Get attendance for the specific date
      final attendanceResponse = await Supabase.instance.client
          .from('attendance')
          .select('user_id, check_in_time')
          .eq('course_id', courseId)
          .eq('date', dateStr);

      final enrollments = List<Map<String, dynamic>>.from(enrollmentsResponse);
      final attendance = List<Map<String, dynamic>>.from(attendanceResponse);

      // Create attendance list
      final attendanceList = enrollments.map((enrollment) {
        final userId = enrollment['user_id'];
        final userAttendance = attendance.firstWhere(
          (a) => a['user_id'] == userId,
          orElse: () => {'user_id': userId, 'check_in_time': null},
        );

        return {
          'user_id': userId,
          'full_name': enrollment['profiles']?['full_name'] ?? 'Unknown',
          'email': enrollment['profiles']?['email'] ?? 'Unknown',
          'is_present': userAttendance['check_in_time'] != null,
          'check_in_time': userAttendance['check_in_time'],
        };
      }).toList();

      setState(() {
        _attendance = attendanceList;
        _totalEnrolled = enrollments.length;
        _totalPresent = attendanceList.where((a) => a['is_present']).length;
        _totalAbsent = _totalEnrolled - _totalPresent;
        _isLoading = false;
      });
    } catch (e) {
      Logger.error('Error loading attendance', e);
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _exportToPDF() async {
    if (_selectedCourse == null || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selectează un curs și o dată înainte de export!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Header(
                  level: 0,
                  child: pw.Text(
                    'Raport Prezență - AIU Dance',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),

                // Course and Date Info
                pw.Row(
                  children: [
                    pw.Text(
                      'Curs: ',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(_selectedCourse!['name']),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Row(
                  children: [
                    pw.Text(
                      'Data: ',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(DateFormat('dd.MM.yyyy').format(_selectedDate!)),
                  ],
                ),
                pw.SizedBox(height: 20),

                // Statistics
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(),
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Statistici:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text('Total înscriși: $_totalEnrolled'),
                      pw.Text('Prezenți: $_totalPresent'),
                      pw.Text('Absenți: $_totalAbsent'),
                      pw.Text('Procent prezență: ${_totalEnrolled > 0 ? ((_totalPresent / _totalEnrolled) * 100).toStringAsFixed(1) : '0'}%'),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Attendance Table
                pw.Text(
                  'Lista Prezență:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 10),
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    // Header
                    pw.TableRow(
                      children: [
                        pw.Text('Nr.', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text('Nume', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text('Email', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text('Status', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text('Ora Check-in', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                    // Data rows
                    ..._attendance.asMap().entries.map((entry) {
                      final index = entry.key + 1;
                      final student = entry.value;
                      return pw.TableRow(
                        children: [
                          pw.Text(index.toString()),
                          pw.Text(student['full_name']),
                          pw.Text(student['email']),
                          pw.Text(
                            student['is_present'] ? 'Prezent' : 'Absent',
                            style: pw.TextStyle(
                              color: student['is_present'] ? PdfColors.green : PdfColors.red,
                            ),
                          ),
                          pw.Text(
                            student['check_in_time'] != null
                                ? DateFormat('HH:mm').format(DateTime.parse(student['check_in_time']))
                                : '-',
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
                pw.SizedBox(height: 20),

                // Footer
                pw.Text(
                  'Raport generat la: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey,
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Save PDF
      final bytes = await pdf.save();
      final tempDir = Directory.systemTemp;
      final file = File('${tempDir.path}/raport_prezenta_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf');
      await file.writeAsBytes(bytes);

      // Share PDF
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Raport Prezență - ${_selectedCourse!['name']}',
        text: 'Raport prezență pentru cursul ${_selectedCourse!['name']} din data ${DateFormat('dd.MM.yyyy').format(_selectedDate!)}',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Raport exportat cu succes!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Logger.error('Error exporting PDF', e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Eroare la export: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionare Prezență'),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportToPDF,
            tooltip: 'Export PDF',
          ),
        ],
      ),
      body: Column(
        children: [
          // Selection Controls
          _buildSelectionControls(),
          
          // Statistics Cards
          _buildStatisticsCards(),
          
          // Attendance List
          Expanded(
            child: _buildAttendanceList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<Map<String, dynamic>>(
                  decoration: const InputDecoration(
                    labelText: 'Selectează Cursul',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.school),
                  ),
                  value: _selectedCourse,
                  items: _courses.map((course) {
                    return DropdownMenuItem(
                      value: course,
                      child: Text(course['name']),
                    );
                  }).toList(),
                  onChanged: (course) {
                    setState(() {
                      _selectedCourse = course;
                      _attendance = [];
                      _totalEnrolled = 0;
                      _totalPresent = 0;
                      _totalAbsent = 0;
                    });
                    if (course != null) {
                      _loadAttendance();
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        _selectedDate = date;
                      });
                      if (_selectedCourse != null) {
                        _loadAttendance();
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today),
                        const SizedBox(width: 8),
                        Text(
                          _selectedDate != null
                              ? DateFormat('dd.MM.yyyy').format(_selectedDate!)
                              : 'Selectează data',
                          style: TextStyle(
                            color: _selectedDate != null ? Colors.black : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _selectedCourse != null && _selectedDate != null
                  ? _loadAttendance
                  : null,
              icon: const Icon(Icons.refresh),
              label: const Text('Încarcă Prezența'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Înscriși',
              _totalEnrolled.toString(),
              Icons.people,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Prezenți',
              _totalPresent.toString(),
              Icons.check_circle,
              Colors.green,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Absenți',
              _totalAbsent.toString(),
              Icons.cancel,
              Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
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
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceList() {
    if (_selectedCourse == null) {
      return _buildEmptyState(
        'Selectează un curs pentru a vedea prezența',
        Icons.school,
      );
    }

    if (_selectedDate == null) {
      return _buildEmptyState(
        'Selectează o dată pentru a vedea prezența',
        Icons.calendar_today,
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_attendance.isEmpty) {
      return _buildEmptyState(
        'Nu există înscrieri pentru acest curs',
        Icons.people_outline,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _attendance.length,
      itemBuilder: (context, index) {
        final student = _attendance[index];
        final isPresent = student['is_present'] as bool;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isPresent ? Colors.green.shade100 : Colors.red.shade100,
              child: Icon(
                isPresent ? Icons.check_circle : Icons.cancel,
                color: isPresent ? Colors.green : Colors.red,
              ),
            ),
            title: Text(
              student['full_name'],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isPresent ? Colors.green.shade800 : Colors.red.shade800,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student['email']),
                if (isPresent && student['check_in_time'] != null)
                  Text(
                    'Check-in: ${DateFormat('HH:mm').format(DateTime.parse(student['check_in_time']))}',
                    style: TextStyle(
                      color: Colors.green.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isPresent ? Colors.green.shade100 : Colors.red.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isPresent ? Colors.green.shade300 : Colors.red.shade300,
                ),
              ),
              child: Text(
                isPresent ? 'Prezent' : 'Absent',
                style: TextStyle(
                  color: isPresent ? Colors.green.shade700 : Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}








