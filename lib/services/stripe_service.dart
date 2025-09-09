// import 'package:flutter_stripe/flutter_stripe.dart'; // Temporar dezactivat pentru APK minimal
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';
import '../utils/platform_utils_simple.dart';

class StripeService {
  static const String stripePublishableKey = 'pk_test_51S2sC7QbMbo4QVSdgP2GHPuE8qs2WH2RKMFL9m2An7Zk4CKj1sfk0PfGZqpWIvJdsKS87DBSR66UT5ricYomME3900ghX2B75q';
  // 🔄 ÎNLOCUIEȘTE CU URL-UL REAL DIN AWS
  static const String stripeLambdaUrl = 'https://your-actual-lambda-url.execute-api.eu-west-1.amazonaws.com/prod/create-checkout';
  
  // Fallback pentru testare locală
  static const bool useMockMode = true; // Setează false când Lambda e gata

  static Future<void> initStripe() async {
    try {
      // Stripe functionality temporarily disabled for APK optimization
      print('[STRIPE] Service temporarily disabled for APK optimization');
      return;
      
      // Stripe.publishableKey = stripePublishableKey;
      // await Stripe.instance.applySettings();
      Logger.info('✅ Stripe initialized successfully');
    } catch (e) {
      Logger.error('Error initializing Stripe', e);
      // Don't rethrow on web platform - continue without Stripe
      if (e.toString().contains('Platform._operatingSystem')) {
        Logger.info('⚠️ Stripe not supported on web platform, continuing without it');
        return;
      }
      rethrow;
    }
  }

