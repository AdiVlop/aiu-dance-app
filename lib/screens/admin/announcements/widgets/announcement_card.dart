import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AnnouncementCard extends StatelessWidget {
  final Map<String, dynamic> announcement;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final Function(String platform)? onShare;

  const AnnouncementCard({
    super.key,
    required this.announcement,
    this.onEdit,
    this.onDelete,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final title = announcement['title'] ?? 'Fără titlu';
    final content = announcement['content'] ?? '';
    final mediaUrl = announcement['media_url'] as String?;
    final mediaType = announcement['media_type'] as String?;
    final visibleTo = announcement['visible_to'] ?? 'all';
    final isPublished = announcement['is_published'] ?? true;
    final createdAt = announcement['created_at'] as String?;
    
    DateTime? createdDate;
    if (createdAt != null) {
      try {
        createdDate = DateTime.parse(createdAt);
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
          // Header with title and status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isPublished ? Colors.green.shade50 : Colors.orange.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusChip(isPublished),
                const SizedBox(width: 8),
                _buildVisibilityChip(visibleTo),
              ],
            ),
          ),

          // Media section
          if (mediaUrl != null && mediaUrl.isNotEmpty)
            _buildMediaSection(mediaUrl, mediaType),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content,
                  style: const TextStyle(fontSize: 14),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                
                // Date and course info
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      createdDate != null 
                          ? DateFormat('dd MMM yyyy, HH:mm').format(createdDate)
                          : 'Data necunoscută',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (announcement['courses'] != null) ...[
                      const SizedBox(width: 16),
                      Icon(Icons.school, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          announcement['courses']['title'] ?? 'Curs necunoscut',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                // Share buttons
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () => _showShareDialog(context),
                  tooltip: 'Partajează',
                ),
                IconButton(
                  icon: Icon(Icons.facebook, color: Colors.blue.shade700),
                  onPressed: () => onShare?.call('facebook'),
                  tooltip: 'Facebook',
                ),
                IconButton(
                  icon: Icon(Icons.message, color: Colors.green.shade600),
                  onPressed: () => onShare?.call('whatsapp'),
                  tooltip: 'WhatsApp',
                ),
                
                const Spacer(),
                
                // Edit and Delete buttons
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: onEdit,
                  tooltip: 'Editează',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: onDelete,
                  tooltip: 'Șterge',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(bool isPublished) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPublished ? Colors.green : Colors.orange,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isPublished ? 'Publicat' : 'Draft',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildVisibilityChip(String visibleTo) {
    Color color;
    String text;
    
    switch (visibleTo) {
      case 'student':
        color = Colors.blue;
        text = 'Studenți';
        break;
      case 'instructor':
        color = Colors.purple;
        text = 'Instructori';
        break;
      default:
        color = Colors.grey;
        text = 'Toți';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMediaSection(String mediaUrl, String? mediaType) {
    if (mediaType == 'image') {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
        ),
        child: Image.network(
          mediaUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey.shade200,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.broken_image,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Imaginea nu poate fi încărcată',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.grey.shade100,
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
        ),
      );
    } else if (mediaType == 'video') {
      return Container(
        height: 200,
        width: double.infinity,
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.play_circle_outline,
              size: 64,
              color: Colors.white.withOpacity(0.8),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Video',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _showShareDialog(BuildContext context) {
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
              'Partajează anunțul',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.spaceEvenly,
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildShareOption(
                  context,
                  'Facebook',
                  Icons.facebook,
                  Colors.blue.shade700,
                  () => onShare?.call('facebook'),
                ),
                _buildShareOption(
                  context,
                  'Instagram',
                  Icons.camera_alt,
                  Colors.purple.shade600,
                  () => onShare?.call('instagram'),
                ),
                _buildShareOption(
                  context,
                  'TikTok',
                  Icons.video_call,
                  Colors.black,
                  () => onShare?.call('tiktok'),
                ),
                _buildShareOption(
                  context,
                  'WhatsApp',
                  Icons.message,
                  Colors.green.shade600,
                  () => onShare?.call('whatsapp'),
                ),
                _buildShareOption(
                  context,
                  'Telegram',
                  Icons.send,
                  Colors.blue.shade400,
                  () => onShare?.call('telegram'),
                ),
                _buildShareOption(
                  context,
                  'General',
                  Icons.share,
                  Colors.grey.shade600,
                  () => onShare?.call('general'),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback? onTap,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap?.call();
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}