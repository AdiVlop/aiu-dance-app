import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aiu_dance/utils/logger.dart';
import 'package:aiu_dance/services/stripe_service.dart';

class BarPaymentService {
  static final _supabase = Supabase.instance.client;

  /// Creează o comandă bar cu metoda de plată selectată
  static Future<Map<String, dynamic>> createBarOrder({
    required String userId,
    required String productId,
    required String productName,
    required int quantity,
    required double totalPrice,
    required String paymentMethod,
  }) async {
    try {
      Logger.info('Creating bar order for user $userId');

      // 1. Creează comanda în bar_orders
      final orderData = {
        'user_id': userId,
        'product_name': productName,
        'quantity': quantity,
        'total_price': totalPrice,
        'payment_method': paymentMethod,
        'payment_status': 'pending',
        'status': 'pending',
        'items': jsonEncode([{
          'product_id': productId,
          'product_name': productName,
          'quantity': quantity,
          'unit_price': totalPrice / quantity,
          'total_price': totalPrice,
        }]),
        'metadata': {
          'created_via': 'app',
          'payment_initiated_at': DateTime.now().toIso8601String(),
        },
      };

      final orderResponse = await _supabase
          .from('bar_orders')
          .insert(orderData)
          .select()
          .single();

      Logger.info('Bar order created: ${orderResponse['id']}');

      // 2. Procesează plata în funcție de metodă
      switch (paymentMethod.toLowerCase()) {
        case 'wallet':
          return await _processWalletPayment(orderResponse, totalPrice);
        case 'cash':
          return await _processCashPayment(orderResponse);
        case 'revolut':
          return await _processRevolutPayment(orderResponse);
        case 'qr':
          return await _processQRPayment(orderResponse);
        default:
          return {
            'success': false,
            'message': 'Metodă de plată necunoscută: $paymentMethod',
            'order_id': orderResponse['id'],
          };
      }
    } catch (e) {
      Logger.error('Error creating bar order: $e');
      return {
        'success': false,
        'message': 'Eroare la crearea comenzii: ${e.toString()}',
      };
    }
  }

  /// Procesează plata prin wallet (Stripe)
  static Future<Map<String, dynamic>> _processWalletPayment(
    Map<String, dynamic> order,
    double amount,
  ) async {
    try {
      // Inițiază plata Stripe
      final stripeResult = await StripeService.createBarOrderCheckoutSession(
        userId: order['user_id'],
        orderId: order['id'],
        amount: amount,
      );

      if (stripeResult != null) {
        // Actualizează comanda cu informațiile Stripe
        await _supabase
            .from('bar_orders')
            .update({
              'metadata': {
                ...order['metadata'],
                'stripe_session_id': stripeResult,
                'payment_initiated_at': DateTime.now().toIso8601String(),
              },
            })
            .eq('id', order['id']);

        return {
          'success': true,
          'message': 'Plata prin wallet a fost inițiată',
          'order_id': order['id'],
          'stripe_session_id': stripeResult,
          'requires_payment': true,
        };
      } else {
        return {
          'success': false,
          'message': 'Eroare la inițierea plății Stripe',
          'order_id': order['id'],
        };
      }
    } catch (e) {
      Logger.error('Error processing wallet payment: $e');
      return {
        'success': false,
        'message': 'Eroare la plata wallet: ${e.toString()}',
        'order_id': order['id'],
      };
    }
  }

  /// Procesează plata cash (așteaptă confirmarea barmanului)
  static Future<Map<String, dynamic>> _processCashPayment(
    Map<String, dynamic> order,
  ) async {
    try {
      await _supabase
          .from('bar_orders')
          .update({
            'payment_status': 'pending',
            'status': 'awaiting_payment',
            'metadata': {
              ...order['metadata'],
              'payment_method_confirmed': 'cash',
              'awaiting_bartender_confirmation': true,
            },
          })
          .eq('id', order['id']);

      return {
        'success': true,
        'message': 'Comanda a fost plasată. Plătește la bar și așteaptă confirmarea.',
        'order_id': order['id'],
        'requires_bartender_confirmation': true,
      };
    } catch (e) {
      Logger.error('Error processing cash payment: $e');
      return {
        'success': false,
        'message': 'Eroare la procesarea plății cash: ${e.toString()}',
        'order_id': order['id'],
      };
    }
  }

