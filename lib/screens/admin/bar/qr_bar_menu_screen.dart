import 'package:flutter/material.dart';
import '../../../services/bar_service.dart';
import '../../../utils/logger.dart';

class QRBarMenuScreen extends StatefulWidget {
  const QRBarMenuScreen({super.key});

  @override
  State<QRBarMenuScreen> createState() => _QRBarMenuScreenState();
}

class _QRBarMenuScreenState extends State<QRBarMenuScreen> {
  final BarService _barService = BarService();
  
  List<Map<String, dynamic>> _products = [];
  List<String> _categories = [];
  bool _isLoading = true;
  String _selectedCategory = 'all';
  Map<String, int> _cart = {}; // productId -> quantity

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    
    try {
      final products = await _barService.getBarMenu();
      final categories = await _barService.getBarCategories();
      
      if (mounted) {
        setState(() {
          _products = products.where((p) => p['is_available'] == true).toList();
          _categories = categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      Logger.error('Error loading bar menu: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare la încărcarea meniului: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredProducts {
    if (_selectedCategory == 'all') return _products;
    return _products.where((product) => 
      product['category'] == _selectedCategory
    ).toList();
  }

  double get _cartTotal {
    double total = 0;
    for (final entry in _cart.entries) {
      final product = _products.firstWhere(
        (p) => p['id'] == entry.key,
        orElse: () => {'price': 0.0},
      );
      final price = (product['price'] as num?)?.toDouble() ?? 0.0;
      total += price * entry.value;
    }
    return total;
  }

  int get _cartItemCount {
    return _cart.values.fold(0, (sum, quantity) => sum + quantity);
  }

  void _addToCart(String productId) {
    setState(() {
      _cart[productId] = (_cart[productId] ?? 0) + 1;
    });
  }

  void _removeFromCart(String productId) {
    setState(() {
      if (_cart.containsKey(productId)) {
        if (_cart[productId]! > 1) {
          _cart[productId] = _cart[productId]! - 1;
        } else {
          _cart.remove(productId);
        }
      }
    });
  }

  Future<void> _placeOrder() async {
    if (_cart.isEmpty) return;

    // For now, we'll just show a success message
    // In a real implementation, you'd create multiple orders or a single order with items
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Comandă plasată!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Comanda ta a fost trimisă la bar.'),
            const SizedBox(height: 16),
            Text(
              'Total: ${_cartTotal.toStringAsFixed(2)} €',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vei fi notificat când comanda este gata.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _cart.clear());
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showCart() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Coșul tău',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: _cart.isEmpty
                  ? const Center(
                      child: Text(
                        'Coșul este gol',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _cart.length,
                      itemBuilder: (context, index) {
                        final productId = _cart.keys.elementAt(index);
                        final quantity = _cart[productId]!;
                        final product = _products.firstWhere(
                          (p) => p['id'] == productId,
                          orElse: () => {
                            'name': 'Produs necunoscut',
                            'price': 0.0,
                          },
                        );
                        final name = product['name'] ?? 'Produs necunoscut';
                        final price = (product['price'] as num?)?.toDouble() ?? 0.0;

                        return ListTile(
                          title: Text(name),
                          subtitle: Text('${price.toStringAsFixed(2)} € x $quantity'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () {
                                  _removeFromCart(productId);
                                  if (_cart.isEmpty) {
                                    Navigator.pop(context);
                                  } else {
                                    setState(() {});
                                  }
                                },
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                              Text('$quantity'),
                              IconButton(
                                onPressed: () {
                                  _addToCart(productId);
                                  setState(() {});
                                },
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const Divider(),
            Row(
              children: [
                Text(
                  'Total: ${_cartTotal.toStringAsFixed(2)} €',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _cart.isEmpty ? null : () {
                    Navigator.pop(context);
                    _placeOrder();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Comandă'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meniu Bar - AIU Dance'),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
        actions: [
          if (_cartItemCount > 0)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: _showCart,
                ),
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_cartItemCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            )
          else
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined),
              onPressed: _showCart,
            ),
        ],
      ),
      body: Column(
        children: [
          // Welcome message
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.orange.shade50,
            child: Column(
              children: [
                Icon(
                  Icons.local_bar,
                  size: 32,
                  color: Colors.orange.shade600,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Bun venit la Bar-ul AIU Dance!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Selectează produsele dorite',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Category filter
          if (_categories.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCategoryChip('all', 'Toate'),
                    const SizedBox(width: 8),
                    ..._categories.map((category) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildCategoryChip(category, category),
                    )),
                  ],
                ),
              ),
            ),

          // Products
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadProducts,
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = _filteredProducts[index];
                            return _buildProductCard(product);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: _cartItemCount > 0
          ? FloatingActionButton.extended(
              onPressed: _showCart,
              icon: const Icon(Icons.shopping_cart),
              label: Text('Coș ($_cartItemCount)'),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Widget _buildCategoryChip(String value, String label) {
    final isSelected = _selectedCategory == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedCategory = value);
      },
      backgroundColor: Colors.white,
      selectedColor: Colors.orange.shade100,
      checkmarkColor: Colors.orange.shade600,
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final id = product['id'] ?? '';
    final name = product['name'] ?? 'Fără nume';
    final description = product['description'] as String?;
    final price = (product['price'] as num?)?.toDouble() ?? 0.0;
    final category = product['category'] ?? 'bauturi';
    final imageUrl = product['image_url'] as String?;
    final cartQuantity = _cart[id] ?? 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholderImage(category);
                        },
                      ),
                    )
                  : _buildPlaceholderImage(category),
            ),
          ),

          // Content
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (description != null && description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const Spacer(),
                  Row(
                    children: [
                      Text(
                        '${price.toStringAsFixed(2)} €',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const Spacer(),
                      if (cartQuantity > 0) ...[
                        IconButton(
                          onPressed: () => _removeFromCart(id),
                          icon: const Icon(Icons.remove_circle_outline),
                          iconSize: 20,
                        ),
                        Text('$cartQuantity'),
                        IconButton(
                          onPressed: () => _addToCart(id),
                          icon: const Icon(Icons.add_circle_outline),
                          iconSize: 20,
                        ),
                      ] else ...[
                        IconButton(
                          onPressed: () => _addToCart(id),
                          icon: const Icon(Icons.add_circle),
                          iconSize: 24,
                          color: Colors.orange.shade600,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage(String category) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.orange.shade50,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_drink,
            size: 32,
            color: Colors.orange.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            'Fără imagine',
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_bar_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Meniul este gol',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nu există produse disponibile momentan',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
