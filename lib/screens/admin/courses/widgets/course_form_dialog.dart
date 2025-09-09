import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../services/courses_service.dart';
import '../../../../utils/logger.dart';

class CourseFormDialog extends StatefulWidget {
  final Map<String, dynamic>? course;
  final List<String> categories;
  final List<String> teachers;

  const CourseFormDialog({
    super.key,
    this.course,
    required this.categories,
    required this.teachers,
  });

  @override
  State<CourseFormDialog> createState() => _CourseFormDialogState();
}

class _CourseFormDialogState extends State<CourseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _capacityController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final CoursesService _coursesService = CoursesService();
  
  String _category = '';
  String _teacher = '';
  DateTime? _startDateTime;
  DateTime? _endDateTime;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    if (widget.course != null) {
      final course = widget.course!;
      _titleController.text = course['title'] ?? '';
      _descriptionController.text = course['description'] ?? '';
      _capacityController.text = (course['capacity'] ?? 20).toString();
      _locationController.text = course['location'] ?? 'Sala de dans AIU';
      _priceController.text = (course['price'] ?? 0.0).toString();
      _category = course['category'] ?? (widget.categories.isNotEmpty ? widget.categories.first : 'Bachata');
      _teacher = course['teacher'] ?? (widget.teachers.isNotEmpty ? widget.teachers.first : 'Instructor');
      
      if (course['start_time'] != null) {
        try {
          _startDateTime = DateTime.parse(course['start_time']);
        } catch (e) {
          Logger.error('Error parsing start time: $e');
        }
      }
      
      if (course['end_time'] != null) {
        try {
          _endDateTime = DateTime.parse(course['end_time']);
        } catch (e) {
          Logger.error('Error parsing end time: $e');
        }
      }
    } else {
      _locationController.text = 'Sala de dans AIU';
      _capacityController.text = '20';
      _priceController.text = '0';
      _category = widget.categories.isNotEmpty ? widget.categories.first : 'Bachata';
      _teacher = widget.teachers.isNotEmpty ? widget.teachers.first : 'Instructor';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _capacityController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime(bool isStartTime) async {
    final initialDate = isStartTime ? _startDateTime : _endDateTime;
    
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate ?? DateTime.now()),
      );

      if (time != null) {
        final dateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

        setState(() {
          if (isStartTime) {
            _startDateTime = dateTime;
            // Auto-set end time to 1 hour later if not set
            if (_endDateTime == null || _endDateTime!.isBefore(dateTime)) {
              _endDateTime = dateTime.add(const Duration(hours: 1));
            }
          } else {
            _endDateTime = dateTime;
          }
        });
      }
    }
  }

  Future<void> _saveCourse() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_startDateTime == null || _endDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selectează data și ora de început și sfârșit')),
      );
      return;
    }

    if (_endDateTime!.isBefore(_startDateTime!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ora de sfârșit trebuie să fie după ora de început')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final capacity = int.tryParse(_capacityController.text) ?? 20;
      final price = double.tryParse(_priceController.text) ?? 0.0;

      if (widget.course == null) {
        // Create new course
        final result = await _coursesService.createCourse(
          title: _titleController.text.trim(),
          category: _category,
          teacher: _teacher,
          capacity: capacity,
          startTime: _startDateTime!,
          endTime: _endDateTime!,
          location: _locationController.text.trim(),
          description: _descriptionController.text.trim().isEmpty 
              ? null 
              : _descriptionController.text.trim(),
          price: price == 0.0 ? null : price,
        );

        if (result != null) {
          if (mounted) {
            Navigator.pop(context, true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Curs creat cu succes!')),
            );
          }
        } else {
          throw Exception('Eroare la crearea cursului');
        }
      } else {
        // Update existing course
        final updates = <String, dynamic>{
          'title': _titleController.text.trim(),
          'category': _category,
          'teacher': _teacher,
          'capacity': capacity,
          'start_time': _startDateTime!.toIso8601String(),
          'end_time': _endDateTime!.toIso8601String(),
          'location': _locationController.text.trim(),
        };

        if (_descriptionController.text.trim().isNotEmpty) {
          updates['description'] = _descriptionController.text.trim();
        }

        if (price > 0.0) {
          updates['price'] = price;
        }

        final success = await _coursesService.updateCourse(
          widget.course!['id'],
          updates,
        );

        if (success) {
          if (mounted) {
            Navigator.pop(context, true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Curs actualizat cu succes!')),
            );
          }
        } else {
          throw Exception('Eroare la actualizarea cursului');
        }
      }
    } catch (e) {
      Logger.error('Error saving course: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.course != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.purple.shade600,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isEditing ? Icons.edit : Icons.add,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isEditing ? 'Editează Cursul' : 'Curs Nou',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Titlu *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.title),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Titlul este obligatoriu';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Category and Teacher row
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _category.isNotEmpty ? _category : null,
                              decoration: const InputDecoration(
                                labelText: 'Categorie *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.category),
                              ),
                              items: widget.categories.map((category) => 
                                DropdownMenuItem(
                                  value: category,
                                  child: Text(category),
                                )
                              ).toList(),
                              onChanged: (value) => setState(() => _category = value!),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Categoria este obligatorie';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _teacher.isNotEmpty ? _teacher : null,
                              decoration: const InputDecoration(
                                labelText: 'Instructor *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person),
                              ),
                              items: widget.teachers.map((teacher) => 
                                DropdownMenuItem(
                                  value: teacher,
                                  child: Text(teacher),
                                )
                              ).toList(),
                              onChanged: (value) => setState(() => _teacher = value!),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Instructorul este obligatoriu';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Capacity and Location row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _capacityController,
                              decoration: const InputDecoration(
                                labelText: 'Capacitate *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.people),
                                suffixText: 'persoane',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Capacitatea este obligatorie';
                                }
                                final capacity = int.tryParse(value);
                                if (capacity == null || capacity <= 0) {
                                  return 'Capacitatea trebuie să fie un număr pozitiv';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _locationController,
                              decoration: const InputDecoration(
                                labelText: 'Locația *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.location_on),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Locația este obligatorie';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Descriere (opțional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // Price
                      TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                          labelText: 'Preț (opțional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.euro),
                          suffixText: 'EUR',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            final price = double.tryParse(value);
                            if (price == null || price < 0) {
                              return 'Prețul trebuie să fie un număr pozitiv';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Date and Time selection
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.schedule),
                                  SizedBox(width: 8),
                                  Text(
                                    'Program',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              // Start time
                              ListTile(
                                leading: const Icon(Icons.play_arrow, color: Colors.green),
                                title: const Text('Ora de început'),
                                subtitle: Text(
                                  _startDateTime != null
                                      ? DateFormat('dd/MM/yyyy HH:mm').format(_startDateTime!)
                                      : 'Selectează data și ora',
                                ),
                                trailing: const Icon(Icons.calendar_today),
                                onTap: () => _selectDateTime(true),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(color: Colors.grey.shade300),
                                ),
                              ),
                              const SizedBox(height: 8),
                              
                              // End time
                              ListTile(
                                leading: const Icon(Icons.stop, color: Colors.red),
                                title: const Text('Ora de sfârșit'),
                                subtitle: Text(
                                  _endDateTime != null
                                      ? DateFormat('dd/MM/yyyy HH:mm').format(_endDateTime!)
                                      : 'Selectează data și ora',
                                ),
                                trailing: const Icon(Icons.calendar_today),
                                onTap: () => _selectDateTime(false),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(color: Colors.grey.shade300),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Anulează'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveCourse,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade600,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(isEditing ? 'Actualizează' : 'Creează'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}