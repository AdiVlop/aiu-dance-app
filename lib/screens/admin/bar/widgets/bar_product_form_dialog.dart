import 'dart:io';
import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart'; // Temporar dezactivat pentru APK minimal
import '../../../../services/bar_service.dart';
import '../../../../utils/logger.dart';

class BarProductFormDialog extends StatefulWidget {
  final Map<String, dynamic>? product;
  final List<String> categories;

  const BarProductFormDialog({
    super.key,
    this.product,
    required this.categories,
  });

  @override
  State<BarProductFormDialog> createState() => _BarProductFormDialogState();
}

class _BarProductFormDialogState extends State<BarProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final BarService _barService = BarService();
  
  String _category = '';
  File? _selectedImage;
  bool _isAvailable = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    if (widget.product != null) {
      final product = widget.product!;
      _nameController.text = product['name'] ?? '';
      _descriptionController.text = product['description'] ?? '';
      _priceController.text = (product['price'] ?? 0.0).toString();
      _category = product['category'] ?? (widget.categories.isNotEmpty ? widget.categories.first : 'bauturi');
      _isAvailable = product['is_available'] ?? true;
    } else {
      _category = widget.categories.isNotEmpty ? widget.categories.first : 'bauturi';
      _priceController.text = '0.00';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    // final picker = ImagePicker(); // Temporar dezactivat pentru APK minimal
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Upload imagini temporar dezactivat pentru optimizarea aplicației')),
    );
    return;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Selectează sursa imaginii',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      // Image picker temporarily disabled for APK optimization
                      // final image = await picker.pickImage(source: ImageSource.camera);
                      // if (image != null) {
                      //   setState(() => _selectedImage = File(image.path));
                      // }
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      // Image picker temporarily disabled for APK optimization
                      // final image = await picker.pickImage(source: ImageSource.gallery);
                      // if (image != null) {
                      //   setState(() => _selectedImage = File(image.path));
                      // }
                    },
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galerie'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _selectedImage = null);
              },
              child: const Text('Elimină imaginea'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final price = double.tryParse(_priceController.text) ?? 0.0;

      if (widget.product == null) {
        // Create new product
        final result = await _barService.createBarMenuItem(
          name: _nameController.text.trim(),
          price: price,
          description: _descriptionController.text.trim().isEmpty 
              ? null 
              : _descriptionController.text.trim(),
          category: _category,
          imageFile: _selectedImage,
          isAvailable: _isAvailable,
        );

        if (result != null) {
          if (mounted) {
            Navigator.pop(context, true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Produs creat cu succes!')),
            );
          }
        } else {
          throw Exception('Eroare la crearea produsului');
        }
      } else {
        // Update existing product
        final updates = <String, dynamic>{
          'name': _nameController.text.trim(),
          'price': price,
          'category': _category,
          'is_available': _isAvailable,
        };

        if (_descriptionController.text.trim().isNotEmpty) {
          updates['description'] = _descriptionController.text.trim();
        }

        // Note: Image update would require additional logic for Supabase Storage
        // For now, we'll skip image updates in edit mode

        final success = await _barService.updateBarMenuItem(
          widget.product!['id'],
          updates,
        );

        if (success) {
          if (mounted) {
            Navigator.pop(context, true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Produs actualizat cu succes!')),
            );
          }
        } else {
          throw Exception('Eroare la actualizarea produsului');
        }
      }
    } catch (e) {
      Logger.error('Error saving bar product: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare: $e')),
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
    final isEditing = widget.product != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.shade600,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isEditing ? Icons.edit : Icons.add,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isEditing ? 'Editează Produsul' : 'Produs Nou',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nume produs *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.inventory),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Numele produsului este obligatoriu';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Descriere (opțional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),

                      // Price and Category row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              decoration: const InputDecoration(
                                labelText: 'Preț *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.euro),
                                suffixText: 'EUR',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Prețul este obligatoriu';
                                }
                                final price = double.tryParse(value);
                                if (price == null || price < 0) {
                                  return 'Prețul trebuie să fie un număr pozitiv';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _category.isNotEmpty ? _category : null,
                              decoration: const InputDecoration(
                                labelText: 'Categorie *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.category),
                              ),
                              items: widget.categories.map((category) => 
                                DropdownMenuItem(
                                  value: category,
                                  child: Text(category),
                                )
                              ).toList(),
                              onChanged: (value) => setState(() => _category = value!),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Categoria este obligatorie';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Image selection
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.image),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Imagine produs',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const Spacer(),
                                  TextButton.icon(
                                    onPressed: _pickImage,
                                    icon: const Icon(Icons.add_a_photo),
                                    label: const Text('Selectează'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (_selectedImage != null) ...[
                                Container(
                                  height: 120,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      _selectedImage!,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ] else if (widget.product?['image_url'] != null) ...[
                                Container(
                                  height: 120,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      widget.product!['image_url'],
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey.shade200,
                                          child: const Center(
                                            child: Text('Imaginea nu poate fi încărcată'),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ] else ...[
                                Container(
                                  height: 120,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.image_outlined,
                                        size: 48,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Fără imagine',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Availability switch
                      SwitchListTile(
                        title: const Text('Disponibil'),
                        subtitle: const Text('Produsul este disponibil pentru comandă'),
                        value: _isAvailable,
                        onChanged: (value) => setState(() => _isAvailable = value),
                        activeColor: Colors.green,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Anulează'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade600,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(isEditing ? 'Actualizează' : 'Creează'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
