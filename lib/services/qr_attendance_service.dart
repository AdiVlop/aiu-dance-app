import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aiu_dance/utils/logger.dart';

class QRAttendanceService {
  static final _supabase = Supabase.instance.client;

  /// Generează payload-ul pentru QR code de prezență
  static Map<String, dynamic> generateAttendancePayload({
    required String courseId,
    String? additionalData,
  }) {
    return {
      'type': 'attendance',
      'course_id': courseId,
      'timestamp': DateTime.now().toIso8601String(),
      'version': '1.0',
      if (additionalData != null) 'data': additionalData,
    };
  }

  /// Convertește payload-ul în string pentru QR code
  static String payloadToQRString(Map<String, dynamic> payload) {
    return jsonEncode(payload);
  }

  /// Parsează string-ul QR și returnează payload-ul
  static Map<String, dynamic>? parseQRString(String qrData) {
    try {
      final decoded = jsonDecode(qrData) as Map<String, dynamic>;
      
      // Verifică că este un QR de prezență valid
      if (decoded['type'] == 'attendance' && 
          decoded['course_id'] != null && 
          decoded['course_id'].toString().isNotEmpty) {
        return decoded;
      }
      
      return null;
    } catch (e) {
      Logger.error('Error parsing QR string: $e');
      return null;
    }
  }

  /// Înregistrează prezența unui utilizator la un curs
  static Future<Map<String, dynamic>> recordAttendance({
    required String userId,
    required String courseId,
  }) async {
    try {
      Logger.info('Recording attendance for user $userId at course $courseId');

      // 1. Verifică dacă utilizatorul există
      final userCheck = await _supabase
          .from('profiles')
          .select('id, full_name')
          .eq('id', userId)
          .maybeSingle();

      if (userCheck == null) {
        return {
          'success': false,
          'message': 'Utilizator nu a fost găsit',
          'error_code': 'USER_NOT_FOUND'
        };
      }

      // 2. Verifică dacă cursul există și este activ
      final courseCheck = await _supabase
          .from('courses')
          .select('id, title, is_active')
          .eq('id', courseId)
          .maybeSingle();

      if (courseCheck == null) {
        return {
          'success': false,
          'message': 'Cursul nu a fost găsit',
          'error_code': 'COURSE_NOT_FOUND'
        };
      }

      if (courseCheck['is_active'] != true) {
        return {
          'success': false,
          'message': 'Cursul nu este activ',
          'error_code': 'COURSE_INACTIVE'
        };
      }

      // 3. Verifică dacă prezența nu a fost deja înregistrată (pentru ziua curentă)
      final todayDate = DateTime.now().toIso8601String().split('T')[0];
      final existingAttendance = await _supabase
          .from('attendance')
          .select('id')
          .eq('user_id', userId)
          .eq('course_id', courseId)
          .eq('session_date', todayDate)
          .maybeSingle();

      if (existingAttendance != null) {
        return {
          'success': false,
          'message': 'Prezența a fost deja înregistrată pentru acest curs',
          'error_code': 'ALREADY_RECORDED'
        };
      }

      // 4. Înregistrează prezența
      final attendanceData = {
        'user_id': userId,
        'course_id': courseId,
        'check_in_time': DateTime.now().toIso8601String(),
        'session_date': DateTime.now().toIso8601String().split('T')[0], // YYYY-MM-DD format
        'status': 'present',
      };

      await _supabase
          .from('attendance')
          .insert(attendanceData);

      Logger.info('Attendance recorded successfully');

      return {
        'success': true,
        'message': 'Prezența a fost înregistrată cu succes ✅',
        'data': {
          'user_name': userCheck['full_name'],
          'course_title': courseCheck['title'],
          'recorded_at': attendanceData['check_in_time'],
          'session_date': attendanceData['session_date'],
        }
      };

    } catch (e) {
      Logger.error('Error recording attendance: $e');
      return {
        'success': false,
        'message': 'Eroare la înregistrarea prezenței: ${e.toString()}',
        'error_code': 'DATABASE_ERROR'
      };
    }
  }