  // Course payment method
  Future<String?> createCourseCheckoutSession({
    required String userId,
    required String courseId,
    required double amount,
  }) async {
    try {
      if (useMockMode) {
        Logger.info('⚠️ Using mock course payment for testing');
        await Future.delayed(const Duration(seconds: 2));
        
        // Simulate successful payment and enrollment
        await _processCourseEnrollment(userId, courseId, amount, 'mock_payment_intent');
        
        return null; // No URL needed for mock
      }

      final response = await http.post(
        Uri.parse('$stripeLambdaUrl/course-checkout'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'amount': (amount * 100).round(), // Convert to cents
          'currency': 'ron',
          'user_id': userId,
          'course_id': courseId,
          'success_url': 'https://aiu-dance.com/payment/success',
          'cancel_url': 'https://aiu-dance.com/payment/cancel',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['checkout_url'] as String?;
      } else {
        Logger.error('Stripe checkout session creation failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      Logger.error('Error creating course checkout session: $e');
      return null;
    }
  }

  Future<void> launchCheckoutUrl(String url) async {
    try {
      Logger.info('Opening checkout URL: $url');
      
      // Pentru demo și testare, simulează procesul de plată
      if (useMockMode) {
        Logger.info('⚠️ Mock mode: Simulating successful payment');
        await Future.delayed(const Duration(seconds: 3));
        return;
      }
      
      // Deschide URL-ul pe toate platformele
      await PlatformUtils.openUrl(url);
    } catch (e) {
      Logger.error('Error launching checkout URL: $e');
      throw Exception('Nu s-a putut deschide pagina de plată: $e');
    }
  }

  Future<void> _processCourseEnrollment(
    String userId, 
    String courseId, 
    double amount, 
    String paymentIntentId,
  ) async {
    try {
      final supabase = Supabase.instance.client;

      // Check if already enrolled
      final existingEnrollment = await supabase
          .from('enrollments')
          .select('id')
          .eq('user_id', userId)
          .eq('course_id', courseId)
          .maybeSingle();

      if (existingEnrollment != null) {
        Logger.info('User already enrolled in course');
        return;
      }

      // Get course details
      final course = await supabase
          .from('courses')
          .select('title')
          .eq('id', courseId)
          .single();

      // Create enrollment
      await supabase.from('enrollments').insert({
        'user_id': userId,
        'course_id': courseId,
        'status': 'active',
        'paid': true,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Record transaction
      await supabase.from('wallet_transactions').insert({
        'user_id': userId,
        'type': 'debit',
        'amount': -amount, // Negative for payment
        'description': 'Plată curs: ${course['title']}',
        'metadata': {
          'course_id': courseId,
          'payment_intent_id': paymentIntentId,
          'payment_method': 'stripe',
        }.toString(),
        'created_at': DateTime.now().toIso8601String(),
      });

      Logger.info('Course enrollment and transaction recorded successfully');
    } catch (e) {
      Logger.error('Error processing course enrollment: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> createPaymentIntent({
    required int amount,
    required String currency,
    required String customerEmail,
  }) async {
    try {
      // Dacă e în mock mode, returnează mock response
      if (useMockMode) {
        Logger.info('⚠️ Using mock payment intent for testing');
        await Future.delayed(const Duration(seconds: 1));
        
        return {
          'client_secret': 'pi_mock_${DateTime.now().millisecondsSinceEpoch}_secret_mock',
          'payment_intent_id': 'pi_mock_${DateTime.now().millisecondsSinceEpoch}',
          'amount': amount,
          'currency': currency,
          'status': 'requires_payment_method',
        };
      }

      // COD REAL PENTRU LAMBDA
      Logger.info('🚀 Creating payment intent via Lambda: $stripeLambdaUrl');
      
      final response = await http.post(
        Uri.parse(stripeLambdaUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'amount': amount,
          'currency': currency,
          'customer_email': customerEmail,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - Lambda took too long to respond');
        },
      );

      Logger.info('📡 Lambda response status: ${response.statusCode}');
      Logger.info('📡 Lambda response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        Logger.info('✅ Payment intent created successfully');
        return data;
      } else if (response.statusCode == 0) {
        // CORS sau network error
        throw Exception('Network error - check CORS settings in AWS Lambda');
      } else {
        throw Exception('Lambda error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      Logger.error('Error creating payment intent', e);
      
      // Fallback la mock dacă Lambda eșuează
      if (!useMockMode) {
        Logger.info('🔄 Falling back to mock payment intent');
        await Future.delayed(const Duration(seconds: 1));
        
        return {
          'client_secret': 'pi_fallback_${DateTime.now().millisecondsSinceEpoch}_secret',
          'payment_intent_id': 'pi_fallback_${DateTime.now().millisecondsSinceEpoch}',
          'amount': amount,
          'currency': currency,
          'status': 'requires_payment_method',
        };
      }
      
      rethrow;
    }
  }

  static Future<void> initPaymentSheet({
    required String clientSecret,
    required String customerEphemeralKey,
    required String customerId,
  }) async {
    try {
      // Stripe functionality temporarily disabled for APK optimization
      print('[STRIPE] Payment sheet initialization disabled for APK optimization');
      return;
      
      // await Stripe.instance.initPaymentSheet(
      //   paymentSheetParameters: SetupPaymentSheetParameters(
      //     paymentIntentClientSecret: clientSecret,
      //     customerEphemeralKeySecret: customerEphemeralKey,
      //     customerId: customerId,
      //     merchantDisplayName: 'AIU Dance',
      //   ),
      // );
      Logger.info('✅ Payment sheet initialization skipped');
    } catch (e) {
      Logger.error('Error initializing payment sheet', e);
      rethrow;
    }
  }

  static Future<void> confirmPayment() async {
    try {
      // Stripe functionality temporarily disabled for APK optimization
      print('[STRIPE] Payment confirmation disabled for APK optimization');
      return;
      
      // await Stripe.instance.presentPaymentSheet();
      Logger.info('✅ Payment confirmation skipped');
    } catch (e) {
      Logger.error('Error confirming payment', e);
      rethrow;
    }
  }

  static Future<bool> completeWalletTopup({
    required String userId,
    required double amount,
    required String paymentIntentId,
  }) async {
    try {
      // Add transaction to database
      await Supabase.instance.client.from('wallet_transactions').insert({
        'user_id': userId,
        'amount': amount,
        'type': 'topup',
        'status': 'completed',
        'description': 'Top-up via Stripe',
        'payment_intent_id': paymentIntentId,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Update wallet balance
      await Supabase.instance.client.from('wallets').upsert({
        'user_id': userId,
        'balance': amount,
        'updated_at': DateTime.now().toIso8601String(),
      });

      Logger.info('✅ Wallet top-up completed');
      return true;
    } catch (e) {
      Logger.error('Error completing wallet top-up', e);
      return false;
    }
  }

  /// Creează Stripe checkout session pentru comandă bar
  static Future<String?> createBarOrderCheckoutSession({
    required String userId,
    required String orderId,
    required double amount,
  }) async {
    try {
      // Pentru bar orders, folosim întotdeauna mock pe web
      Logger.warning('Using mock checkout for bar order');
      return _createMockBarOrderSession(orderId, amount);
    } catch (e) {
      Logger.error('Error creating bar order checkout session: $e');
      return null;
    }
  }

  static String _createMockBarOrderSession(String orderId, double amount) {
    final sessionId = 'cs_bar_${orderId}_${DateTime.now().millisecondsSinceEpoch}';
    Logger.info('Mock bar order checkout session created: $sessionId for amount: $amount');
    return sessionId;
  }
}