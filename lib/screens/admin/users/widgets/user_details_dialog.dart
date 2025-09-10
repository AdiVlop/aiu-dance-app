import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Dialog pentru afișarea detaliilor complete ale unui utilizator
/// Permite editarea informațiilor și gestionarea statusului
class UserDetailsDialog extends StatefulWidget {
  final Map<String, dynamic> user;
  final Function(String) onStatusChanged;

  const UserDetailsDialog({
    super.key,
    required this.user,
    required this.onStatusChanged,
  });

  @override
  State<UserDetailsDialog> createState() => _UserDetailsDialogState();
}

class _UserDetailsDialogState extends State<UserDetailsDialog> {
  late String _currentStatus;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.user['status'];
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await widget.onStatusChanged(newStatus);
      setState(() {
        _currentStatus = newStatus;
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status actualizat cu succes!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare la actualizarea statusului: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final enrolledCourses = user['enrolledCourses'] as List<dynamic>? ?? [];
    final registrationDate = user['registrationDate'] as DateTime?;
    final lastLogin = user['lastLogin'] as DateTime?;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.6,
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: _currentStatus == 'active' 
                        ? Colors.green.shade100 
                        : Colors.red.shade100,
                    child: Text(
                      _getInitials(user['name']),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _currentStatus == 'active' 
                            ? Colors.green.shade700 
                            : Colors.red.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user['name'],
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user['email'],
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _currentStatus == 'active' 
                                ? Colors.green.shade100 
                                : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _currentStatus == 'active' 
                                  ? Colors.green.shade300 
                                  : Colors.red.shade300,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _currentStatus == 'active' 
                                    ? Icons.check_circle 
                                    : Icons.cancel,
                                size: 16,
                                color: _currentStatus == 'active' 
                                    ? Colors.green.shade600 
                                    : Colors.red.shade600,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _currentStatus == 'active' ? 'Activ' : 'Inactiv',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _currentStatus == 'active' 
                                      ? Colors.green.shade600 
                                      : Colors.red.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Contact Information
                    _buildSection(
                      title: 'Informații de contact',
                      icon: Icons.contact_phone,
                      children: [
                        _buildInfoRow('Email', user['email'], Icons.email),
                        if (user['phone'] != null)
                          _buildInfoRow('Telefon', user['phone'], Icons.phone),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Financial Information
                    _buildSection(
                      title: 'Informații financiare',
                      icon: Icons.account_balance_wallet,
                      children: [
                        _buildInfoRow(
                          'Sold portofel', 
                          '${user['walletBalance'].toStringAsFixed(2)} RON',
                          Icons.account_balance_wallet,
                        ),
                        _buildInfoRow(
                          'Total cheltuit', 
                          '${user['totalSpent'].toStringAsFixed(2)} RON',
                          Icons.attach_money,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Enrolled Courses
                    _buildSection(
                      title: 'Cursuri înscrise',
                      icon: Icons.school,
                      children: [
                        if (enrolledCourses.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'Nu este înscris la niciun curs',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        else
                          ...enrolledCourses.map<Widget>((course) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5E6EA),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFD199A3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.school,
                                    size: 16,
                                    color: const Color(0xFF7A0029),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      course,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF5C001F),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Account Information
                    _buildSection(
                      title: 'Informații cont',
                      icon: Icons.info,
                      children: [
                        if (registrationDate != null)
                          _buildInfoRow(
                            'Data înregistrării',
                            DateFormat('dd.MM.yyyy HH:mm').format(registrationDate),
                            Icons.person_add,
                          ),
                        if (lastLogin != null)
                          _buildInfoRow(
                            'Ultima conectare',
                            DateFormat('dd.MM.yyyy HH:mm').format(lastLogin),
                            Icons.login,
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : () {
                              final newStatus = _currentStatus == 'active' ? 'inactive' : 'active';
                              _updateStatus(newStatus);
                            },
                            icon: _isLoading 
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Icon(
                                    _currentStatus == 'active' ? Icons.cancel : Icons.check_circle,
                                  ),
                            label: Text(
                              _currentStatus == 'active' ? 'Dezactivează cont' : 'Activează cont',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _currentStatus == 'active' ? Colors.red : Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Închide'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.blue.shade600),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
  }
}




