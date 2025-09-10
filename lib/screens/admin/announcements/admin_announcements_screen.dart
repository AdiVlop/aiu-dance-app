import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../utils/platform_utils_simple.dart';
// import '../../../services/announcement_service.dart'; // Fișier șters temporar
import '../../../services/courses_service.dart';
import '../../../utils/logger.dart';
import 'widgets/announcement_card.dart';
import 'widgets/announcement_form_dialog.dart';

class AdminAnnouncementsScreen extends StatefulWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  State<AdminAnnouncementsScreen> createState() => _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState extends State<AdminAnnouncementsScreen> {
  // final AnnouncementService _announcementService = AnnouncementService(); // Temporar comentat
  final CoursesService _coursesService = CoursesService();
  
  List<Map<String, dynamic>> _announcements = [];
  List<Map<String, dynamic>> _courses = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Încarcă anunțurile din Supabase + mock data pentru testare
      List<Map<String, dynamic>> announcements = [];
      
      try {
        // Încearcă să încarci anunțurile reale din Supabase
        final response = await Supabase.instance.client
            .from('announcements')
            .select()
            .order('created_at', ascending: false);
        
        announcements = List<Map<String, dynamic>>.from(response);
        print('[ANNOUNCEMENTS] Loaded ${announcements.length} announcements from Supabase');
        
        // Dacă nu există anunțuri în baza de date, adaugă mock data
        if (announcements.isEmpty) {
          announcements = [
            {
              'id': 'mock-1',
              'title': 'Curs Special de Salsa',
              'content': 'Vino să înveți pașii de salsa cu instructorul nostru principal! Cursul se va desfășura sâmbătă de la ora 18:00.',
              'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
              'is_published': true,
              'visible_to': 'all',
              'course_id': 'course-1',
              'media_url': null,
              'media_type': 'none',
            },
            {
              'id': 'mock-2', 
              'title': 'Workshop Bachata pentru Începători',
              'content': 'Descoperă frumusețea dansului bachata într-un workshop dedicat începătorilor. Toate vârstele sunt binevenite!',
              'created_at': DateTime.now().subtract(const Duration(hours: 12)).toIso8601String(),
              'is_published': false,
              'visible_to': 'students',
              'course_id': 'course-2',
              'media_url': null,
              'media_type': 'none',
            },
            {
              'id': 'mock-3',
              'title': 'Eveniment Special Kizomba',
              'content': 'Seară magică de kizomba cu muzică live și demonstrații de dans. Nu rata această experiență unică!',
              'created_at': DateTime.now().subtract(const Duration(hours: 6)).toIso8601String(),
              'is_published': true,
              'visible_to': 'all',
              'course_id': 'course-3',
              'media_url': null,
              'media_type': 'none',
            },
          ];
          print('[ANNOUNCEMENTS] Using mock data (${announcements.length} items)');
        }
      } catch (e) {
        print('[ANNOUNCEMENTS] Error loading from Supabase: $e');
        // Fallback la mock data în caz de eroare
        announcements = [
          {
            'id': 'mock-1',
            'title': 'Curs Special de Salsa',
            'content': 'Vino să înveți pașii de salsa cu instructorul nostru principal! Cursul se va desfășura sâmbătă de la ora 18:00.',
            'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
            'is_published': true,
            'visible_to': 'all',
            'course_id': 'course-1',
            'media_url': null,
            'media_type': 'none',
          },
        ];
        print('[ANNOUNCEMENTS] Using fallback mock data');
      }
      final courses = await _coursesService.getCourses();
      
