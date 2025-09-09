import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
// import 'package:image_picker/image_picker.dart'; // Temporar dezactivat pentru APK minimal
import 'package:supabase_flutter/supabase_flutter.dart';
// import '../../../../services/announcement_service.dart'; // Fișier șters temporar
import '../../../../utils/logger.dart';

class AnnouncementFormDialog extends StatefulWidget {
  final Map<String, dynamic>? announcement;
  final List<Map<String, dynamic>> courses;

  const AnnouncementFormDialog({
    super.key,
    this.announcement,
    required this.courses,
  });

  @override
  State<AnnouncementFormDialog> createState() => _AnnouncementFormDialogState();
}

class _AnnouncementFormDialogState extends State<AnnouncementFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  
  String _visibleTo = 'all';
  String? _selectedCourseId;
  File? _selectedMedia;
  String? _mediaType;
  DateTime? _scheduledAt;
  bool _isPublished = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.announcement != null) {
      _titleController.text = widget.announcement!['title'] ?? '';
      _contentController.text = widget.announcement!['content'] ?? '';
      _visibleTo = widget.announcement!['visible_to'] ?? 'all';
      _selectedCourseId = widget.announcement!['course_id'];
      _isPublished = widget.announcement!['is_published'] ?? true;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Widget _buildMediaPreview() {
    // Media preview functionality temporarily disabled for APK optimization
    return const SizedBox.shrink();
  }

  Future<void> _pickMedia() async {
    // Media picker functionality temporarily disabled for APK optimization
    return;
  }

  Future<void> _pickScheduledDate() async {
    // Date picker functionality temporarily disabled for APK optimization
    return;
  }

  Future<void> _saveAnnouncement() async {
    // Save functionality temporarily disabled for APK optimization
    return;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.announcement != null;

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              isEditing ? 'Editează Anunț' : 'Anunț Nou',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Titlu',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Titlul este obligatoriu';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Content
                      TextFormField(
                        controller: _contentController,
                        decoration: const InputDecoration(
                          labelText: 'Conținut',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Conținutul este obligatoriu';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Visibility
                      DropdownButtonFormField<String>(
                        value: _visibleTo,
                        decoration: const InputDecoration(
                          labelText: 'Vizibil pentru',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('Toți')),
                          DropdownMenuItem(value: 'students', child: Text('Studenți')),
                          DropdownMenuItem(value: 'instructors', child: Text('Instructori')),
                          DropdownMenuItem(value: 'admins', child: Text('Administratori')),
                        ],
                        onChanged: (value) => setState(() => _visibleTo = value!),
                      ),
                      const SizedBox(height: 16),

                      // Course selection (if visible to specific course)
                      if (_visibleTo == 'course')
                        DropdownButtonFormField<String>(
                          value: _selectedCourseId,
                          decoration: const InputDecoration(
                            labelText: 'Curs',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Selectează cursul')),
                            ...widget.courses.map((course) => DropdownMenuItem<String>(
                              value: course['id'],
                              child: Text(course['name'] ?? 'Curs fără nume'),
                            )),
                          ],
                          onChanged: (value) => setState(() => _selectedCourseId = value),
                        ),
                      const SizedBox(height: 16),

                      // Published status
                      SwitchListTile(
                        title: const Text('Publicat'),
                        subtitle: const Text('Anunțul va fi vizibil pentru utilizatori'),
                        value: _isPublished,
                        onChanged: (value) => setState(() => _isPublished = value),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Anulează'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveAnnouncement,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isEditing ? 'Actualizează' : 'Salvează'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}