  /// Procesează plata Revolut (link către transfer)
  static Future<Map<String, dynamic>> _processRevolutPayment(
    Map<String, dynamic> order,
  ) async {
    try {
      // Generează link Revolut (în practică, acesta ar fi un link real)
      final revolutLink = 'https://revolut.me/aiudance/${order['total_price'].toStringAsFixed(2)}';

      await _supabase
          .from('bar_orders')
          .update({
            'payment_status': 'pending',
            'status': 'awaiting_payment',
            'metadata': {
              ...order['metadata'],
              'revolut_link': revolutLink,
              'payment_method_confirmed': 'revolut',
            },
          })
          .eq('id', order['id']);

      return {
        'success': true,
        'message': 'Transferă suma prin Revolut și așteaptă confirmarea.',
        'order_id': order['id'],
        'revolut_link': revolutLink,
        'requires_external_payment': true,
      };
    } catch (e) {
      Logger.error('Error processing Revolut payment: $e');
      return {
        'success': false,
        'message': 'Eroare la procesarea plății Revolut: ${e.toString()}',
        'order_id': order['id'],
      };
    }
  }

  /// Procesează plata prin QR (generează QR pentru client)
  static Future<Map<String, dynamic>> _processQRPayment(
    Map<String, dynamic> order,
  ) async {
    try {
      // Generează QR code pentru plată
      final qrPayload = {
        'type': 'bar_payment',
        'order_id': order['id'],
        'amount': order['total_price'],
        'currency': 'RON',
        'expires_at': DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
      };

      final qrResponse = await _supabase
          .from('qr_codes')
          .insert({
            'code': 'BAR_PAYMENT_${order['id']}_${DateTime.now().millisecondsSinceEpoch}',
            'type': 'bar_payment',
            'title': 'Plată ${order['product_name']} - ${order['total_price']} RON',
            'data': qrPayload,
            'is_active': true,
            'expires_at': DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
            'created_by': order['user_id'],
          })
          .select()
          .single();

      // Actualizează comanda cu QR code-ul
      await _supabase
          .from('bar_orders')
          .update({
            'qr_code_id': qrResponse['id'],
            'payment_status': 'pending',
            'status': 'awaiting_payment',
            'metadata': {
              ...order['metadata'],
              'qr_code_generated': true,
              'qr_expires_at': qrPayload['expires_at'],
            },
          })
          .eq('id', order['id']);

      return {
        'success': true,
        'message': 'QR code generat pentru plată. Scanează pentru a plăti.',
        'order_id': order['id'],
        'qr_code': jsonEncode(qrPayload),
        'qr_code_id': qrResponse['id'],
        'requires_qr_scan': true,
      };
    } catch (e) {
      Logger.error('Error processing QR payment: $e');
      return {
        'success': false,
        'message': 'Eroare la generarea QR pentru plată: ${e.toString()}',
        'order_id': order['id'],
      };
    }
  }

