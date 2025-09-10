import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';

class AuthService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Get current user with profile fallback
  static Future<Map<String, dynamic>?> getCurrentUserWithProfile() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        Logger.info('No user logged in');
        return null;
      }

      // Try to get profile
      final profile = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profile == null) {
        // Check if this is the admin user and create profile
        if (user.email == 'adrian@payai-x.com' && user.id == '9195288e-d88b-4178-b970-b13a7ed445cf') {
          Logger.info('Creating admin profile for ${user.email}');
          try {
            final newProfile = await _client.from('profiles').insert({
              'id': user.id,
              'email': user.email,
              'full_name': 'Admin',
              'role': 'admin',
              'is_active': true,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            }).select().single();
            
            Logger.info('✅ Admin profile created successfully');
            return newProfile;
          } catch (e) {
            Logger.error('Error creating admin profile', e);
            return null;
          }
        }
        
        Logger.info('No profile found for user ${user.email}');
        return null;
      }

      return profile;
    } catch (e) {
      Logger.error('Error getting user with profile', e);
      return null;
    }
  }

  // Removed _createFallbackProfile method to prevent constraint violations

  /// Sign in with email and password
  static Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      Logger.info('Attempting to sign in with email: $email');
      
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      Logger.info('✅ Sign in successful for user: ${response.user?.email}');

      if (response.user != null) {
        // Try to get profile, but don't create if missing
        await getCurrentUserWithProfile();
      }

      return response;
    } on AuthException catch (e) {
      Logger.error('Auth error: ${e.message}', e);
      rethrow;
    } on AuthRetryableFetchException catch (e) {
      Logger.error('Network error during auth: ${e.message}', e);
      // For mobile apps, provide more specific error handling with retry
      if (e.message.contains('Failed host lookup') || e.message.contains('No address associated with hostname')) {
        Logger.info('Retrying login after network error...');
        await Future.delayed(const Duration(seconds: 2));
        try {
          // Retry once
          final retryResponse = await _client.auth.signInWithPassword(
            email: email,
            password: password,
          );
          Logger.info('✅ Retry successful for user: ${retryResponse.user?.email}');
          return retryResponse;
        } catch (retryError) {
          Logger.error('Retry failed: $retryError');
          throw Exception('Conexiune indisponibilă. Verifică internetul și încearcă din nou.');
        }
      }
      rethrow;
    } catch (e) {
      Logger.error('Unexpected error signing in', e);
      rethrow;
    }
  }

  /// Sign up with email and password
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
    String role = 'student',
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName ?? email.split('@')[0],
          'role': role,
        },
      );

      if (response.user != null) {
        // Create profile automatically
        try {
          await _client.from('profiles').insert({
            'id': response.user!.id,
            'email': email,
            'full_name': fullName ?? email.split('@')[0],
            'role': role,
            'is_active': true,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
          Logger.info('✅ User registered and profile created for ${email}');
        } catch (profileError) {
          Logger.error('Error creating profile', profileError);
          // Don't fail registration if profile creation fails
        }
      }

      return response;
    } catch (e) {
      Logger.error('Error signing up', e);
      rethrow;
    }
  }

  /// Reset password for user
  static Future<void> resetPassword(String email) async {
    try {
      Logger.info('Attempting to reset password for email: $email');
      
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'https://aiu-dance.web.app/reset-password',
      );
      
      Logger.info('✅ Password reset email sent to $email');
    } catch (e) {
      Logger.error('Error resetting password', e);
      rethrow;
    }
  }

  /// Sign out
  static Future<void> signOut() async {
    try {
      await _client.auth.signOut();
      Logger.info('User signed out');
    } catch (e) {
      Logger.error('Error signing out', e);
      rethrow;
    }
  }

  /// Get current user
  static User? getCurrentUser() {
    return _client.auth.currentUser;
  }

  /// Check if user is authenticated
  static bool isAuthenticated() {
    return _client.auth.currentUser != null;
  }

  /// Get user role
  static Future<String?> getUserRole() async {
    try {
      final profile = await getCurrentUserWithProfile();
      if (profile != null) {
        return profile['role'] as String?;
      }
      
      // If no profile, try to get role from user metadata
      final user = _client.auth.currentUser;
      if (user != null) {
        final role = user.userMetadata?['role'] as String?;
        if (role != null) {
          return role;
        }
      }
      
      // Default to student if no role found
      return 'student';
    } catch (e) {
      Logger.error('Error getting user role', e);
      return 'student'; // Default fallback
    }
  }

  /// Update user profile
  static Future<void> updateProfile({
    String? fullName,
    String? role,
  }) async {
    try {
      final user = getCurrentUser();
      if (user == null) throw Exception('User not logged in');

      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (fullName != null) updates['full_name'] = fullName;
      if (role != null) updates['role'] = role;

      await _client
          .from('profiles')
          .update(updates)
          .eq('id', user.id);

      Logger.info('Profile updated successfully');
    } catch (e) {
      Logger.error('Error updating profile', e);
      rethrow;
    }
  }
}
