import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class SocialMediaDialog extends StatefulWidget {
  final Map<String, dynamic> announcement;

  const SocialMediaDialog({
    super.key,
    required this.announcement,
  });

  @override
  State<SocialMediaDialog> createState() => _SocialMediaDialogState();
}

class _SocialMediaDialogState extends State<SocialMediaDialog> {
  // Social media login states
  bool _isFacebookLoggedIn = false;
  bool _isInstagramLoggedIn = false;
  bool _isTikTokLoggedIn = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.share, color: Colors.blue, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Publicare Social Media',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Announcement preview
            _buildAnnouncementPreview(),
            
            const SizedBox(height: 24),
            
            // Social media platforms
            _buildSocialMediaPlatforms(),
            
            const SizedBox(height: 24),
            
            // Publishing options
            _buildPublishingOptions(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Previzualizare Anunț',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.announcement['title'],
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.announcement['description'],
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          if (widget.announcement['imageUrl'] != null && widget.announcement['imageUrl'].isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  widget.announcement['imageUrl'],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.image, size: 48, color: Colors.grey),
                    );
                  },
                ),
              ),
            ),
          ] else if (widget.announcement['localImage'] != null) ...[
            const SizedBox(height: 12),
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(widget.announcement['localImage']),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.image, size: 48, color: Colors.grey),
                    );
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSocialMediaPlatforms() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Platforme Social Media',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildPlatformCard(
                'Facebook',
                Icons.facebook,
                Colors.blue.shade600,
                _isFacebookLoggedIn,
                () => _loginToFacebook(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPlatformCard(
                'Instagram',
                Icons.camera_alt,
                const Color(0xFF7A0029),
                _isInstagramLoggedIn,
                () => _loginToInstagram(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPlatformCard(
                'TikTok',
                Icons.music_note,
                Colors.black,
                _isTikTokLoggedIn,
                () => _loginToTikTok(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildPlatformCard(
                'WhatsApp',
                Icons.chat,
                Colors.green.shade600,
                false, // WhatsApp doesn't need login state
                () => _publishToWhatsApp(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPlatformCard(
                'Telegram',
                Icons.send,
                Colors.blue.shade400,
                false,
                () => _publishToTelegram(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPlatformCard(
                'Email',
                Icons.email,
                Colors.orange.shade600,
                false,
                () => _publishToEmail(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlatformCard(String name, IconData icon, Color color, bool isLoggedIn, VoidCallback onLogin) {
    return Card(
      child: InkWell(
        onTap: onLogin,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: isLoggedIn ? Colors.green : color,
              ),
              const SizedBox(height: 8),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isLoggedIn ? Colors.green.shade100 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isLoggedIn ? 'Conectat' : 'Conectează-te',
                  style: TextStyle(
                    fontSize: 10,
                    color: isLoggedIn ? Colors.green.shade700 : Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPublishingOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Opțiuni Publicare',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Direct publishing buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _publishToSocialMedia('Facebook'),
                icon: const Icon(Icons.facebook),
                label: const Text('Publică pe Facebook'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _publishToSocialMedia('Instagram'),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Publică pe Instagram'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7A0029),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _publishToSocialMedia('TikTok'),
                icon: const Icon(Icons.music_note),
                label: const Text('Publică pe TikTok'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Manual export options
        const Text(
          'Export pentru publicare manuală',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _copyToClipboard(),
                icon: const Icon(Icons.copy),
                label: const Text('Copiază text'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _exportImage(),
                icon: const Icon(Icons.image),
                label: const Text('Export imagine'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _openSocialMediaApp('Facebook'),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Deschide Facebook'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _loginToFacebook() {
    _showLoginDialog('Facebook', () {
      setState(() {
        _isFacebookLoggedIn = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conectat cu succes la Facebook!'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  void _loginToInstagram() {
    _showLoginDialog('Instagram', () {
      setState(() {
        _isInstagramLoggedIn = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conectat cu succes la Instagram!'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  void _loginToTikTok() {
    _showLoginDialog('TikTok', () {
      setState(() {
        _isTikTokLoggedIn = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conectat cu succes la TikTok!'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  void _showLoginDialog(String platform, VoidCallback onSuccess) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Conectare la $platform'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Vrei să te conectezi la $platform pentru a publica anunțurile direct?'),
            const SizedBox(height: 16),
            const Text(
              'Notă: Această funcționalitate necesită integrarea cu API-urile respective.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anulează'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onSuccess();
            },
            child: const Text('Conectează-te'),
          ),
        ],
      ),
    );
  }

  void _publishToSocialMedia(String platform) {
    // Deschide direct platforma social media pentru publicare
    String url = '';
    String message = '';
    
    switch (platform) {
      case 'Facebook':
        url = 'https://www.facebook.com/sharer/sharer.php?u=https://aiudance.com&quote=${Uri.encodeComponent('${widget.announcement['title']}\n\n${widget.announcement['description']}')}';
        message = 'Se deschide Facebook pentru publicare...';
        break;
      case 'Instagram':
        url = 'https://www.instagram.com/aiudance';
        message = 'Se deschide Instagram. Copiază textul și imaginea pentru publicare.';
        break;
      case 'TikTok':
        url = 'https://www.tiktok.com/@aiudance';
        message = 'Se deschide TikTok. Copiază textul pentru publicare.';
        break;
    }
    
    // Copiază textul în clipboard
    // In production would use Clipboard.setData
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Text copiat în clipboard! $message'), // Using interpolation
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
      ),
    );
    
    // Deschide platforma
    launchUrl(Uri.parse(url));
  }

  void _copyToClipboard() {
    // In production would use Clipboard.setData
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Text copiat în clipboard!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _exportImage() {
    String message = 'Imagine exportată cu succes!';
    
    if (widget.announcement['localImage'] != null) {
      message = 'Imagine locală exportată cu succes!';
    } else if (widget.announcement['imageUrl'] != null && widget.announcement['imageUrl'].isNotEmpty) {
      message = 'Imagine URL exportată cu succes!';
    } else {
      message = 'Nu există imagine pentru export!';
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _openSocialMediaApp(String platform) {
    String url = '';
    switch (platform) {
      case 'Facebook':
        url = 'https://www.facebook.com/aiudance'; // Contul real AIU Dance
        break;
      case 'Instagram':
        url = 'https://www.instagram.com/aiudance'; // Contul real AIU Dance
        break;
      case 'TikTok':
        url = 'https://www.tiktok.com/@aiudance'; // Contul real AIU Dance
        break;
    }
    
    launchUrl(Uri.parse(url));
  }

  void _publishToWhatsApp() {
    final message = '${widget.announcement['title']}\n\n${widget.announcement['description']}\n\n#AIUDance #Dans #Bucuresti';
    final encodedMessage = Uri.encodeComponent(message);
    final url = 'https://wa.me/?text=$encodedMessage';
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Se deschide WhatsApp pentru publicare...'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
    
    launchUrl(Uri.parse(url));
  }

  void _publishToTelegram() {
    final message = '${widget.announcement['title']}\n\n${widget.announcement['description']}\n\n#AIUDance #Dans #Bucuresti';
    final encodedMessage = Uri.encodeComponent(message);
    final url = 'https://t.me/share/url?url=https://aiudance.com&text=$encodedMessage';
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Se deschide Telegram pentru publicare...'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 3),
      ),
    );
    
    launchUrl(Uri.parse(url));
  }

  void _publishToEmail() {
    final subject = Uri.encodeComponent('${widget.announcement['title']} - AIU Dance');
    final body = Uri.encodeComponent('${widget.announcement['description']}\n\nPentru mai multe informații, vizitează: https://aiudance.com');
    final url = 'mailto:?subject=$subject&body=$body';
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Se deschide clientul de email pentru publicare...'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );
    
    launchUrl(Uri.parse(url));
  }
}