  /// Confirmă plata unei comenzi (pentru barman/admin)
  static Future<Map<String, dynamic>> confirmPayment({
    required String orderId,
    required String confirmedBy,
    String? notes,
  }) async {
    try {
      // 1. Obține comanda
      final order = await _supabase
          .from('bar_orders')
          .select('*')
          .eq('id', orderId)
          .single();

      if (order['payment_status'] == 'paid') {
        return {
          'success': false,
          'message': 'Comanda a fost deja plătită',
        };
      }

      // 2. Actualizează statusul comenzii
      await _supabase
          .from('bar_orders')
          .update({
            'payment_status': 'paid',
            'status': 'completed',
            'payment_completed_at': DateTime.now().toIso8601String(),
            'metadata': {
              ...order['metadata'],
              'confirmed_by': confirmedBy,
              'confirmation_notes': notes,
              'confirmed_at': DateTime.now().toIso8601String(),
            },
          })
          .eq('id', orderId);

      // 3. Creează tranzacția în wallet_transactions dacă e wallet payment
      if (order['payment_method'] == 'wallet') {
        await _supabase
            .from('wallet_transactions')
            .insert({
              'user_id': order['user_id'],
              'type': 'debit',
              'amount': -order['total_price'],
              'description': 'Plată bar: ${order['product_name']}',
              'metadata': {
                'bar_order_id': orderId,
                'payment_method': 'wallet',
                'confirmed_by': confirmedBy,
              },
            });
      }

      Logger.info('Payment confirmed for order: $orderId');

      return {
        'success': true,
        'message': 'Plata a fost confirmată cu succes',
        'order_id': orderId,
        'receipt_url': order['receipt_url'],
      };
    } catch (e) {
      Logger.error('Error confirming payment: $e');
      return {
        'success': false,
        'message': 'Eroare la confirmarea plății: ${e.toString()}',
      };
    }
  }

  /// Obține comenzile bar cu statusurile de plată
  static Future<List<Map<String, dynamic>>> getBarOrdersWithPayments({
    String? status,
    String? paymentStatus,
    int limit = 50,
  }) async {
    try {
      var query = _supabase
          .from('bar_orders')
          .select('''
            *,
            user:profiles!bar_orders_user_id_fkey(full_name, email),
            qr_code:qr_codes!bar_orders_qr_code_id_fkey(code, is_active, expires_at)
          ''');

      if (status != null) {
        query = query.eq('status', status);
      }

      if (paymentStatus != null) {
        query = query.eq('payment_status', paymentStatus);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      Logger.error('Error loading bar orders: $e');
      return [];
    }
  }

  /// Generează QR code pentru o comandă existentă (pentru barman)
  static Future<Map<String, dynamic>> generatePaymentQR({
    required String orderId,
    required String generatedBy,
  }) async {
    try {
      // 1. Obține comanda
      final order = await _supabase
          .from('bar_orders')
          .select('*')
          .eq('id', orderId)
          .single();

      if (order['payment_status'] == 'paid') {
        return {
          'success': false,
          'message': 'Comanda a fost deja plătită',
        };
      }

      // 2. Dezactivează QR-urile vechi pentru această comandă
      if (order['qr_code_id'] != null) {
        await _supabase
            .from('qr_codes')
            .update({'is_active': false})
            .eq('id', order['qr_code_id']);
      }

      // 3. Generează QR nou
      final qrPayload = {
        'type': 'bar_payment',
        'order_id': orderId,
        'amount': order['total_price'],
        'currency': 'RON',
        'product_name': order['product_name'],
        'quantity': order['quantity'],
        'generated_by': generatedBy,
        'expires_at': DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
      };

      final qrResponse = await _supabase
          .from('qr_codes')
          .insert({
            'code': 'BAR_PAYMENT_${orderId}_${DateTime.now().millisecondsSinceEpoch}',
            'type': 'bar_payment',
            'title': 'Plată ${order['product_name']} - ${order['total_price']} RON',
            'data': qrPayload,
            'is_active': true,
            'expires_at': DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
            'created_by': generatedBy,
          })
          .select()
          .single();

      // 4. Actualizează comanda cu noul QR
      await _supabase
          .from('bar_orders')
          .update({
            'qr_code_id': qrResponse['id'],
            'metadata': {
              ...order['metadata'],
              'qr_generated_by': generatedBy,
              'qr_generated_at': DateTime.now().toIso8601String(),
            },
          })
          .eq('id', orderId);

      return {
        'success': true,
        'message': 'QR code generat cu succes pentru plată',
        'order_id': orderId,
        'qr_code': jsonEncode(qrPayload),
        'qr_code_id': qrResponse['id'],
        'qr_data': qrPayload,
      };
    } catch (e) {
      Logger.error('Error generating payment QR: $e');
      return {
        'success': false,
        'message': 'Eroare la generarea QR pentru plată: ${e.toString()}',
      };
    }
  }

  /// Procesează scanarea QR de plată
  static Future<Map<String, dynamic>> processPaymentQRScan({
    required String qrData,
    required String scannedBy,
  }) async {
    try {
      // 1. Parsează QR data
      final payload = jsonDecode(qrData) as Map<String, dynamic>;

      if (payload['type'] != 'bar_payment') {
        return {
          'success': false,
          'message': 'Acest QR nu este pentru plata bar',
        };
      }

      final orderId = payload['order_id'];

      // 2. Verifică dacă QR-ul nu a expirat
      final expiresAt = DateTime.tryParse(payload['expires_at'] ?? '');
      if (expiresAt != null && DateTime.now().isAfter(expiresAt)) {
        return {
          'success': false,
          'message': 'QR code-ul a expirat',
        };
      }

      // 3. Confirmă plata
      return await confirmPayment(
        orderId: orderId,
        confirmedBy: scannedBy,
        notes: 'Plată confirmată prin scanare QR',
      );
    } catch (e) {
      Logger.error('Error processing payment QR scan: $e');
      return {
        'success': false,
        'message': 'Eroare la procesarea QR de plată: ${e.toString()}',
      };
    }
  }

  /// Obține chitanța pentru o comandă
  static Future<Map<String, dynamic>?> getReceiptForOrder(String orderId) async {
    try {
      final response = await _supabase
          .from('bar_receipts')
          .select('''
            *,
            bar_order:bar_orders!bar_receipts_bar_order_id_fkey(
              id,
              user_id,
              product_name,
              quantity,
              total_price,
              payment_method,
              payment_status,
              created_at,
              user:profiles!bar_orders_user_id_fkey(full_name, email)
            )
          ''')
          .eq('bar_order_id', orderId)
          .maybeSingle();

      return response;
    } catch (e) {
      Logger.error('Error loading receipt: $e');
      return null;
    }
  }

  /// Obține statistici pentru plățile bar
  static Future<Map<String, dynamic>> getBarPaymentStats() async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];

