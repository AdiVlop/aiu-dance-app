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
  // final AnnouncementService _announcementService = AnnouncementService(); // Temporar comentat
  
  String _visibleTo = 'all';
  String? _selectedCourseId;
  File? _selectedMedia;
  // XFile? _selectedWebMedia; // Pentru web - temporar dezactivat
  String? _mediaType;
  DateTime? _scheduledAt;
  bool _isLoading = false;
  bool _isPublished = true;

  @override
  void initState() {
    super.initState();
    if (widget.announcement != null) {
      _initializeFields();
    }
  }

  void _initializeFields() {
    final announcement = widget.announcement!;
    _titleController.text = announcement['title'] ?? '';
    _contentController.text = announcement['content'] ?? '';
    _visibleTo = announcement['visible_to'] ?? 'all';
    _selectedCourseId = announcement['course_id'];
    _mediaType = announcement['media_type'];
    _isPublished = announcement['is_published'] ?? true;
    
    if (announcement['scheduled_at'] != null) {
      try {
        _scheduledAt = DateTime.parse(announcement['scheduled_at']);
      } catch (e) {
        Logger.error('Error parsing scheduled date: $e');
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    // final picker = ImagePicker(); // Temporar dezactivat pentru APK minimal
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Upload imagini temporar dezactivat pentru optimizarea aplicației')),
    );
    return;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Selectează tipul media',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      final image = await picker.pickImage(source: ImageSource.gallery);
                      if (image != null) {
                        setState(() {
                          if (kIsWeb) {
                            _selectedWebMedia = image;
                            _selectedMedia = null;
                          } else {
                            _selectedMedia = File(image.path);
                            _selectedWebMedia = null;
                          }
                          _mediaType = 'image';
                        });
                      }
                    },
                    icon: const Icon(Icons.image),
                    label: const Text('Imagine'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      final video = await picker.pickVideo(source: ImageSource.gallery);
                      if (video != null) {
                        setState(() {
                          if (kIsWeb) {
                            _selectedWebMedia = video;
                            _selectedMedia = null;
                          } else {
                            _selectedMedia = File(video.path);
                            _selectedWebMedia = null;
                          }
                          _mediaType = 'video';
                        });
                      }
                    },
                    icon: const Icon(Icons.videocam),
                    label: const Text('Video'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _selectedMedia = null;
                  _mediaType = null;
                });
              },
              child: const Text('Elimină media'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickScheduledDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_scheduledAt ?? DateTime.now()),
      );

      if (time != null) {
        setState(() {
          _scheduledAt = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _saveAnnouncement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (widget.announcement == null) {
        // Create new announcement în Supabase
        final announcementData = {
          'title': _titleController.text.trim(),
          'content': _contentController.text.trim(),
          'visible_to': _visibleTo,
          'course_id': _selectedCourseId,
          'is_published': _isPublished,
          'media_url': null, // Media upload va fi implementat mai târziu
          'media_type': 'none',
          'created_at': DateTime.now().toIso8601String(),
        };

        if (_scheduledAt != null) {
          announcementData['scheduled_at'] = _scheduledAt!.toIso8601String();
        }

        final result = await Supabase.instance.client
            .from('announcements')
            .insert(announcementData)
            .select()
            .single();

        if (result != null) {
          if (mounted) {
            Navigator.pop(context, true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Anunț creat cu succes!')),
            );
          }
        } else {
          throw Exception('Eroare la crearea anunțului');
        }
      } else {
        // Update existing announcement
        final updates = <String, dynamic>{
          'title': _titleController.text.trim(),
          'content': _contentController.text.trim(),
          'visible_to': _visibleTo,
          'course_id': _selectedCourseId,
          'is_published': _isPublished,
        };

        if (_scheduledAt != null) {
          updates['scheduled_at'] = _scheduledAt!.toIso8601String();
        }

        // Update în Supabase
        await Supabase.instance.client
            .from('announcements')
            .update(updates)
            .eq('id', widget.announcement!['id']);

        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Anunț actualizat cu succes!')),
          );
        }
      }
    } catch (e) {
      Logger.error('Error saving announcement: $e');
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

  Widget _buildMediaPreview() {
    if (_selectedWebMedia != null && kIsWeb) {
      // Pentru web, afișează numele fișierului
      return Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _mediaType == 'image' ? Icons.image : Icons.videocam,
              size: 48,
              color: Colors.green.shade600,
            ),
            const SizedBox(height: 8),
            Text(
              _selectedWebMedia!.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              _mediaType == 'image' ? 'Imagine selectată' : 'Video selectat',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green.shade600,
              ),
            ),
          ],
        ),
      );
    } else if (_selectedMedia != null && !kIsWeb) {
      // Pentru mobile, afișează preview-ul real
      return _mediaType == 'image'
          ? Image.file(_selectedMedia!, fit: BoxFit.cover)
          : const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.videocam, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('Video selectat'),
                ],
              ),
            );
    } else {
      return const Center(
        child: Text('Media selectată'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.announcement != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade600,
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
                      isEditing ? 'Editează Anunțul' : 'Anunț Nou',
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

                      // Content
                      TextFormField(
                        controller: _contentController,
                        decoration: const InputDecoration(
                          labelText: 'Conținut *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
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
                          prefixIcon: Icon(Icons.visibility),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('Toți utilizatorii')),
                          DropdownMenuItem(value: 'student', child: Text('Doar studenții')),
                          DropdownMenuItem(value: 'instructor', child: Text('Doar instructorii')),
                        ],
                        onChanged: (value) => setState(() => _visibleTo = value!),
                      ),
                      const SizedBox(height: 16),

                      // Course selection
                      DropdownButtonFormField<String?>(
                        value: _selectedCourseId,
                        decoration: const InputDecoration(
                          labelText: 'Curs asociat (opțional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.school),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Fără curs asociat'),
                          ),
                          ...widget.courses.map((course) => DropdownMenuItem<String>(
                            value: course['id'],
                            child: Text(course['title'] ?? 'Curs necunoscut'),
                          )),
                        ],
                        onChanged: (value) => setState(() => _selectedCourseId = value),
                      ),
                      const SizedBox(height: 16),

                      // Media selection
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.image),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Media',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const Spacer(),
                                  TextButton.icon(
                                    onPressed: _pickMedia,
                                    icon: const Icon(Icons.add),
                                    label: const Text('Adaugă'),
                                  ),
                                ],
                              ),
                              if (_selectedMedia != null || _selectedWebMedia != null) ...[
                                const SizedBox(height: 8),
                                Container(
                                  height: 120,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: _buildMediaPreview(),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      _mediaType == 'image' ? Icons.image : Icons.videocam,
                                      size: 16,
                                      color: Colors.green.shade600,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        kIsWeb 
                                          ? (_selectedWebMedia?.name ?? 'Media selectată')
                                          : (_selectedMedia?.path.split('/').last ?? 'Media selectată'),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.green.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          _selectedMedia = null;
                                          _selectedWebMedia = null;
                                          _mediaType = null;
                                        });
                                      },
                                      icon: const Icon(Icons.close, size: 16),
                                      label: const Text('Elimină'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ] else if (widget.announcement?['media_url'] != null) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _mediaType == 'image' ? Icons.image : Icons.videocam,
                                        color: Colors.blue,
                                      ),
                                      const SizedBox(width: 8),
                                      const Expanded(
                                        child: Text(
                                          'Media existentă',
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Scheduled date
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.schedule),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Programare',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const Spacer(),
                                  TextButton.icon(
                                    onPressed: _pickScheduledDate,
                                    icon: const Icon(Icons.calendar_today),
                                    label: const Text('Alege'),
                                  ),
                                ],
                              ),
                              if (_scheduledAt != null) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.schedule, color: Colors.orange.shade600),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Programat pentru: ${_scheduledAt!.day}/${_scheduledAt!.month}/${_scheduledAt!.year} la ${_scheduledAt!.hour}:${_scheduledAt!.minute.toString().padLeft(2, '0')}',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close, size: 16),
                                        onPressed: () => setState(() => _scheduledAt = null),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Published switch
                      if (isEditing)
                        SwitchListTile(
                          title: const Text('Publicat'),
                          subtitle: const Text('Anunțul este vizibil pentru utilizatori'),
                          value: _isPublished,
                          onChanged: (value) => setState(() => _isPublished = value),
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
                      onPressed: _isLoading ? null : _saveAnnouncement,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
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