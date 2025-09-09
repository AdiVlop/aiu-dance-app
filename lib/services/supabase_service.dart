import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../utils/logger.dart';

class SupabaseService extends ChangeNotifier {
  final _client = Supabase.instance.client;
  
  // User state
  User? _currentUser;
  bool _isLoading = false;
  
  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;

  SupabaseService() {
    _initializeAuthListener();
  }

  void _initializeAuthListener() {
    _client.auth.onAuthStateChange.listen((data) {
      _currentUser = data.session?.user;
      notifyListeners();
    });
  }

  Future<AuthResponse> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      _currentUser = response.user;
      return response;
    } catch (e) {
      Logger.error('Login error', e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _client.auth.signOut();
      _currentUser = null;
    } catch (e) {
      Logger.error('Sign out error', e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool isUserLoggedIn() {
    return _currentUser != null;
  }

  String? getUserEmail() {
    return _currentUser?.email;
  }

  Future<Map<String, dynamic>?> getUser() async {
    if (_currentUser == null) return null;
    
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', _currentUser!.id)
          .maybeSingle();
      return response;
    } catch (e) {
      Logger.error('Error getting user profile', e);
      return null;
    }
  }

  Future<AuthResponse> register(String email, String password, Map<String, dynamic> userData) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: userData,
      );
      return response;
    } catch (e) {
      Logger.error('Registration error', e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> getWallet(String userId) async {
    try {
      final response = await _client
          .from('wallets')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      return response;
    } catch (e) {
      Logger.error('Error getting wallet', e);
      return null;
    }
  }

  Future<List<dynamic>> getWalletTransactions(String userId) async {
    try {
      final response = await _client
          .from('wallet_transactions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return response;
    } catch (e) {
      Logger.error('Error getting wallet transactions', e);
      return [];
    }
  }

  Future<void> updateWallet(String userId, double newBalance) async {
    try {
      await _client
          .from('wallets')
          .update({'balance': newBalance})
          .eq('user_id', userId);
      notifyListeners();
    } catch (e) {
      Logger.error('Error updating wallet', e);
      rethrow;
    }
  }

  Future<void> createWalletTransaction(Map<String, dynamic> transactionData) async {
    try {
      await _client.from('wallet_transactions').insert(transactionData);
      notifyListeners();
    } catch (e) {
      Logger.error('Error creating wallet transaction', e);
      rethrow;
    }
  }

  Future<bool> checkInQR(String qrData, String userId) async {
    try {
      // Aici ar trebui să implementezi logica de validare QR
      // și înregistrare prezență
      return true;
    } catch (e) {
      Logger.error('Error checking in with QR', e);
      return false;
    }
  }

  Future<List<dynamic>> getCourses() async {
    try {
      final response = await _client.from('courses').select();
      return response;
    } catch (e) {
      Logger.error('Error getting courses', e);
      return [];
    }
  }

  Future<void> submitBarOrder(Map<String, dynamic> orderData) async {
    try {
      await _client.from('bar_orders').insert(orderData);
      notifyListeners();
    } catch (e) {
      Logger.error('Error submitting bar order', e);
      rethrow;
    }
  }

  // Additional methods for AIU Dance app
  Future<List<dynamic>> getBarMenu() async {
    try {
      final response = await _client.from('bar_menu').select().eq('available', true);
      return response;
    } catch (e) {
      Logger.error('Error getting bar menu', e);
      return [];
    }
  }

  Future<List<dynamic>> getBarOrders() async {
    try {
      final response = await _client
          .from('bar_orders')
          .select()
          .order('created_at', ascending: false);
      return response;
    } catch (e) {
      Logger.error('Error getting bar orders', e);
      return [];
    }
  }

  Future<List<dynamic>> getAttendance() async {
    try {
      final response = await _client
          .from('attendance')
          .select()
          .order('timestamp', ascending: false);
      return response;
    } catch (e) {
      Logger.error('Error getting attendance', e);
      return [];
    }
  }

  Future<void> recordAttendance(Map<String, dynamic> attendanceData) async {
    try {
      await _client.from('attendance').insert(attendanceData);
      notifyListeners();
    } catch (e) {
      Logger.error('Error recording attendance', e);
      rethrow;
    }
  }

  Future<List<dynamic>> getUsers() async {
    try {
      final response = await _client.from('profiles').select();
      return response;
    } catch (e) {
      Logger.error('Error getting users', e);
      return [];
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return response;
    } catch (e) {
      Logger.error('Error getting user profile', e);
      return null;
    }
  }

  Future<void> updateUserProfile(String userId, Map<String, dynamic> profileData) async {
    try {
      await _client
          .from('profiles')
          .update(profileData)
          .eq('id', userId);
      notifyListeners();
    } catch (e) {
      Logger.error('Error updating user profile', e);
      rethrow;
    }
  }

  Future<List<dynamic>> getEnrollments() async {
    try {
      final response = await _client
          .from('enrollments')
          .select()
          .order('enrolled_at', ascending: false);
      return response;
    } catch (e) {
      Logger.error('Error getting enrollments', e);
      return [];
    }
  }

  Future<void> enrollInCourse(Map<String, dynamic> enrollmentData) async {
    try {
      await _client.from('enrollments').insert(enrollmentData);
      notifyListeners();
    } catch (e) {
      Logger.error('Error enrolling in course', e);
      rethrow;
    }
  }

  Future<void> updateWalletBalance(String userId, double newBalance) async {
    try {
      await _client
          .from('wallets')
          .update({'balance': newBalance})
          .eq('user_id', userId);
      notifyListeners();
    } catch (e) {
      Logger.error('Error updating wallet balance', e);
      rethrow;
    }
  }

  // Simplified real-time subscriptions using streams
  Stream<List<Map<String, dynamic>>> subscribeToBarOrders() {
    try {
      return _client
          .from('bar_orders')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .map((response) => List<Map<String, dynamic>>.from(response));
    } catch (e) {
      Logger.error('Error subscribing to bar orders', e);
      return Stream.value([]);
    }
  }

  Stream<List<Map<String, dynamic>>> subscribeToAttendance() {
    try {
      return _client
          .from('attendance')
          .stream(primaryKey: ['id'])
          .order('timestamp', ascending: false)
          .map((response) => List<Map<String, dynamic>>.from(response));
    } catch (e) {
      Logger.error('Error subscribing to attendance', e);
      return Stream.value([]);
    }
  }

  Stream<List<Map<String, dynamic>>> subscribeToCourses() {
    try {
      return _client
          .from('courses')
          .stream(primaryKey: ['id'])
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .map((response) => List<Map<String, dynamic>>.from(response));
    } catch (e) {
      Logger.error('Error subscribing to courses', e);
      return Stream.value([]);
    }
  }

  @override
  void dispose() {
    // Clean up any subscriptions if needed
    super.dispose();
  }
}