      // Total comenzi
      final totalOrders = await _supabase
          .from('bar_orders')
          .select('id');

      // Comenzi plătite
      final paidOrders = await _supabase
          .from('bar_orders')
          .select('id')
          .eq('payment_status', 'paid');

      // Comenzi în așteptare
      final pendingOrders = await _supabase
          .from('bar_orders')
          .select('id')
          .eq('payment_status', 'pending');

      // Vânzări astăzi
      final todayOrders = await _supabase
          .from('bar_orders')
          .select('total_price')
          .eq('payment_status', 'paid')
          .gte('created_at', '${today}T00:00:00.000Z')
          .lt('created_at', '${today}T23:59:59.999Z');

      final todayRevenue = todayOrders.fold<double>(
        0.0, 
        (sum, order) => sum + (double.tryParse(order['total_price'].toString()) ?? 0.0)
      );

      return {
        'total_orders': totalOrders.length,
        'paid_orders': paidOrders.length,
        'pending_orders': pendingOrders.length,
        'today_revenue': todayRevenue,
        'success_rate': totalOrders.isNotEmpty 
            ? (paidOrders.length / totalOrders.length * 100).toStringAsFixed(1)
            : '0.0',
      };
    } catch (e) {
      Logger.error('Error loading bar payment stats: $e');
      return {
        'total_orders': 0,
        'paid_orders': 0,
        'pending_orders': 0,
        'today_revenue': 0.0,
        'success_rate': '0.0',
      };
    }
  }
}
