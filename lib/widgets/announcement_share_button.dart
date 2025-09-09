import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../utils/platform_utils_simple.dart';
import '../utils/logger.dart';

class AnnouncementShareButton extends StatelessWidget {
  final String title;
  final String message;
  final String? link;
  final String? imageUrl;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final IconData? icon;
  final String? customLabel;
  final bool isCompact;

  const AnnouncementShareButton({
    super.key,
    required this.title,
    required this.message,
    this.link,
    this.imageUrl,
    this.backgroundColor,
    this.foregroundColor,
    this.icon,
    this.customLabel,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return IconButton(
        onPressed: () => _shareAnnouncement(context),
        icon: Icon(icon ?? Icons.share),
        color: foregroundColor ?? Colors.blue,
        tooltip: 'Partajează anunțul',
      );
    }

    return ElevatedButton.icon(
      onPressed: () => _shareAnnouncement(context),
      icon: Icon(icon ?? Icons.share),
      label: Text(customLabel ?? 'Partajează'),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? Colors.blue,
        foregroundColor: foregroundColor ?? Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Future<void> _shareAnnouncement(BuildContext context) async {
    try {
      // Construiește mesajul pentru partajare
      String shareContent = _buildShareMessage();

      if (imageUrl != null && imageUrl!.isNotEmpty) {
        // Pentru anunțuri cu imagini, încearcă să partajeze cu media
        await _shareWithMedia(context, shareContent);
      } else {
        // Pentru anunțuri doar text
        await Share.share(
          shareContent,
          subject: title,
        );
      }

      // Feedback vizual
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text('Anunț partajat cu succes!'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      Logger.error('Error sharing announcement: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Eroare la partajare: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _buildShareMessage() {
    String content = '🎭 *AIU DANCE - ANUNȚ IMPORTANT*\n\n';
    content += '📢 *$title*\n\n';
    content += message;
    
    if (link != null && link!.isNotEmpty) {
      content += '\n\n🌐 *Aplicația:* $link';
    }
    
    content += '\n\n💃 *Echipa AIU Dance*';
    content += '\n\n#AIUDance #Dans #Cursuri #Salsa #Bachata #Kizomba';
    
    return content;
  }

  Future<void> _shareWithMedia(BuildContext context, String shareContent) async {
    try {
      // Pentru web, partajează doar textul și afișează instrucțiuni pentru imagine
      await Share.share(
        shareContent,
        subject: title,
      );

      // Afișează dialog cu instrucțiuni pentru imagine
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                const Text('Partajare cu Imagine'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Textul a fost partajat cu succes!',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
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
                          Icon(Icons.lightbulb_outline, color: Colors.blue.shade600, size: 16),
                          const SizedBox(width: 6),
                          const Text(
                            'Pentru a include și imaginea:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '1. Deschide WhatsApp/Messenger\n'
                        '2. Lipește textul partajat\n'
                        '3. Adaugă imaginea separat',
                        style: TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (imageUrl != null)
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _openImageInNewTab();
                    },
                    icon: const Icon(Icons.image, size: 16),
                    label: const Text('Vezi Imaginea'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 36),
                    ),
                  ),
              ],
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
    } catch (e) {
      Logger.error('Error sharing with media: $e');
      // Fallback la partajarea simplă
      await Share.share(shareContent, subject: title);
    }
  }

  void _openImageInNewTab() {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      PlatformUtils.openUrl(imageUrl!);
    }
  }
}

/// Widget pentru partajarea rapidă pe platforme specifice
class QuickShareButtons extends StatelessWidget {
  final String title;
  final String message;
  final String? link;
  final String? imageUrl;

  const QuickShareButtons({
    super.key,
    required this.title,
    required this.message,
    this.link,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildQuickShareButton(
          'WhatsApp',
          Icons.chat,
          Colors.green,
          () => _shareToWhatsApp(context),
        ),
        _buildQuickShareButton(
          'Messenger',
          Icons.message,
          Colors.blue,
          () => _shareToMessenger(context),
        ),
        _buildQuickShareButton(
          'Telegram',
          Icons.send,
          Colors.cyan,
          () => _shareToTelegram(context),
        ),
        _buildQuickShareButton(
          'General',
          Icons.share,
          Colors.grey,
          () => _shareGeneral(context),
        ),
      ],
    );
  }

  Widget _buildQuickShareButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(0, 36),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }

  Future<void> _shareToWhatsApp(BuildContext context) async {
    final content = _buildShareContent();
    await Share.share(content, subject: 'AIU Dance - $title');
    _showShareFeedback(context, 'WhatsApp');
  }

  Future<void> _shareToMessenger(BuildContext context) async {
    final content = _buildShareContent();
    await Share.share(content, subject: 'AIU Dance - $title');
    _showShareFeedback(context, 'Messenger');
  }

  Future<void> _shareToTelegram(BuildContext context) async {
    final content = _buildShareContent();
    await Share.share(content, subject: 'AIU Dance - $title');
    _showShareFeedback(context, 'Telegram');
  }

  Future<void> _shareGeneral(BuildContext context) async {
    final content = _buildShareContent();
    await Share.share(content, subject: 'AIU Dance - $title');
    _showShareFeedback(context, 'aplicația selectată');
  }

  String _buildShareContent() {
    String content = '🎭 AIU DANCE - ANUNȚ IMPORTANT\n\n';
    content += '📢 $title\n\n';
    content += message;
    
    if (link != null && link!.isNotEmpty) {
      content += '\n\n🌐 Aplicația: $link';
    }
    
    content += '\n\n💃 Echipa AIU Dance';
    content += '\n#AIUDance #Dans #Cursuri';
    
    return content;
  }

  void _showShareFeedback(BuildContext context, String platform) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Anunț partajat pe $platform!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
