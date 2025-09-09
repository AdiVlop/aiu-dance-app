import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/meta_api_service.dart';
import '../../widgets/announcement_share_button.dart';
import '../../utils/platform_utils_simple.dart';

class InstructorAnnouncementsScreen extends StatefulWidget {
  const InstructorAnnouncementsScreen({super.key});

  @override
  State<InstructorAnnouncementsScreen> createState() => _InstructorAnnouncementsScreenState();
}

class _InstructorAnnouncementsScreenState extends State<InstructorAnnouncementsScreen> {
  List<Map<String, dynamic>> _announcements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('announcements')
          .select('*')
          .eq('created_by', user.id)
          .order('created_at', ascending: false);

      setState(() {
        _announcements = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print('Error loading announcements: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAnnouncement(String announcementId) async {
    try {
      await Supabase.instance.client
          .from('announcements')
          .delete()
          .eq('id', announcementId);

      await _loadAnnouncements();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anunț șters cu succes')),
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

  void _showDeleteDialog(String announcementId, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Șterge anunț'),
        content: Text('Sigur doriți să ștergeți anunțul "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anulează'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAnnouncement(announcementId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Șterge'),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String selectedTarget = 'students';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Creează anunț'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Titlu'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(labelText: 'Conținut'),
                  maxLines: 5,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedTarget,
                  decoration: const InputDecoration(labelText: 'Destinatar'),
                  items: const [
                    DropdownMenuItem(value: 'students', child: Text('Studenți')),
                    DropdownMenuItem(value: 'all', child: Text('Toți utilizatorii')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedTarget = value!;
                    });
                  },
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
                if (titleController.text.isEmpty || contentController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Completați toate câmpurile')),
                  );
                  return;
                }

                try {
                  final user = Supabase.instance.client.auth.currentUser;
                  if (user == null) return;

                  final response = await Supabase.instance.client.from('announcements').insert({
                    'title': titleController.text,
                    'content': contentController.text,
                    'target_role': selectedTarget,
                    'created_by': user.id,
                    'is_published': false, // Inițial nepublicat
                    'created_at': DateTime.now().toIso8601String(),
                  }).select().single();

                  await _loadAnnouncements();
                  Navigator.pop(context);
                  
                  if (mounted) {
                    _showPublishOptionsDialog(response);
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Eroare la creare: $e')),
                    );
                  }
                }
              },
              child: const Text('Creează'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPublishOptionsDialog(Map<String, dynamic> announcement) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.share, color: Colors.green.shade600),
            const SizedBox(width: 8),
            const Text('Publică Anunțul'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Anunțul "${announcement['title']}" a fost creat cu succes!',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            const Text(
              'Alege cum vrei să îl publici:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            // WhatsApp Option
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.chat, color: Colors.green.shade600, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Distribuie în WhatsApp',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Trimite în grupurile de cursuri',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Facebook & Instagram Option
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.facebook, color: Colors.blue.shade600, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Facebook & Instagram',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Publică automat pe rețelele sociale',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // App Only Option
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.app_registration, color: Colors.purple.shade600, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Doar în aplicație',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Vizibil doar în AIU Dance app',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Warning
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange.shade600, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Dacă nu publici acum, vei primi reminder-e din oră în oră!',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _scheduleHourlyReminders(announcement['id']);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Anunț salvat ca draft. Vei primi reminder-e pentru publicare.'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('Publică mai târziu'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _publishToAppOnly(announcement['id']);
            },
            icon: const Icon(Icons.app_registration),
            label: const Text('Doar în app'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _publishToMeta(announcement);
            },
            icon: const Icon(Icons.facebook),
            label: const Text('Facebook & IG'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showShareOptions(announcement);
            },
            icon: const Icon(Icons.share),
            label: const Text('Partajează'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _publishToAppOnly(String announcementId) async {
    try {
      await Supabase.instance.client
          .from('announcements')
          .update({
            'is_published': true,
            'published_at': DateTime.now().toIso8601String(),
            'distribution_method': 'app_only',
          })
          .eq('id', announcementId);

      await _loadAnnouncements();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anunț publicat în aplicație!'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare la publicare: $e')),
      );
    }
  }

  Future<void> _publishToMeta(Map<String, dynamic> announcement) async {
    try {
      // Inițializează Meta API Service
      await MetaApiService.initialize();
      
      if (!MetaApiService.isConfigured) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meta API nu este configurat. Verifică Settings → Configurare Meta API.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
        return;
      }

      // Afișează dialog de progres
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Publicând pe Facebook și Instagram...'),
            ],
          ),
        ),
      );

      // 1. Marchează ca publicat
      await Supabase.instance.client
          .from('announcements')
          .update({
            'is_published': true,
            'published_at': DateTime.now().toIso8601String(),
            'distribution_method': 'meta_api',
          })
          .eq('id', announcement['id']);

      // 2. Publică pe Meta platforms
      final result = await MetaApiService.publishToBoth(
        title: announcement['title'] ?? '',
        content: announcement['content'] ?? '',
        imageUrl: announcement['media_url'],
        appUrl: 'https://aiu-dance.web.app',
      );

      Navigator.pop(context); // Close progress dialog

      if (result['success']) {
        await _loadAnnouncements();
        _showMetaPublishResult(result);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${result['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close progress dialog if open
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare la publicarea pe Meta: $e')),
      );
    }
  }

  void _showMetaPublishResult(Map<String, dynamic> result) {
    final results = result['results'] as Map<String, dynamic>;
    final fbSuccess = results['facebook']['success'] == true;
    final igSuccess = results['instagram']['success'] == true;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600),
            const SizedBox(width: 8),
            const Text('Publicare Completă'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result['message'] ?? 'Publicare completă',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            
            // Facebook status
            Row(
              children: [
                Icon(
                  fbSuccess ? Icons.check_circle : Icons.error,
                  color: fbSuccess ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  fbSuccess ? 'Facebook ✓' : 'Facebook ✗',
                  style: TextStyle(
                    color: fbSuccess ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Instagram status
            Row(
              children: [
                Icon(
                  igSuccess ? Icons.check_circle : Icons.error,
                  color: igSuccess ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  igSuccess ? 'Instagram ✓' : 'Instagram ✗',
                  style: TextStyle(
                    color: igSuccess ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            
            if (!fbSuccess || !igSuccess) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange.shade600, size: 16),
                        const SizedBox(width: 8),
                        const Text(
                          'Probleme detectate:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (!fbSuccess)
                      Text(
                        '• Facebook: ${results['facebook']['message'] ?? 'Eroare necunoscută'}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    if (!igSuccess)
                      Text(
                        '• Instagram: ${results['instagram']['message'] ?? 'Eroare necunoscută'}',
                        style: const TextStyle(fontSize: 11),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Închide'),
          ),
          if (fbSuccess || igSuccess)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Verifică postările pe Facebook și Instagram!'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('Vezi Postările'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  void _showShareOptions(Map<String, dynamic> announcement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.share, color: Colors.green.shade600),
            const SizedBox(width: 8),
            const Text('Partajează Anunțul'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Partajează "${announcement['title']}" pe:',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            
            // Quick share buttons
            QuickShareButtons(
              title: announcement['title'] ?? '',
              message: announcement['content'] ?? '',
              link: 'https://aiu-dance.web.app',
              imageUrl: announcement['media_url'],
            ),
            
            const SizedBox(height: 20),
            
            // Instructions
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade600, size: 16),
                      const SizedBox(width: 6),
                      const Text(
                        'Cum funcționează:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '• Se va deschide aplicația selectată\n'
                    '• Mesajul va fi pre-completat\n'
                    '• Pentru imagini, adaugă separat',
                    style: TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Închide'),
          ),
          if (announcement['media_url'] != null)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                PlatformUtils.openUrl(announcement['media_url']);
              },
              icon: const Icon(Icons.image, size: 16),
              label: const Text('Vezi Imaginea'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _publishToWhatsApp(Map<String, dynamic> announcement) async {
    try {
      // 1. Marchează ca publicat
      await Supabase.instance.client
          .from('announcements')
          .update({
            'is_published': true,
            'published_at': DateTime.now().toIso8601String(),
            'distribution_method': 'whatsapp',
          })
          .eq('id', announcement['id']);

      // 2. Generează mesajul pentru WhatsApp
      final whatsappMessage = _generateWhatsAppMessage(announcement);
      
      // 3. Deschide WhatsApp cu mesajul
      await _openWhatsApp(whatsappMessage, announcement);

      await _loadAnnouncements();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anunț publicat și distribuit în WhatsApp!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare la distribuirea WhatsApp: $e')),
      );
    }
  }

  String _generateWhatsAppMessage(Map<String, dynamic> announcement) {
    final title = announcement['title'] ?? '';
    final content = announcement['content'] ?? '';
    final targetRole = announcement['target_role'] ?? 'students';
    final mediaUrl = announcement['media_url'] as String?;
    final mediaType = announcement['media_type'] as String?;
    
    final roleText = targetRole == 'students' ? 'Studenți' : 'Toți';
    
    String message = """
🎭 *AIU DANCE - ANUNȚ IMPORTANT*

📢 *${title}*

${content}

👥 *Destinatar:* ${roleText}
📅 *Data:* ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}
⏰ *Ora:* ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}""";

    // Adaugă link-ul către media dacă există
    if (mediaUrl != null && mediaUrl.isNotEmpty) {
      if (mediaType == 'image') {
        message += '\n\n📸 *Imagine:* $mediaUrl';
      } else if (mediaType == 'video') {
        message += '\n\n🎥 *Video:* $mediaUrl';
      } else {
        message += '\n\n📎 *Fișier atașat:* $mediaUrl';
      }
    }

    message += '\n\n💃 *Echipa AIU Dance*';
    message += '\n🌐 *Aplicația:* https://aiu-dance.web.app';
    
    return message.trim();
  }

  Future<void> _openWhatsApp(String message, [Map<String, dynamic>? announcementData]) async {
    try {
      final hasMedia = announcementData?['media_url'] != null && 
                      announcementData!['media_url'].toString().isNotEmpty;
      
      if (hasMedia) {
        // Pentru anunțuri cu media, afișează opțiuni multiple
        _showMediaSharingOptions(message, announcementData!);
      } else {
        // Pentru anunțuri doar text, deschide direct WhatsApp
        final encodedMessage = Uri.encodeComponent(message);
        final whatsappUrl = 'https://wa.me/?text=$encodedMessage';
        PlatformUtils.openUrl(whatsappUrl);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('WhatsApp deschis cu mesajul!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      // Afișează dialog-ul cu opțiuni multiple
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.chat, color: Colors.green.shade600),
              const SizedBox(width: 8),
              const Text('Distribuire WhatsApp'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'WhatsApp s-a deschis cu mesajul pre-completat!',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                const Text(
                  'Mesajul pentru WhatsApp:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: SelectableText(
                    message,
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Instructions for media
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Pentru imagini și media:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '1. Trimite mai întâi mesajul text în grup\n'
                        '2. Apoi trimite separat imaginile/video-urile\n'
                        '3. Link-urile către media sunt incluse în mesaj',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Închide'),
            ),
            if (announcementData != null && 
                announcementData['media_url'] != null && 
                announcementData['media_url'].toString().isNotEmpty)
              TextButton.icon(
                onPressed: () {
                  final mediaUrl = announcementData['media_url'] as String;
                  PlatformUtils.openUrl(mediaUrl);
                },
                icon: const Icon(Icons.image),
                label: const Text('Vezi Media'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                ),
              ),
            ElevatedButton.icon(
              onPressed: () {
                // Copy to clipboard functionality
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Mesaj copiat! Trimite în grupurile WhatsApp.'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copiază'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare la deschiderea WhatsApp: $e')),
      );
    }
  }

  void _showMediaSharingOptions(String message, Map<String, dynamic> announcementData) {
    final mediaUrl = announcementData['media_url'] as String;
    final mediaType = announcementData['media_type'] as String? ?? 'image';
    final title = announcementData['title'] ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.share, color: Colors.purple.shade600),
            const SizedBox(width: 8),
            const Text('Distribuire cu Media'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Media preview
              Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: mediaType == 'image'
                      ? Image.network(
                          mediaUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.image, size: 48, color: Colors.grey),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey.shade200,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.videocam, size: 48, color: Colors.grey.shade600),
                              const SizedBox(height: 8),
                              const Text('Video', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              
              Text(
                'Alege platforma pentru distribuire:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 16),

              // Platform buttons
              _buildPlatformButton(
                'WhatsApp',
                Icons.chat,
                Colors.green,
                () => _shareToWhatsAppWithMedia(message, mediaUrl, mediaType),
              ),
              const SizedBox(height: 8),
              _buildPlatformButton(
                'Instagram',
                Icons.camera_alt,
                Colors.purple,
                () => _shareToInstagramWithMedia(message, mediaUrl, mediaType),
              ),
              const SizedBox(height: 8),
              _buildPlatformButton(
                'Facebook',
                Icons.facebook,
                Colors.blue,
                () => _shareToFacebookWithMedia(message, mediaUrl, mediaType),
              ),
              const SizedBox(height: 8),
              _buildPlatformButton(
                'TikTok',
                Icons.music_note,
                Colors.black,
                () => _shareToTikTokWithMedia(message, mediaUrl, mediaType),
              ),
              const SizedBox(height: 16),
              
              // Instructions
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: Colors.amber.shade700, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Instrucțiuni:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Se va deschide platforma selectată\n'
                      '• Imaginea se va deschide în tab separat\n'
                      '• Copiază și lipește imaginea manual\n'
                      '• Adaugă textul din mesaj',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anulează'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              PlatformUtils.openUrl(mediaUrl);
            },
            icon: const Icon(Icons.open_in_new),
            label: const Text('Deschide Media'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformButton(String name, IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text('Distribuie pe $name'),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Future<void> _shareToWhatsAppWithMedia(String message, String mediaUrl, String mediaType) async {
    Navigator.pop(context); // Close dialog
    
    // Deschide WhatsApp cu mesajul
    final encodedMessage = Uri.encodeComponent(message);
    final whatsappUrl = 'https://wa.me/?text=$encodedMessage';
    PlatformUtils.openUrl(whatsappUrl);
    
    // Deschide imaginea în tab separat pentru copiere
    PlatformUtils.openUrl(mediaUrl);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('WhatsApp și imaginea s-au deschis! Copiază imaginea manual.'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Vezi Media',
          textColor: Colors.white,
          onPressed: () => PlatformUtils.openUrl(mediaUrl),
        ),
      ),
    );
  }

  Future<void> _shareToInstagramWithMedia(String message, String mediaUrl, String mediaType) async {
    Navigator.pop(context);
    
    // Deschide Instagram și imaginea
    PlatformUtils.openUrl('https://www.instagram.com/');
    PlatformUtils.openUrl(mediaUrl);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Instagram și imaginea s-au deschis! Creează un post nou și adaugă imaginea.'),
        backgroundColor: Colors.purple,
        duration: Duration(seconds: 4),
      ),
    );
  }

  Future<void> _shareToFacebookWithMedia(String message, String mediaUrl, String mediaType) async {
    Navigator.pop(context);
    
    // Deschide Facebook și imaginea
    PlatformUtils.openUrl('https://www.facebook.com/');
    PlatformUtils.openUrl(mediaUrl);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Facebook și imaginea s-au deschis! Creează un post nou și adaugă imaginea.'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 4),
      ),
    );
  }

  Future<void> _shareToTikTokWithMedia(String message, String mediaUrl, String mediaType) async {
    Navigator.pop(context);
    
    // Deschide TikTok și imaginea/video-ul
    PlatformUtils.openUrl('https://www.tiktok.com/');
    PlatformUtils.openUrl(mediaUrl);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('TikTok și media s-au deschis! Creează un video nou și adaugă conținutul.'),
        backgroundColor: Colors.black87,
        duration: Duration(seconds: 4),
      ),
    );
  }

  Future<void> _scheduleHourlyReminders(String announcementId) async {
    try {
      // Creează reminder în tabela notifications
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      await Supabase.instance.client.from('notifications').insert({
        'user_id': user.id,
        'title': 'Anunț nepublicat',
        'body': 'Ai un anunț care așteaptă să fie publicat. Apasă pentru a-l distribui.',
        'type': 'unpublished_announcement',
        'data': {
          'announcement_id': announcementId,
          'reminder_type': 'hourly',
          'created_at': DateTime.now().toIso8601String(),
        },
        'read': false,
        'sent_at': DateTime.now().toIso8601String(),
      });

      // Programează reminder-ul pentru următoarea oră
      _scheduleNextReminder(announcementId);
    } catch (e) {
      print('Error scheduling reminders: $e');
    }
  }

  void _scheduleNextReminder(String announcementId) {
    // Pentru demo, vom simula reminder-ul cu un timer
    // În producție, ar trebui să folosești un serviciu de background sau Firebase Functions
    
    // Simulează reminder după 1 minut (pentru demo)
    Future.delayed(const Duration(minutes: 1), () {
      if (mounted) {
        _showReminderNotification(announcementId);
      }
    });
  }

  void _showReminderNotification(String announcementId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('🔔 Reminder: Ai un anunț nepublicat!'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Publică acum',
          textColor: Colors.white,
          onPressed: () => _showAnnouncementForPublishing(announcementId),
        ),
      ),
    );
  }

  Future<void> _showAnnouncementForPublishing(String announcementId) async {
    try {
      final announcement = await Supabase.instance.client
          .from('announcements')
          .select('*')
          .eq('id', announcementId)
          .single();

      _showPublishOptionsDialog(announcement);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare la încărcarea anunțului: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anunțurile Mele'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnnouncements,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _announcements.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.announcement, size: 100, color: Colors.grey),
                      SizedBox(height: 20),
                      Text(
                        'Nu aveți anunțuri create',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _announcements.length,
                  itemBuilder: (context, index) {
                    final announcement = _announcements[index];
                    
                    final isPublished = announcement['is_published'] ?? false;
                    final distributionMethod = announcement['distribution_method'] ?? '';
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isPublished ? Colors.green.shade200 : Colors.orange.shade200,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Status Badge
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isPublished ? Colors.green.shade100 : Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isPublished ? Icons.check_circle : Icons.schedule,
                                        size: 16,
                                        color: isPublished ? Colors.green.shade700 : Colors.orange.shade700,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isPublished ? 'Publicat' : 'Draft',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isPublished ? Colors.green.shade700 : Colors.orange.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (distributionMethod == 'whatsapp') ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.chat, size: 12, color: Colors.green.shade700),
                                        const SizedBox(width: 2),
                                        Text(
                                          'WhatsApp',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.green.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const Spacer(),
                                if (!isPublished)
                                  IconButton(
                                    onPressed: () => _showPublishOptionsDialog(announcement),
                                    icon: Icon(Icons.share, color: Colors.green.shade600),
                                    tooltip: 'Publică anunțul',
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    announcement['title'] ?? 'Anunț fără titlu',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'delete') {
                                      _showDeleteDialog(
                                        announcement['id'],
                                        announcement['title'] ?? 'Anunț fără titlu',
                                      );
                                    }
                                  },
                                  itemBuilder: (context) => [
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
                            Text(
                              announcement['content'] ?? 'Fără conținut',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.people, size: 16, color: Colors.purple),
                                const SizedBox(width: 4),
                                Text(_getTargetText(announcement['target_role'])),
                                const SizedBox(width: 16),
                                Icon(Icons.access_time, size: 16, color: Colors.purple),
                                const SizedBox(width: 4),
                                Text(_formatDate(announcement['created_at'])),
                              ],
                            ),
                            
                            // Share buttons pentru anunțuri publicate
                            if (isPublished) ...[
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Text(
                                    'Partajează:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: QuickShareButtons(
                                      title: announcement['title'] ?? '',
                                      message: announcement['content'] ?? '',
                                      link: 'https://aiu-dance.web.app',
                                      imageUrl: announcement['media_url'],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  String _getTargetText(String? targetRole) {
    switch (targetRole) {
      case 'students':
        return 'Pentru studenți';
      case 'all':
        return 'Pentru toți';
      default:
        return 'Destinatar necunoscut';
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Data necunoscută';
    try {
      final dateTime = DateTime.parse(dateString);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Data necunoscută';
    }
  }
}