  /// Obține lista cursurilor active pentru care se pot genera QR-uri
  static Future<List<Map<String, dynamic>>> getActiveCourses() async {
    try {
      final response = await _supabase
          .from('courses')
          .select('''
            id,
            title,
            category,
            description,
            is_active,
            instructor:profiles!courses_instructor_id_fkey(full_name)
          ''')
          .eq('is_active', true)
          .order('title');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      Logger.error('Error loading active courses: $e');
      return [];
    }
  }

  /// Obține statisticile de prezență pentru un curs
  static Future<Map<String, dynamic>> getCourseAttendanceStats(String courseId) async {
    try {
      // Total prezențe pentru curs
      final attendanceCount = await _supabase
          .from('attendance')
          .select('id')
          .eq('course_id', courseId);

      // Utilizatori unici prezenți
      final uniqueAttendees = await _supabase
          .from('attendance')
          .select('user_id')
          .eq('course_id', courseId);

      final uniqueCount = uniqueAttendees
          .map((a) => a['user_id'])
          .toSet()
          .length;

      // Prezențe recent (ultimele 24h)
      final recentAttendance = await _supabase
          .from('attendance')
          .select('id')
          .eq('course_id', courseId)
          .eq('session_date', DateTime.now().toIso8601String().split('T')[0]);

      return {
        'total_attendance': attendanceCount.length,
        'unique_attendees': uniqueCount,
        'recent_attendance': recentAttendance.length,
      };
    } catch (e) {
      Logger.error('Error loading attendance stats: $e');
      return {
        'total_attendance': 0,
        'unique_attendees': 0,
        'recent_attendance': 0,
      };
    }
  }

  /// Obține lista de prezențe pentru un curs cu detalii utilizatori
  static Future<List<Map<String, dynamic>>> getCourseAttendanceList(String courseId) async {
    try {
      final response = await _supabase
          .from('attendance')
          .select('''
            id,
            check_in_time,
            session_date,
            status,
            user:profiles!attendance_user_id_fkey(
              id,
              full_name,
              email
            )
          ''')
          .eq('course_id', courseId)
          .order('check_in_time', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      Logger.error('Error loading course attendance list: $e');
      return [];
    }
  }

  /// Verifică dacă utilizatorul este înscris la curs
  static Future<bool> isUserEnrolledInCourse(String userId, String courseId) async {
    try {
      final enrollment = await _supabase
          .from('enrollments')
          .select('id')
          .eq('user_id', userId)
          .eq('course_id', courseId)
          .eq('status', 'active')
          .maybeSingle();

      return enrollment != null;
    } catch (e) {
      Logger.error('Error checking enrollment: $e');
      return false; // Default la false pentru siguranță
    }
  }

  /// Validează QR code și înregistrează prezența
  static Future<Map<String, dynamic>> processQRScan({
    required String qrData,
    required String userId,
  }) async {
    try {
      // 1. Parsează QR data
      final payload = parseQRString(qrData);
      if (payload == null) {
        return {
          'success': false,
          'message': 'Cod QR invalid sau format incorect',
          'error_code': 'INVALID_QR'
        };
      }

      // 2. Verifică tipul QR
      if (payload['type'] != 'attendance') {
        return {
          'success': false,
          'message': 'Acest QR nu este pentru prezență',
          'error_code': 'WRONG_QR_TYPE'
        };
      }

      final courseId = payload['course_id'].toString();

      // 3. Verifică dacă utilizatorul este înscris la curs (opțional)
      // final isEnrolled = await isUserEnrolledInCourse(userId, courseId);
      // if (!isEnrolled) {
      //   return {
      //     'success': false,
      //     'message': 'Nu ești înscris la acest curs',
      //     'error_code': 'NOT_ENROLLED'
      //   };
      // }

      // 4. Înregistrează prezența
      return await recordAttendance(
        userId: userId,
        courseId: courseId,
      );

    } catch (e) {
      Logger.error('Error processing QR scan: $e');
      return {
        'success': false,
        'message': 'Eroare la procesarea codului QR: ${e.toString()}',
        'error_code': 'PROCESSING_ERROR'
      };
    }
  }
}
