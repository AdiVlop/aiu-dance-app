import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:flutter_stripe/flutter_stripe.dart'; // Temporar dezactivat
import 'config/supabase_config.dart';
import 'services/auth_service.dart';
import 'services/stripe_service.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/instructor/instructor_dashboard_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/courses/courses_screen.dart';
import 'screens/wallet/wallet_screen.dart';
import 'screens/wallet/wallet_topup_screen.dart';
import 'screens/qr_scanner/qr_scanner_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/student/courses/course_list_screen.dart';
import 'screens/student/courses/course_detail_screen.dart';
import 'screens/student/qr/qr_scanner_screen.dart' as student_qr;
import 'screens/admin/courses/admin_course_payments_screen.dart';
import 'screens/notifications/notification_list_screen.dart';
import 'screens/admin/qr/qr_attendance_admin_screen.dart';
import 'screens/qr_scanner/qr_checkin_scanner_screen.dart';
import 'screens/bar/bar_receipt_screen.dart';
import 'screens/instructor/instructor_course_create_screen.dart';
import 'screens/instructor/instructor_announcements_screen.dart';

// AIU Dance Brand Colors
class AIUColors {
  static const Color primary = Color(0xFF9C0033);
  static const Color secondary = Color(0xFFC00055);
  static const Color background = Color(0xFFF6F7FB);
  static const Color card = Colors.white;
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  
  static const LinearGradient brandGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// Gradient Button Widget
class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final EdgeInsetsGeometry? padding;
  
