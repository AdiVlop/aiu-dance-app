import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/stripe_service.dart';
import '../../../utils/logger.dart';

class CourseListScreen extends StatefulWidget {
  const CourseListScreen({super.key});

  @override
  State<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen> {
  List<Map<String, dynamic>> _courses = [];
  List<String> _enrolledCourseIds = [];
  bool _isLoading = true;
  final StripeService _stripeService = StripeService();

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    try {
      setState(() => _isLoading = true);
      
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // Load courses
      final coursesResponse = await Supabase.instance.client
          .from('courses')
          .select('*')
          .eq('is_active', true)
          .order('created_at', ascending: false);

      // Load user enrollments
      final enrollmentsResponse = await Supabase.instance.client
          .from('enrollments')
          .select('course_id')
          .eq('user_id', userId)
          .eq('status', 'active');

      setState(() {
        _courses = List<Map<String, dynamic>>.from(coursesResponse);
        _enrolledCourseIds = enrollmentsResponse
            .map<String>((e) => e['course_id'].toString())
            .toList();
        _isLoading = false;
      });

      Logger.info('Loaded ${_courses.length} courses, enrolled in ${_enrolledCourseIds.length}');
    } catch (e) {
      Logger.error('Error loading courses: $e');
      setState(() => _isLoading = false);
      _showErrorSnackBar('Eroare la încărcarea cursurilor');
    }
  }

