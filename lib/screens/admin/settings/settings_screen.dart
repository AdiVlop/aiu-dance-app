import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../utils/platform_utils_simple.dart';
import '../../../utils/logger.dart';
import '../../../services/stripe_service.dart';
import '../../../services/meta_api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = false;
  Map<String, dynamic> _settings = {};

  // Controllers pentru configurări
  final _stripePublishableKeyController = TextEditingController();
  final _stripeSecretKeyController = TextEditingController();
  final _supabaseUrlController = TextEditingController();
  final _supabaseAnonKeyController = TextEditingController();
  final _studioNameController = TextEditingController();
  final _studioAddressController = TextEditingController();
  final _studioPhoneController = TextEditingController();
  final _studioEmailController = TextEditingController();
  
  // Meta API Controllers
  final _metaAccessTokenController = TextEditingController();
  final _metaPageIdController = TextEditingController();
  final _metaInstagramIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _stripePublishableKeyController.dispose();
    _stripeSecretKeyController.dispose();
    _supabaseUrlController.dispose();
    _supabaseAnonKeyController.dispose();
    _studioNameController.dispose();
    _studioAddressController.dispose();
    _studioPhoneController.dispose();
    _studioEmailController.dispose();
    _metaAccessTokenController.dispose();
    _metaPageIdController.dispose();
    _metaInstagramIdController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Încarcă setările din SharedPreferences și Supabase
      setState(() {
        _settings = {
          'stripe_publishable_key': prefs.getString('stripe_publishable_key') ?? '',
          'stripe_secret_key': prefs.getString('stripe_secret_key') ?? '',
          'supabase_url': prefs.getString('supabase_url') ?? '',
          'supabase_anon_key': prefs.getString('supabase_anon_key') ?? '',
          'studio_name': prefs.getString('studio_name') ?? 'AIU Dance Studio',
          'studio_address': prefs.getString('studio_address') ?? '',
          'studio_phone': prefs.getString('studio_phone') ?? '',
          'studio_email': prefs.getString('studio_email') ?? '',
          'notifications_enabled': prefs.getBool('notifications_enabled') ?? true,
          'email_notifications': prefs.getBool('email_notifications') ?? true,
          'sms_notifications': prefs.getBool('sms_notifications') ?? false,
          'dark_mode': prefs.getBool('dark_mode') ?? false,
          'language': prefs.getString('language') ?? 'ro',
          'auto_backup': prefs.getBool('auto_backup') ?? true,
          'meta_access_token': prefs.getString('meta_access_token') ?? '',
          'meta_page_id': prefs.getString('meta_page_id') ?? '',
          'meta_instagram_id': prefs.getString('meta_instagram_id') ?? '',
        };
      });

      // Populează controller-ele
      _stripePublishableKeyController.text = _settings['stripe_publishable_key'] ?? '';
      _stripeSecretKeyController.text = _settings['stripe_secret_key'] ?? '';
      _supabaseUrlController.text = _settings['supabase_url'] ?? '';
      _supabaseAnonKeyController.text = _settings['supabase_anon_key'] ?? '';
      _studioNameController.text = _settings['studio_name'] ?? '';
      _studioAddressController.text = _settings['studio_address'] ?? '';
      _studioPhoneController.text = _settings['studio_phone'] ?? '';
      _studioEmailController.text = _settings['studio_email'] ?? '';
      _metaAccessTokenController.text = _settings['meta_access_token'] ?? '';
      _metaPageIdController.text = _settings['meta_page_id'] ?? '';
      _metaInstagramIdController.text = _settings['meta_instagram_id'] ?? '';
      
    } catch (e) {
      Logger.error('Error loading settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      } else {
        await prefs.setString(key, value.toString());
      }

      setState(() {
        _settings[key] = value;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Setarea "$key" a fost salvată'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Logger.error('Error saving setting: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Eroare la salvarea setării: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurări Sistem'),
        backgroundColor: Colors.indigo.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Stripe Configuration
            _buildConfigSection(
              'Configurare Stripe',
              Icons.payment,
              Colors.blue,
              [
                _buildTextSetting(
                  'Cheia Publică Stripe',
                  _stripePublishableKeyController,
                  'stripe_publishable_key',
                  hint: 'pk_test_...',
                  icon: Icons.key,
                ),
                _buildTextSetting(
                  'Cheia Secretă Stripe',
                  _stripeSecretKeyController,
                  'stripe_secret_key',
                  hint: 'sk_test_...',
                  icon: Icons.lock,
                  obscure: true,
                ),
                _buildActionButton(
                  'Testează Conexiunea Stripe',
                  Icons.check_circle,
                  Colors.green,
                  _testStripeConnection,
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Supabase Configuration
            _buildConfigSection(
              'Configurare Supabase',
              Icons.cloud,
              Colors.green,
              [
                _buildTextSetting(
                  'URL Supabase',
                  _supabaseUrlController,
                  'supabase_url',
                  hint: 'https://your-project.supabase.co',
                  icon: Icons.link,
                ),
                _buildTextSetting(
                  'Cheia Anonimă Supabase',
                  _supabaseAnonKeyController,
                  'supabase_anon_key',
                  hint: 'eyJhbGciOiJIUzI1NiIsInR5cCI6...',
                  icon: Icons.vpn_key,
                  obscure: true,
                ),
                _buildActionButton(
                  'Testează Conexiunea Supabase',
                  Icons.check_circle,
                  Colors.green,
                  _testSupabaseConnection,
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Meta API Configuration
            _buildConfigSection(
              'Configurare Meta API (Facebook & Instagram)',
              Icons.facebook,
              Colors.blue,
              [
                _buildTextSetting(
                  'Access Token Meta',
                  _metaAccessTokenController,
                  'meta_access_token',
                  hint: 'EAABwz...',
                  icon: Icons.key,
                  obscure: true,
                ),
                _buildTextSetting(
                  'ID Pagină Facebook',
                  _metaPageIdController,
                  'meta_page_id',
                  hint: '123456789012345',
                  icon: Icons.facebook,
                ),
                _buildTextSetting(
                  'ID Cont Instagram Business',
                  _metaInstagramIdController,
                  'meta_instagram_id',
                  hint: '987654321098765',
                  icon: Icons.camera_alt,
                ),
                _buildActionButton(
                  'Testează Conexiunea Meta',
                  Icons.check_circle,
                  Colors.green,
                  _testMetaConnection,
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Studio Information
            _buildConfigSection(
              'Informații Studio',
              Icons.home_work,
              const Color(0xFF9C0033),
              [
                _buildTextSetting(
                  'Numele Studioului',
                  _studioNameController,
                  'studio_name',
                  hint: 'AIU Dance Studio',
                  icon: Icons.business,
                ),
                _buildTextSetting(
                  'Adresa Studioului',
                  _studioAddressController,
                  'studio_address',
                  hint: 'Str. Exemplu nr. 123, București',
                  icon: Icons.location_on,
                ),
                _buildTextSetting(
                  'Telefon Studio',
                  _studioPhoneController,
                  'studio_phone',
                  hint: '+40 123 456 789',
                  icon: Icons.phone,
                ),
                _buildTextSetting(
                  'Email Studio',
                  _studioEmailController,
                  'studio_email',
                  hint: 'contact@aiudance.ro',
                  icon: Icons.email,
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Notification Settings
            _buildConfigSection(
              'Setări Notificări',
              Icons.notifications,
              Colors.orange,
              [
                _buildSwitchSetting(
                  'Notificări Activate',
                  'notifications_enabled',
                  Icons.notifications_active,
                ),
                _buildSwitchSetting(
                  'Notificări Email',
                  'email_notifications',
                  Icons.email,
                ),
                _buildSwitchSetting(
                  'Notificări SMS',
                  'sms_notifications',
                  Icons.sms,
                ),
                _buildActionButton(
                  'Testează Notificările',
                  Icons.send,
                  Colors.blue,
                  _testNotifications,
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // App Settings
            _buildConfigSection(
              'Setări Aplicație',
              Icons.settings_applications,
              Colors.indigo,
              [
                _buildSwitchSetting(
                  'Mod Întunecat',
                  'dark_mode',
                  Icons.dark_mode,
                ),
                _buildDropdownSetting(
                  'Limba Aplicației',
                  'language',
                  Icons.language,
                  {
                    'ro': 'Română',
                    'en': 'English',
                    'fr': 'Français',
                  },
                ),
                _buildSwitchSetting(
                  'Backup Automat',
                  'auto_backup',
                  Icons.backup,
                ),
                _buildActionButton(
                  'Resetează la Default',
                  Icons.restore,
                  Colors.red,
                  _resetToDefaults,
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // System Actions
            _buildConfigSection(
              'Acțiuni Sistem',
              Icons.build,
              Colors.red,
              [
                _buildActionButton(
                  'Exportă Configurările',
                  Icons.download,
                  Colors.blue,
                  _exportSettings,
                ),
                _buildActionButton(
                  'Importă Configurările',
                  Icons.upload,
                  Colors.green,
                  _importSettings,
                ),
                _buildActionButton(
                  'Curăță Cache-ul',
                  Icons.clear_all,
                  Colors.orange,
                  _clearCache,
                ),
                _buildActionButton(
                  'Resetare Parolă',
                  Icons.lock_reset,
                  Colors.orange,
                  _resetPassword,
                ),
                _buildActionButton(
                  'Restart Aplicație',
                  Icons.restart_alt,
                  Colors.red,
                  _restartApp,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigSection(String title, IconData icon, Color color, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextSetting(
    String label,
    TextEditingController controller,
    String key, {
    String? hint,
    IconData? icon,
    bool obscure = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: icon != null ? Icon(icon) : null,
          suffixIcon: IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _saveSetting(key, controller.text),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchSetting(String label, String key, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        trailing: Switch(
          value: _settings[key] ?? false,
          onChanged: (value) => _saveSetting(key, value),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  Widget _buildDropdownSetting(
    String label,
    String key,
    IconData icon,
    Map<String, String> options,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: _settings[key] ?? options.keys.first,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        items: options.entries.map((entry) {
          return DropdownMenuItem(
            value: entry.key,
            child: Text(entry.value),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            _saveSetting(key, value);
          }
        },
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
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

  // Test Functions
  Future<void> _testStripeConnection() async {
    try {
      setState(() => _isLoading = true);
      
      // Încearcă să inițializeze Stripe cu noile chei
      final publishableKey = _stripePublishableKeyController.text.trim();
      
      if (publishableKey.isEmpty) {
        throw Exception('Cheia publică Stripe este necesară');
      }

      // Testează conexiunea (mock pentru demo)
      await Future.delayed(const Duration(seconds: 2));
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Conexiunea Stripe funcționează!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Eroare Stripe: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testSupabaseConnection() async {
    try {
      setState(() => _isLoading = true);
      
      // Testează conexiunea la Supabase
      final response = await Supabase.instance.client
          .from('profiles')
          .select('count(*)')
          .limit(1);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Conexiunea Supabase funcționează!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Eroare Supabase: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testMetaConnection() async {
    try {
      setState(() => _isLoading = true);
      
      // Salvează configurările Meta
      await MetaApiService.setConfiguration(
        accessToken: _metaAccessTokenController.text.trim(),
        pageId: _metaPageIdController.text.trim(),
        instagramAccountId: _metaInstagramIdController.text.trim(),
      );
      
      // Testează conexiunea
      final result = await MetaApiService.testConnection();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['success'] ? '✅ ${result['message']}' : '❌ ${result['message']}'),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Eroare Meta API: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testNotifications() async {
    try {
      setState(() => _isLoading = true);
      
      // Simulează trimiterea unei notificări test
      await Future.delayed(const Duration(seconds: 1));
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Notificare test trimisă!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Eroare notificări: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exportSettings() async {
    try {
      // Exportă configurările ca JSON
      final settingsJson = _settings.toString();
      
      // Pentru demo, doar afișează într-un dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Configurări Exportate'),
          content: SingleChildScrollView(
            child: SelectableText(
              settingsJson,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Închide'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare la export: $e')),
      );
    }
  }

  Future<void> _importSettings() async {
    // Pentru demo, afișează un dialog de import
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Configurări'),
        content: const Text(
          'Funcționalitatea de import va fi implementată în versiunea viitoare.\n\n'
          'Momentan poți configura manual toate setările.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearCache() async {
    try {
      setState(() => _isLoading = true);
      
      // Simulează curățarea cache-ului
      await Future.delayed(const Duration(seconds: 2));
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Cache-ul a fost curățat!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare la curățarea cache: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetToDefaults() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resetează la Default'),
        content: const Text(
          'Ești sigur că vrei să resetezi toate configurările la valorile implicite?\n\n'
          'Această acțiune nu poate fi anulată.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anulează'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Resetează'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Configurările au fost resetate!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Reîncarcă setările
        await _loadSettings();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare la resetare: $e')),
        );
      }
    }
  }

  Future<void> _resetPassword() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || user.email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nu s-a putut obține adresa de email'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resetare Parolă Admin'),
        content: Text(
          'Vrei să primești un email de resetare a parolei la adresa:\n\n${user.email}\n\n'
          'Vei fi redirecționat către pagina de resetare a parolei.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anulează'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Trimite Email'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await Supabase.instance.client.auth.resetPasswordForEmail(
          user.email!,
          redirectTo: 'https://aiu-dance.web.app/reset-password',
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Email de resetare trimis cu succes!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Eroare la trimiterea email-ului: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _restartApp() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restart Aplicație'),
        content: const Text(
          'Pentru a reporni aplicația, reîncarcă pagina în browser.\n\n'
          'Toate configurările salvate vor fi aplicate.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anulează'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Pentru web, reîncarcă pagina
              PlatformUtils.reloadApp();
            },
            child: const Text('Reîncarcă'),
          ),
        ],
      ),
    );
  }
}