  const GradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AIUColors.brandGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AIUColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white),
                  const SizedBox(width: 8),
                ],
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🚀 Starting AIU Dance App...');
  
  // Initialize Supabase with mobile-specific configuration
  try {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        autoRefreshToken: true,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.info,
      ),
    );
    print('✅ Supabase initialized successfully');
  } catch (e) {
    print('❌ Supabase initialization failed: $e');
    // Continue without Supabase for now
  }
  
  // Initialize Stripe
  try {
    await StripeService.initStripe();
    print('✅ Stripe initialized successfully');
  } catch (e) {
    print('⚠️ Stripe initialization failed: $e');
    // Continue without Stripe for now
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AIU Dance',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF9C0033),
          primary: const Color(0xFF9C0033),
          secondary: const Color(0xFFC00055),
          surface: Colors.white,
          background: const Color(0xFFF6F7FB),
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F7FB),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF9C0033),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF111827)),
          bodyMedium: TextStyle(color: Color(0xFF6B7280)),
          bodySmall: TextStyle(color: Color(0xFF6B7280)),
          titleLarge: TextStyle(color: Color(0xFF111827)),
          titleMedium: TextStyle(color: Color(0xFF111827)),
          titleSmall: TextStyle(color: Color(0xFF111827)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF9C0033),
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF9C0033),
            side: const BorderSide(color: Color(0xFF9C0033)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF9C0033)),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/admin': (context) => const AdminDashboardScreen(),
        '/instructor': (context) => const InstructorDashboardScreen(),
        '/user': (context) => const DashboardScreen(),
        
        // Student modules:
        '/courses': (context) => const CoursesScreen(),
        '/courses/list': (context) => const CourseListScreen(),
        '/course/detail': (context) => const CourseDetailScreen(),
        '/wallet': (context) => const WalletScreen(),
        '/wallet/topup': (context) => const WalletTopupScreen(),
        '/qr': (context) => const QRScannerScreen(),
        '/scanner': (context) => const student_qr.QRScannerScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/notifications': (context) => const NotificationListScreen(),
        
        // Admin routes:
        '/admin/attendance': (context) => const AdminDashboardScreen(),
        '/admin/courses/payments': (context) => const AdminCoursePaymentsScreen(),
        '/admin/qr/attendance': (context) => const QRAttendanceAdminScreen(),
        
        // Instructor routes:
        '/instructor/courses/create': (context) => const InstructorCourseCreateScreen(),
        '/instructor/announcements': (context) => const InstructorAnnouncementsScreen(),
        
        // QR Scanner routes:
        '/scanner/qr': (context) => const QRCheckinScannerScreen(),
        
        // Bar routes:
        '/bar/receipt': (context) => const BarReceiptScreen(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    print('🌟 Initializing SplashScreen...');
    
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    
    _controller.forward();
    
    // Check if user is already authenticated
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Wait for splash animation
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    try {
      // Check if user is already signed in
      final user = Supabase.instance.client.auth.currentUser;
      print('🔍 Checking auth state: ${user?.email}');
      
      if (user != null) {
        // User is already signed in, get role and navigate
        final role = await AuthService.getUserRole();
        print('🔍 User role detected: $role');
        
        if (!mounted) return;
        
        switch (role) {
          case 'admin':
            print('✅ Auto-navigating to Admin Dashboard...');
                          Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
              );
            break;
          case 'instructor':
            print('✅ Auto-navigating to Instructor Dashboard...');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const InstructorDashboardScreen()),
            );
            break;
          case 'student':
          default:
            print('✅ Auto-navigating to Student Dashboard...');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
            );
        }
      } else {
        // User not signed in, go to login
        print('🔍 No user signed in, navigating to login...');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      print('❌ Error checking auth: $e');
      // Fallback to login on error
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('🎨 Building SplashScreen...');
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Color(0xFFFFF8E1), // amber.shade50
              Color(0xFFFFF3E0), // orange.shade50
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _animation.value,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF9C0033).withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Image.asset(
                          'assets/images/logo_aiu_dance.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.music_note,
                              size: 100,
                              color: const Color(0xFF9C0033),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 30),
              const Text(
                'AIU Dance',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF9C0033),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Aplicația ta de dans preferată',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 50),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF9C0033)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String _selectedRole = 'user'; // user, instructor, admin

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completează toate câmpurile'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await AuthService.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (response.user != null) {
        // Get user role with fallback
        final role = await AuthService.getUserRole();
        print('🔍 User role detected: $role');

        if (!mounted) return;

        if (role == null) {
          // Fallback dacă rolul lipsește
          print('⚠️ Rol lipsă. Redirecționez către Dashboard implicit.');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
          return;
        }

        switch (role) {
          case 'admin':
            print('✅ Navigating to Admin Dashboard...');
                          Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
              );
            break;
          case 'instructor':
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const InstructorDashboardScreen()),
            );
            break;
          case 'student':
          default:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
            );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare la autentificare: $e'),
            backgroundColor: Colors.red,
          ),
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Color(0xFFFFF8E1), // amber.shade50
              Color(0xFFFFF3E0), // orange.shade50
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                  // Logo
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(60),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF9C0033).withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Image.asset(
                        'assets/images/logo_aiu_dance.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // Title
                  const Text(
                    'AIU Dance',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF9C0033),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Conectează-te la contul tău',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Role Selection
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                const Text(
                          'Selectează tipul de cont:',
                  style: TextStyle(
                            fontSize: 16,
                    fontWeight: FontWeight.bold,
                            color: const Color(0xFF9C0033),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(
                              child: _buildRoleButton(
                                'Student',
                                'user',
                                Icons.person,
                                Colors.green,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildRoleButton(
                                'Instructor',
                                'instructor',
                                Icons.school,
                                Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildRoleButton(
                                'Admin',
                                'admin',
                                Icons.admin_panel_settings,
                                Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // Email Field
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Password Field
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Parolă',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    child: _isLoading
                        ? Container(
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: AIUColors.brandGradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(color: Colors.white),
                            ),
                          )
                        : GradientButton(
                            text: 'Conectează-te',
                            onPressed: _login,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Forgot Password Link
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Ai uitat parola?',
                      style: TextStyle(color: const Color(0xFF9C0033)),
                    ),
                  ),
                  
                  const SizedBox(height: 10),
                  
                  // Register Link
                  TextButton(
                  onPressed: () {
                      Navigator.pushNamed(context, '/register');
                  },
                    child: const Text(
                      'Nu ai cont? Înregistrează-te',
                      style: TextStyle(color: const Color(0xFF9C0033)),
                    ),
                ),
              ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton(String title, String role, IconData icon, Color color) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : color,
              size: 24,
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Dashboard-urile sunt acum în folderele lor separate:
// - AdminDashboardFixed: lib/screens/admin/admin_dashboard_screen.dart
// - InstructorDashboardScreen: lib/screens/instructor/instructor_dashboard_screen.dart  
// - DashboardScreen: lib/screens/dashboard/dashboard_screen.dart