  Future<void> _enrollInCourse(Map<String, dynamic> course) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        _showErrorSnackBar('Nu ești autentificat');
        return;
      }

      final courseId = course['id'];
      final price = (course['price'] ?? 0.0).toDouble();
      
      if (price == 0) {
        // Free course - direct enrollment
        await _enrollDirectly(userId, courseId);
        return;
      }

      // Show payment method selection dialog
      final paymentMethod = await _showPaymentMethodDialog(course);
      if (paymentMethod == null) return;

      await _processEnrollmentWithPayment(userId, courseId, course, paymentMethod, price);
    } catch (e) {
      Logger.error('Error enrolling in course: $e');
      _showErrorSnackBar('Eroare la înscrierea în curs');
    }
  }

  Future<String?> _showPaymentMethodDialog(Map<String, dynamic> course) async {
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selectează Metoda de Plată'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Curs: ${course['title']}'),
            Text('Preț: ${course['price']} RON'),
            const SizedBox(height: 16),
            const Text('Alege metoda de plată:'),
            const SizedBox(height: 12),
            _buildPaymentMethodOption('cash', 'Cash', 'Plată în numerar la sala de dans', Icons.money),
            _buildPaymentMethodOption('wallet', 'Wallet Digital', 'Plată online cu cardul', Icons.account_balance_wallet),
            _buildPaymentMethodOption('revolut', 'Revolut', 'Transfer prin Revolut', Icons.phone_android),
            _buildPaymentMethodOption('rate', 'Plată în Rate', 'Plată în rate (necesită aprobare)', Icons.schedule),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anulează'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodOption(String method, String title, String description, IconData icon) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF9C0033)),
        title: Text(title),
        subtitle: Text(description, style: const TextStyle(fontSize: 12)),
        onTap: () => Navigator.pop(context, method),
      ),
    );
  }

  Future<void> _processEnrollmentWithPayment(
    String userId, 
    String courseId, 
    Map<String, dynamic> course, 
    String paymentMethod, 
    double price
  ) async {
    try {
      // Create course payment record
      final paymentResponse = await Supabase.instance.client
          .from('course_payments')
          .insert({
            'user_id': userId,
            'course_id': courseId,
            'method': paymentMethod,
            'amount': price,
            'status': paymentMethod == 'rate' ? 'pending' : 'authorized',
            'authorized': paymentMethod != 'rate',
          })
          .select('id')
          .single();

      final paymentId = paymentResponse['id'];

      // Handle different payment methods
      switch (paymentMethod) {
        case 'wallet':
          await _processWalletPayment(userId, courseId, course, price, paymentId);
          break;
        case 'rate':
          await _processRatePayment(userId, courseId, paymentId);
          break;
        case 'cash':
        case 'revolut':
          await _processOfflinePayment(userId, courseId, paymentMethod, paymentId);
          break;
      }
    } catch (e) {
      Logger.error('Error processing enrollment with payment: $e');
      _showErrorSnackBar('Eroare la procesarea plății');
    }
  }

  Future<void> _processWalletPayment(String userId, String courseId, Map<String, dynamic> course, double price, String paymentId) async {
    try {
      _showLoadingDialog('Procesare plată wallet...');
      
      // Pentru demo și testare, simulează plata cu succes
      await Future.delayed(const Duration(seconds: 2));
      
      Navigator.pop(context); // Close loading dialog

      // Simulează plata cu succes
      await Supabase.instance.client
          .from('course_payments')
          .update({
            'status': 'paid',
            'authorized': true,
            'paid_at': DateTime.now().toIso8601String(),
          })
          .eq('id', paymentId);

      // Creează enrollment
      await _createEnrollment(userId, courseId, 'wallet', 'paid');
      
      // Creează tranzacția în wallet
      await Supabase.instance.client
          .from('wallet_transactions')
          .insert({
            'user_id': userId,
            'type': 'debit',
            'amount': price,
            'description': 'Plată curs: ${course['title']}',
            'metadata': {
              'course_id': courseId,
              'payment_id': paymentId,
              'payment_method': 'wallet_demo',
            },
          });

      _showSuccessSnackBar('Plată finalizată cu succes!\nAi fost înscris la curs.');
      await _loadCourses();
    } catch (e) {
      Navigator.pop(context); // Close loading dialog if open
      Logger.error('Error processing wallet payment: $e');
      
      // Update payment status to failed
      try {
        await Supabase.instance.client
            .from('course_payments')
            .update({'status': 'declined'})
            .eq('id', paymentId);
      } catch (updateError) {
        Logger.error('Error updating payment status: $updateError');
      }
      
      _showErrorSnackBar('Eroare la procesarea plății: ${e.toString()}');
    }
  }

  Future<void> _processRatePayment(String userId, String courseId, String paymentId) async {
    // Create enrollment with pending payment status
    await _createEnrollment(userId, courseId, 'rate', 'pending');
    
    _showSuccessSnackBar('Cererea de plată în rate a fost trimisă!\nAștepți aprobarea administratorului.');
    await _loadCourses();
  }

  Future<void> _processOfflinePayment(String userId, String courseId, String method, String paymentId) async {
    // Create enrollment with pending payment status
    await _createEnrollment(userId, courseId, method, 'pending');
    
    String message = method == 'cash' 
        ? 'Înscrierea a fost confirmată!\nPlata se va face în numerar la sala de dans.'
        : 'Înscrierea a fost confirmată!\nVei primi detaliile pentru transferul Revolut.';
    
    _showSuccessSnackBar(message);
    await _loadCourses();
  }

  Future<void> _createEnrollment(String userId, String courseId, String paymentMethod, String paymentStatus) async {
    // Check if already enrolled
    final existingEnrollment = await Supabase.instance.client
        .from('enrollments')
        .select('id')
        .eq('user_id', userId)
        .eq('course_id', courseId)
        .maybeSingle();

    if (existingEnrollment != null) {
      _showErrorSnackBar('Ești deja înscris la acest curs');
      return;
    }

    // Create enrollment
    await Supabase.instance.client
        .from('enrollments')
        .insert({
          'user_id': userId,
          'course_id': courseId,
          'status': 'active',
          'payment_method': paymentMethod,
          'payment_status': paymentStatus,
          'created_at': DateTime.now().toIso8601String(),
        });
  }

  Future<void> _enrollDirectly(String userId, String courseId) async {
    try {
      // Check if already enrolled
      final existingEnrollment = await Supabase.instance.client
          .from('enrollments')
          .select('id')
          .eq('user_id', userId)
          .eq('course_id', courseId)
          .maybeSingle();

      if (existingEnrollment != null) {
        _showErrorSnackBar('Ești deja înscris la acest curs');
        return;
      }

      // Create enrollment
      await Supabase.instance.client
          .from('enrollments')
          .insert({
            'user_id': userId,
            'course_id': courseId,
            'status': 'active',
            'paid': true,
            'created_at': DateTime.now().toIso8601String(),
          });

      _showSuccessSnackBar('Înscriere completă!');
      await _loadCourses();
    } catch (e) {
      Logger.error('Error in direct enrollment: $e');
      _showErrorSnackBar('Eroare la înscrierea directă');
    }
  }

  Future<bool> _showPaymentConfirmationDialog(Map<String, dynamic> course) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmare Plată'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Curs: ${course['title']}'),
            Text('Preț: ${course['price']} RON'),
            const SizedBox(height: 16),
            const Text('Dorești să continui cu plata?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anulează'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Plătește'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  void _navigateToCourseDetail(Map<String, dynamic> course) {
    Navigator.pushNamed(
      context, 
      '/course/detail',
      arguments: course,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cursuri Disponibile'),
        backgroundColor: const Color(0xFF9C0033),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadCourses,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _courses.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.school, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Nu sunt cursuri disponibile',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadCourses,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _courses.length,
                    itemBuilder: (context, index) {
                      final course = _courses[index];
                      final isEnrolled = _enrolledCourseIds.contains(course['id']);
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 2,
                        child: InkWell(
                          onTap: () => _navigateToCourseDetail(course),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Course Header
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        course['title'] ?? 'Fără titlu',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (isEnrolled)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.check, 
                                                 color: Colors.green, size: 16),
                                            SizedBox(width: 4),
                                            Text(
                                              'Înscris',
                                              style: TextStyle(
                                                color: Colors.green,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                
                                const SizedBox(height: 8),
                                
                                // Course Details
                                Text(
                                  course['category'] ?? 'Categorie necunoscută',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                                
                                if (course['description'] != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    course['description'],
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                
                                const SizedBox(height: 12),
                                
                                // Course Info Row
                                Row(
                                  children: [
                                    Icon(Icons.people, 
                                         color: Colors.grey.shade600, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Capacitate: ${course['capacity'] ?? 'N/A'}',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const Spacer(),
                                    if (course['instructor'] != null) ...[
                                      Icon(Icons.person, 
                                           color: Colors.grey.shade600, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        course['instructor'],
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Action Button
                                SizedBox(
                                  width: double.infinity,
                                  child: isEnrolled
                                      ? OutlinedButton.icon(
                                          onPressed: () => _navigateToCourseDetail(course),
                                          icon: const Icon(Icons.visibility),
                                          label: const Text('Vezi Detalii'),
                                        )
                                      : ElevatedButton.icon(
                                          onPressed: () => _enrollInCourse(course),
                                          icon: const Icon(Icons.school),
                                          label: Text(
                                            course['price'] == null || course['price'] == 0
                                                ? 'Înscrie-te Gratuit'
                                                : 'Înscrie-te (${course['price']} RON)',
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF9C0033),
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}
