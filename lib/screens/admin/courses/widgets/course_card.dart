import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class CourseCard extends StatefulWidget {
  final Map<String, dynamic> course;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CourseCard({
    super.key,
    required this.course,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<CourseCard> {
  bool _localeInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeLocale();
  }

  Future<void> _initializeLocale() async {
    try {
      await initializeDateFormatting('ro_RO', null);
      if (mounted) {
        setState(() {
          _localeInitialized = true;
        });
      }
    } catch (e) {
      // Fallback to default locale
      if (mounted) {
        setState(() {
          _localeInitialized = true;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    try {
      return DateFormat('EEEE, dd MMMM yyyy', 'ro_RO').format(date);
    } catch (e) {
      // Fallback to English format
      return DateFormat('EEEE, dd MMMM yyyy', 'en_US').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_localeInitialized) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    final title = widget.course['title'] ?? 'Fără titlu';
    final category = widget.course['category'] ?? 'Necunoscută';
    final teacher = widget.course['teacher'] ?? 'Necunoscut';
    final capacity = widget.course['capacity'] ?? 0;
    final location = widget.course['location'] ?? 'Sala de dans AIU';
    final startTimeStr = widget.course['start_time'] as String?;
    final endTimeStr = widget.course['end_time'] as String?;
    
    DateTime? startTime;
    DateTime? endTime;
    
    if (startTimeStr != null) {
      try {
        startTime = DateTime.parse(startTimeStr);
      } catch (e) {
        // Ignore parsing error
      }
    }
    
    if (endTimeStr != null) {
      try {
        endTime = DateTime.parse(endTimeStr);
      } catch (e) {
        // Ignore parsing error
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with category color
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getCategoryColor(category).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(category),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    category,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.people,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  '$capacity persoane',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // Course details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Teacher
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Instructor: $teacher',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Location
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Time schedule
                if (startTime != null && endTime != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: Colors.blue.shade600,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatDate(startTime),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              Text(
                                '${DateFormat('HH:mm').format(startTime)} - ${DateFormat('HH:mm').format(endTime)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getTimeStatusColor(startTime).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getTimeStatus(startTime),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: _getTimeStatusColor(startTime),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          color: Colors.orange.shade600,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Program de stabilit',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: widget.onEdit,
                  tooltip: 'Editează',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: widget.onDelete,
                  tooltip: 'Șterge',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'bachata':
        return Colors.red.shade600;
      case 'kizomba':
        return Colors.purple.shade600;
      case 'salsa':
        return Colors.orange.shade600;
      case 'tango':
        return Colors.indigo.shade600;
      case 'zouk':
        return Colors.teal.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  String _getTimeStatus(DateTime startTime) {
    final now = DateTime.now();
    final difference = startTime.difference(now);
    
    if (difference.isNegative) {
      return 'Trecut';
    } else if (difference.inDays == 0) {
      return 'Astăzi';
    } else if (difference.inDays == 1) {
      return 'Mâine';
    } else if (difference.inDays <= 7) {
      return 'Această săptămână';
    } else {
      return 'Viitor';
    }
  }

  Color _getTimeStatusColor(DateTime startTime) {
    final now = DateTime.now();
    final difference = startTime.difference(now);
    
    if (difference.isNegative) {
      return Colors.grey.shade600;
    } else if (difference.inDays == 0) {
      return Colors.red.shade600;
    } else if (difference.inDays == 1) {
      return Colors.orange.shade600;
    } else if (difference.inDays <= 7) {
      return Colors.blue.shade600;
    } else {
      return Colors.green.shade600;
    }
  }
}