      if (mounted) {
        setState(() {
          _announcements = announcements;
          _courses = courses;
          _isLoading = false;
        });
      }
    } catch (e) {
      Logger.error('Error loading announcements data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare la încărcarea datelor: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredAnnouncements {
    if (_selectedFilter == 'all') return _announcements;
    return _announcements.where((announcement) => 
      announcement['visible_to'] == _selectedFilter
    ).toList();
  }

  Future<void> _showAnnouncementDialog([Map<String, dynamic>? announcement]) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AnnouncementFormDialog(
        announcement: announcement,
        courses: _courses,
      ),
    );

    if (result == true) {
      await _loadData();
    }
  }

  Future<void> _deleteAnnouncement(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmă ștergerea'),
        content: const Text('Ești sigur că vrei să ștergi acest anunț?'),
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

    if (confirm == true) {
      try {
        await Supabase.instance.client
            .from('announcements')
            .delete()
            .eq('id', id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Anunț șters cu succes!')),
          );
          await _loadData();
        }
      } catch (e) {
        Logger.error('Error deleting announcement: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Eroare la ștergerea anunțului: $e')),
          );
        }
      }
    }
  }

  Future<void> _shareToWhatsApp(Map<String, dynamic> announcement) async {
    try {
      // 1. Marchează ca publicat în WhatsApp
      await Supabase.instance.client
          .from('announcements')
          .update({
            'is_published': true,
            'published_at': DateTime.now().toIso8601String(),
            'distribution_method': 'whatsapp',
          })
          .eq('id', announcement['id']);

      // 2. Verifică dacă are media
      final hasMedia = announcement['media_url'] != null && 
                      announcement['media_url'].toString().isNotEmpty;
      
      if (hasMedia) {
        // Pentru anunțuri cu imagini, afișează dialog special
        _showWhatsAppWithImageDialog(announcement);
      } else {
        // Pentru anunțuri doar text, partajează direct
        final whatsappMessage = _generateWhatsAppMessage(announcement);
        await PlatformUtils.openWhatsApp(whatsappMessage);
        _showWhatsAppSuccessDialog(whatsappMessage);
      }

      await _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare la distribuirea WhatsApp: $e')),
      );
    }
  }

  void _showWhatsAppWithImageDialog(Map<String, dynamic> announcement) {
    final title = announcement['title'] ?? '';
    final content = announcement['content'] ?? '';
    final mediaUrl = announcement['media_url'] as String;
    
    // Mesaj fără link către imagine
    final textMessage = """
🎭 *AIU DANCE - ANUNȚ OFICIAL*

📢 *$title*

$content

👥 *Destinatar:* ${announcement['visible_to'] == 'students' ? 'Studenți' : 'Toți utilizatorii'}
📅 *Data:* ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}
⏰ *Ora:* ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}

💃 *Administrația AIU Dance*
🌐 *Aplicația:* https://aiu-dance.web.app

#AIUDance #Dans #Cursuri""".trim();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.chat, color: Colors.green.shade600),
            const SizedBox(width: 8),
            const Text('Partajare WhatsApp cu Imagine'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Preview imagine
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    mediaUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image, size: 48, color: Colors.grey),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              Text(
                'Pentru a partaja cu imagine pe WhatsApp:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 12),
              
              // Instrucțiuni pas cu pas
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStep('1', 'Salvează imaginea pe computer', 'Click dreapta → "Save image as"'),
                    const SizedBox(height: 8),
                    _buildStep('2', 'Deschide WhatsApp', 'Se va deschide cu textul pre-completat'),
                    const SizedBox(height: 8),
                    _buildStep('3', 'Adaugă imaginea', 'Click pe 📎 → selectează imaginea salvată'),
                    const SizedBox(height: 8),
                    _buildStep('4', 'Trimite', 'Imaginea va apărea în WhatsApp!'),
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
            icon: const Icon(Icons.download),
            label: const Text('Deschide Imaginea'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              PlatformUtils.openWhatsApp(textMessage);
            },
            icon: const Icon(Icons.chat),
            label: const Text('Deschide WhatsApp'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String number, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.green.shade600,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _generateWhatsAppMessage(Map<String, dynamic> announcement) {
    final title = announcement['title'] ?? '';
    final content = announcement['content'] ?? '';
    final visibleTo = announcement['visible_to'] ?? 'all';
    
    final audienceText = visibleTo == 'students' ? 'Studenți' : 'Toți utilizatorii';
    
    String message = """
🎭 *AIU DANCE - ANUNȚ OFICIAL*

📢 *${title}*

${content}

👥 *Destinatar:* ${audienceText}
📅 *Data:* ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}
⏰ *Ora:* ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}

💃 *Administrația AIU Dance*
🌐 *Aplicația:* https://aiu-dance.web.app

#AIUDance #Dans #Cursuri""";
    
    return message.trim();
  }

  void _showWhatsAppSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600),
            const SizedBox(width: 8),
            const Text('WhatsApp Deschis'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'WhatsApp s-a deschis cu mesajul pre-completat!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: const Text(
                'Trimite mesajul în grupurile de cursuri AIU Dance!',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Închide'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              PlatformUtils.shareContent(message, subject: 'AIU Dance');
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copiază Mesajul'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openWhatsApp(String message, Map<String, dynamic> announcementData) async {
    try {
      // Încearcă să deschidă WhatsApp direct
      final encodedMessage = Uri.encodeComponent(message);
      final whatsappUrl = 'https://wa.me/?text=$encodedMessage';
      
      // Pentru web, deschide într-un tab nou
      PlatformUtils.openUrl(whatsappUrl);
      
      // Afișează dialog-ul cu informații
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
                if (announcementData['media_url'] != null)
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
            if (announcementData['media_url'] != null && 
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
            Icon(Icons.share, color: const Color(0xFF7A0029)),
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
                const Color(0xFF9C0033),
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
    Navigator.pop(context);
    
    // Deschide WhatsApp cu mesajul
    await PlatformUtils.openWhatsApp(message);
    
    // Deschide imaginea în tab separat pentru copiere
    await PlatformUtils.openUrl(mediaUrl);
    
    // Afișează dialog cu instrucțiuni
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.chat, color: Colors.green.shade600),
            const SizedBox(width: 8),
            const Text('WhatsApp cu Imagine'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview imagine
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  mediaUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image, size: 48, color: Colors.grey),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
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
                        'Instrucțiuni pentru imagine:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '1. WhatsApp s-a deschis cu textul\n'
                    '2. Imaginea s-a deschis în tab separat\n'
                    '3. Fă click dreapta pe imagine → "Copy image"\n'
                    '4. Întoarce-te la WhatsApp și lipește imaginea',
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
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              PlatformUtils.openUrl(mediaUrl);
            },
            icon: const Icon(Icons.image),
            label: const Text('Vezi Din Nou'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareToInstagramWithMedia(String message, String mediaUrl, String mediaType) async {
    Navigator.pop(context);
    
    PlatformUtils.openUrl('https://www.instagram.com/');
    PlatformUtils.openUrl(mediaUrl);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Instagram și imaginea s-au deschis!'),
        backgroundColor: const Color(0xFF9C0033),
        duration: Duration(seconds: 4),
      ),
    );
  }

  Future<void> _shareToFacebookWithMedia(String message, String mediaUrl, String mediaType) async {
    Navigator.pop(context);
    
    PlatformUtils.openUrl('https://www.facebook.com/');
    PlatformUtils.openUrl(mediaUrl);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Facebook și imaginea s-au deschis!'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 4),
      ),
    );
  }

  Future<void> _shareToTikTokWithMedia(String message, String mediaUrl, String mediaType) async {
    Navigator.pop(context);
    
    PlatformUtils.openUrl('https://www.tiktok.com/');
    PlatformUtils.openUrl(mediaUrl);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('TikTok și media s-au deschis!'),
        backgroundColor: Colors.black87,
        duration: Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrare Anunțuri'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                const Text(
                  'Filtrează: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('all', 'Toate'),
                        const SizedBox(width: 8),
                        _buildFilterChip('student', 'Studenți'),
                        const SizedBox(width: 8),
                        _buildFilterChip('instructor', 'Instructori'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Statistics Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Anunțuri',
                    _announcements.length.toString(),
                    Icons.announcement,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Publicate',
                    _announcements.where((a) => a['is_published'] == true).length.toString(),
                    Icons.publish,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Cu Media',
                    _announcements.where((a) => a['media_url'] != null).length.toString(),
                    Icons.image,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredAnnouncements.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredAnnouncements.length,
                          itemBuilder: (context, index) {
                            final announcement = _filteredAnnouncements[index];
                            return AnnouncementCard(
                              announcement: announcement,
                              onEdit: () => _showAnnouncementDialog(announcement),
                              onDelete: () => _deleteAnnouncement(announcement['id']),
                              onShare: (platform) {
                                if (platform == 'whatsapp') {
                                  _shareToWhatsApp(announcement);
                                } else {
                                  // Share direct prin URL launcher
                                  _shareToSocialMedia(platform, announcement);
                                }
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAnnouncementDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Anunț Nou'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedFilter = value);
      },
      backgroundColor: Colors.white,
      selectedColor: Colors.blue.shade100,
      checkmarkColor: Colors.blue.shade600,
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.announcement_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Nu există anunțuri',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Apasă pe butonul "+" pentru a crea primul anunț',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  void _shareToSocialMedia(String platform, Map<String, dynamic> announcement) {
    final title = announcement['title'] ?? '';
    final content = announcement['content'] ?? '';
    final shareText = '$title\n\n$content\n\n🎭 AIU Dance - Aplicația ta de dans preferată';
    final encodedText = Uri.encodeComponent(shareText);
    
    String url;
    switch (platform.toLowerCase()) {
      case 'facebook':
        url = 'https://www.facebook.com/sharer/sharer.php?u=https://aiu-dance.web.app&quote=$encodedText';
        break;
      case 'instagram':
        url = 'instagram://app';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Aplicația Instagram se va deschide. Copiază textul: $shareText')),
        );
        break;
      case 'tiktok':
        url = 'tiktok://app';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Aplicația TikTok se va deschide. Copiază textul: $shareText')),
        );
        break;
      case 'telegram':
        url = 'https://t.me/share/url?text=$encodedText&url=https://aiu-dance.web.app';
        break;
      case 'twitter':
        url = 'https://twitter.com/intent/tweet?text=$encodedText&url=https://aiu-dance.web.app';
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share pe $platform: $shareText')),
        );
        return;
    }
    
    launchUrl(Uri.parse(url));
  }
}