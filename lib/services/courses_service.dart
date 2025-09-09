import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';

class CoursesService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all courses
  Future<List<Map<String, dynamic>>> getCourses() async {
    try {
      final response = await _supabase
          .from('courses')
          .select('*')
          .order('start_time', ascending: true);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      Logger.error('Error fetching courses: $e');
      return [];
    }
  }

  // Get courses by category
  Future<List<Map<String, dynamic>>> getCoursesByCategory(String category) async {
    try {
      final response = await _supabase
          .from('courses')
          .select('*')
          .eq('category', category)
          .order('start_time', ascending: true);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      Logger.error('Error fetching courses by category: $e');
      return [];
    }
  }

  // Get courses by teacher
  Future<List<Map<String, dynamic>>> getCoursesByTeacher(String teacher) async {
    try {
      final response = await _supabase
          .from('courses')
          .select('*')
          .eq('teacher', teacher)
          .order('start_time', ascending: true);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      Logger.error('Error fetching courses by teacher: $e');
      return [];
    }
  }

  // Create course
  Future<Map<String, dynamic>?> createCourse({
    required String title,
    required String category,
    required String teacher,
    required int capacity,
    required DateTime startTime,
    required DateTime endTime,
    String location = 'Sala de dans AIU',
    String? description,
    double? price,
  }) async {
    try {
      final response = await _supabase
          .from('courses')
          .insert({
            'title': title,
            'category': category,
            'teacher': teacher,
            'capacity': capacity,
            'start_time': startTime.toIso8601String(),
            'end_time': endTime.toIso8601String(),
            'location': location,
            'description': description,
            'price': price,
          })
          .select()
          .single();
      
      Logger.info('Course created successfully: ${response['id']}');
      return response;
    } catch (e) {
      Logger.error('Error creating course: $e');
      return null;
    }
  }

  // Update course
  Future<bool> updateCourse(String id, Map<String, dynamic> updates) async {
    try {
      await _supabase
          .from('courses')
          .update({
            ...updates,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
      
      Logger.info('Course updated successfully: $id');
      return true;
    } catch (e) {
      Logger.error('Error updating course: $e');
      return false;
    }
  }

  // Delete course
  Future<bool> deleteCourse(String id) async {
    try {
      await _supabase
          .from('courses')
          .delete()
          .eq('id', id);
      
      Logger.info('Course deleted successfully: $id');
      return true;
    } catch (e) {
      Logger.error('Error deleting course: $e');
      return false;
    }
  }

  // Get course statistics
  Future<Map<String, dynamic>> getCourseStats() async {
    try {
      final totalResponse = await _supabase
          .from('courses')
          .select('id');

      final categoriesResponse = await _supabase
          .from('courses')
          .select('category');

      // Count by category
      final categories = <String, int>{};
      for (final course in categoriesResponse) {
        final category = course['category'] as String? ?? 'Other';
        categories[category] = (categories[category] ?? 0) + 1;
      }

      // Get today's courses
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

      final todayCoursesResponse = await _supabase
          .from('courses')
          .select('id')
          .gte('start_time', startOfDay.toIso8601String())
          .lte('start_time', endOfDay.toIso8601String());

      // Get teachers
      final teachersResponse = await _supabase
          .from('courses')
          .select('teacher');

      final teachers = <String>{};
      for (final course in teachersResponse) {
        final teacher = course['teacher'] as String?;
        if (teacher != null && teacher.isNotEmpty) {
          teachers.add(teacher);
        }
      }

      return {
        'total': totalResponse.length,
        'today': todayCoursesResponse.length,
        'categories': categories,
        'totalTeachers': teachers.length,
        'teachers': teachers.toList(),
      };
    } catch (e) {
      Logger.error('Error getting course stats: $e');
      return {
        'total': 0,
        'today': 0,
        'categories': <String, int>{},
        'totalTeachers': 0,
        'teachers': <String>[],
      };
    }
  }

  // Get upcoming courses (next 7 days)
  Future<List<Map<String, dynamic>>> getUpcomingCourses() async {
    try {
      final now = DateTime.now();
      final nextWeek = now.add(const Duration(days: 7));

      final response = await _supabase
          .from('courses')
          .select('*')
          .gte('start_time', now.toIso8601String())
          .lte('start_time', nextWeek.toIso8601String())
          .order('start_time', ascending: true);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      Logger.error('Error fetching upcoming courses: $e');
      return [];
    }
  }

  // Get course categories
  Future<List<String>> getCourseCategories() async {
    try {
      final response = await _supabase
          .from('courses')
          .select('category')
          .order('category');

      final categories = <String>{};
      for (final course in response) {
        final category = course['category'] as String?;
        if (category != null && category.isNotEmpty) {
          categories.add(category);
        }
      }

      return categories.toList();
    } catch (e) {
      Logger.error('Error fetching course categories: $e');
      return ['Bachata', 'Kizomba', 'Salsa']; // Default categories
    }
  }

  // Get teachers
  Future<List<String>> getTeachers() async {
    try {
      final response = await _supabase
          .from('courses')
          .select('teacher')
          .order('teacher');

      final teachers = <String>{};
      for (final course in response) {
        final teacher = course['teacher'] as String?;
        if (teacher != null && teacher.isNotEmpty) {
          teachers.add(teacher);
        }
      }

      return teachers.toList();
    } catch (e) {
      Logger.error('Error fetching teachers: $e');
      return ['Raul', 'Emilia', 'Alina', 'Andrei', 'Nico', 'Dan']; // Default teachers
    }
  }
}
