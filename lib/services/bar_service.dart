import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';

class BarService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // BAR MENU MANAGEMENT
  
  // Get all bar menu items
  Future<List<Map<String, dynamic>>> getBarMenu() async {
    try {
      final response = await _supabase
          .from('bar_menu')
          .select('*')
          .order('category', ascending: true)
          .order('name', ascending: true);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      Logger.error('Error fetching bar menu: $e');
      return [];
    }
  }

  // Get bar menu by category
  Future<List<Map<String, dynamic>>> getBarMenuByCategory(String category) async {
    try {
      final response = await _supabase
          .from('bar_menu')
          .select('*')
          .eq('category', category)
          .eq('is_available', true)
          .order('name', ascending: true);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      Logger.error('Error fetching bar menu by category: $e');
      return [];
    }
  }

  // Create bar menu item
  Future<Map<String, dynamic>?> createBarMenuItem({
    required String name,
    required double price,
    String? description,
    String category = 'bauturi',
    File? imageFile,
    bool isAvailable = true,
  }) async {
    try {
      String? imageUrl;
      
      // Upload image if provided
      if (imageFile != null) {
        imageUrl = await _uploadBarImage(imageFile);
      }

      final response = await _supabase
          .from('bar_menu')
          .insert({
            'name': name,
            'description': description,
            'price': price,
            'category': category,
            'image_url': imageUrl,
            'is_available': isAvailable,
          })
          .select()
          .single();
      
      Logger.info('Bar menu item created successfully: ${response['id']}');
      return response;
    } catch (e) {
      Logger.error('Error creating bar menu item: $e');
      return null;
    }
  }

  // Update bar menu item
  Future<bool> updateBarMenuItem(String id, Map<String, dynamic> updates) async {
    try {
      await _supabase
          .from('bar_menu')
          .update({
            ...updates,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
      
      Logger.info('Bar menu item updated successfully: $id');
      return true;
    } catch (e) {
      Logger.error('Error updating bar menu item: $e');
      return false;
    }
  }

  // Delete bar menu item
  Future<bool> deleteBarMenuItem(String id) async {
    try {
      await _supabase
          .from('bar_menu')
          .delete()
          .eq('id', id);
      
      Logger.info('Bar menu item deleted successfully: $id');
      return true;
    } catch (e) {
      Logger.error('Error deleting bar menu item: $e');
      return false;
    }
  }

  // Upload bar image to Supabase Storage
  Future<String?> _uploadBarImage(File file) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final filePath = 'bar_menu/$fileName';
      
      final bytes = await file.readAsBytes();
      await _supabase.storage
          .from('bar_menu')
          .uploadBinary(filePath, bytes);
      
      final publicUrl = _supabase.storage
          .from('bar_menu')
          .getPublicUrl(filePath);
      
      Logger.info('Bar image uploaded successfully: $publicUrl');
      return publicUrl;
    } catch (e) {
      Logger.error('Error uploading bar image: $e');
      return null;
    }
  }

  // BAR ORDERS MANAGEMENT

  // Get all bar orders
  Future<List<Map<String, dynamic>>> getBarOrders() async {
    try {
      final response = await _supabase
          .from('bar_orders')
          .select('''
            *,
            bar_menu(name, price),
            profiles(full_name, email)
          ''')
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      Logger.error('Error fetching bar orders: $e');
      return [];
    }
  }

  // Get bar orders by status
  Future<List<Map<String, dynamic>>> getBarOrdersByStatus(String status) async {
    try {
      final response = await _supabase
          .from('bar_orders')
          .select('''
            *,
            bar_menu(name, price),
            profiles(full_name, email)
          ''')
          .eq('status', status)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      Logger.error('Error fetching bar orders by status: $e');
      return [];
    }
  }

  // Create bar order
  Future<Map<String, dynamic>?> createBarOrder({
    required String productId,
    int quantity = 1,
    String? notes,
  }) async {
    try {
      // Get product details to calculate total
      final productResponse = await _supabase
          .from('bar_menu')
          .select('price')
          .eq('id', productId)
          .single();

      final productPrice = productResponse['price'] as double;
      final totalAmount = productPrice * quantity;

      final response = await _supabase
          .from('bar_orders')
          .insert({
            'user_id': _supabase.auth.currentUser?.id,
            'product_id': productId,
            'quantity': quantity,
            'total_amount': totalAmount,
            'notes': notes,
            'status': 'pending',
          })
          .select()
          .single();
      
      Logger.info('Bar order created successfully: ${response['id']}');
      return response;
    } catch (e) {
      Logger.error('Error creating bar order: $e');
      return null;
    }
  }

  // Update bar order status
  Future<bool> updateBarOrderStatus(String orderId, String status) async {
    try {
      await _supabase
          .from('bar_orders')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);
      
      Logger.info('Bar order status updated successfully: $orderId -> $status');
      return true;
    } catch (e) {
      Logger.error('Error updating bar order status: $e');
      return false;
    }
  }

  // Delete bar order
  Future<bool> deleteBarOrder(String id) async {
    try {
      await _supabase
          .from('bar_orders')
          .delete()
          .eq('id', id);
      
      Logger.info('Bar order deleted successfully: $id');
      return true;
    } catch (e) {
      Logger.error('Error deleting bar order: $e');
      return false;
    }
  }

  // STATISTICS

  // Get bar statistics
  Future<Map<String, dynamic>> getBarStats() async {
    try {
      // Total menu items
      final totalMenuResponse = await _supabase
          .from('bar_menu')
          .select('id');

      // Available menu items
      final availableMenuResponse = await _supabase
          .from('bar_menu')
          .select('id')
          .eq('is_available', true);

      // Total orders
      final totalOrdersResponse = await _supabase
          .from('bar_orders')
          .select('id');

      // Orders by status
      final pendingOrdersResponse = await _supabase
          .from('bar_orders')
          .select('id')
          .eq('status', 'pending');

      final confirmedOrdersResponse = await _supabase
          .from('bar_orders')
          .select('id')
          .eq('status', 'confirmed');

      // Revenue calculation
      final revenueResponse = await _supabase
          .from('bar_orders')
          .select('total_amount')
          .eq('status', 'delivered');

      double totalRevenue = 0;
      for (final order in revenueResponse) {
        totalRevenue += (order['total_amount'] as num?)?.toDouble() ?? 0;
      }

      // Categories
      final categoriesResponse = await _supabase
          .from('bar_menu')
          .select('category');

      final categories = <String, int>{};
      for (final item in categoriesResponse) {
        final category = item['category'] as String? ?? 'Other';
        categories[category] = (categories[category] ?? 0) + 1;
      }

      return {
        'totalMenuItems': totalMenuResponse.length,
        'availableItems': availableMenuResponse.length,
        'totalOrders': totalOrdersResponse.length,
        'pendingOrders': pendingOrdersResponse.length,
        'confirmedOrders': confirmedOrdersResponse.length,
        'totalRevenue': totalRevenue,
        'categories': categories,
      };
    } catch (e) {
      Logger.error('Error getting bar stats: $e');
      return {
        'totalMenuItems': 0,
        'availableItems': 0,
        'totalOrders': 0,
        'pendingOrders': 0,
        'confirmedOrders': 0,
        'totalRevenue': 0.0,
        'categories': <String, int>{},
      };
    }
  }

  // Get bar categories
  Future<List<String>> getBarCategories() async {
    try {
      final response = await _supabase
          .from('bar_menu')
          .select('category')
          .order('category');

      final categories = <String>{};
      for (final item in response) {
        final category = item['category'] as String?;
        if (category != null && category.isNotEmpty) {
          categories.add(category);
        }
      }

      return categories.toList();
    } catch (e) {
      Logger.error('Error fetching bar categories: $e');
      return ['bauturi', 'cafea', 'cocktail', 'alcool']; // Default categories
    }
  }

  // Get today's orders
  Future<List<Map<String, dynamic>>> getTodayOrders() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

      final response = await _supabase
          .from('bar_orders')
          .select('''
            *,
            bar_menu(name, price),
            profiles(full_name, email)
          ''')
          .gte('created_at', startOfDay.toIso8601String())
          .lte('created_at', endOfDay.toIso8601String())
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      Logger.error('Error fetching today orders: $e');
      return [];
    }
  }
}
