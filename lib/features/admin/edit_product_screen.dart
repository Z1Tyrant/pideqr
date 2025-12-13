import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart'; // <--- LIBRERÍA REINTRODUCIDA
import 'package:pideqr/core/models/producto.dart';
import 'package:pideqr/features/menu/menu_providers.dart';
import 'package:pideqr/services/storage_service.dart';

// --- CONTROLADOR (SIN CAMBIOS) ---
final editProductControllerProvider = NotifierProvider<EditProductController, bool>(EditProductController.new);

class EditProductController extends Notifier<bool> {
  @override
  bool build() => false;

  void setLoading(bool isLoading) {
    state = isLoading;
  }

  Future<void> saveProductData({
    required String tiendaId,
    required String name,
    required String description,
    required double price,
    required int stock,
    required String? imageUrl,
    required Producto? existingProduct,
  }) async {
    final productId = existingProduct?.id ?? ref.read(firestoreServiceProvider).getNewDocumentId('tiendas/$tiendaId/productos');
    final productData = {
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'image_url': imageUrl,
    };
    await ref.read(firestoreServiceProvider).upsertProduct(
      tiendaId: tiendaId,
      productoId: productId,
      data: productData,
    );
  }
}

// --- PANTALLA RECONECTADA A IMAGE_PICKER ---
class EditProductScreen extends ConsumerStatefulWidget {
  final String tiendaId;
  final Producto? producto;

  const EditProductScreen({super.key, required this.tiendaId, this.producto});

  @override
  ConsumerState<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends ConsumerState<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;
  
  XFile? _newImageFile; // Guardará el archivo de la nueva imagen seleccionada
  String? _existingImageUrl; // Guardará la URL de la imagen que ya tenía el producto

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.producto?.name ?? '');
    _descriptionController = TextEditingController(text: widget.producto?.description ?? '');
    _priceController = TextEditingController(text: widget.producto?.price.toStringAsFixed(0) ?? '');
    _stockController = TextEditingController(text: widget.producto?.stock.toString() ?? '0');
    _existingImageUrl = widget.producto?.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  // --- MÉTODO PARA ABRIR LA GALERÍA DEL TELÉFONO ---
  Future<void> _pickImageFromGallery() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (image != null) {
      setState(() {
        _newImageFile = image;
      });
    }
  }

  // --- LÓGICA DE GUARDADO FINAL ---
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    ref.read(editProductControllerProvider.notifier).setLoading(true);

    try {
      String? finalImageUrl = _existingImageUrl;

      // 1. Si hay un NUEVO archivo de imagen, súbelo a Storage.
      if (_newImageFile != null) {
        final productId = widget.producto?.id ?? ref.read(firestoreServiceProvider).getNewDocumentId('tiendas/${widget.tiendaId}/productos');
        finalImageUrl = await ref.read(storageServiceProvider).uploadProductImage(
          image: _newImageFile!,
          productId: productId,
        );
      }

      // 2. Guarda todos los datos en Firestore, usando la URL nueva o la que ya existía.
      await ref.read(editProductControllerProvider.notifier).saveProductData(
        tiendaId: widget.tiendaId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.tryParse(_priceController.text) ?? 0.0,
        stock: int.tryParse(_stockController.text) ?? 0,
        imageUrl: finalImageUrl,
        existingProduct: widget.producto,
      );

      ref.invalidate(productosStreamProvider(widget.tiendaId));
      messenger.showSnackBar(
        SnackBar(content: Text('Producto ${widget.producto == null ? "creado" : "actualizado"} con éxito.'), backgroundColor: Colors.green),
      );
      navigator.pop();

    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error al guardar: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      ref.read(editProductControllerProvider.notifier).setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.producto != null;
    final isLoading = ref.watch(editProductControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Producto' : 'Nuevo Producto'),
      ),
      body: IgnorePointer(
        ignoring: isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  onTap: _pickImageFromGallery,
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                      // La imagen que se muestra cambia dinámicamente
                      image: _newImageFile != null
                          ? DecorationImage(image: FileImage(File(_newImageFile!.path)), fit: BoxFit.cover)
                          : (_existingImageUrl != null && _existingImageUrl!.isNotEmpty)
                              ? DecorationImage(image: NetworkImage(_existingImageUrl!), fit: BoxFit.cover)
                              : null,
                    ),
                    child: (_newImageFile == null && (_existingImageUrl == null || _existingImageUrl!.isEmpty))
                        ? const Center(child: Icon(Icons.add_a_photo, size: 50, color: Colors.grey))
                        : null,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (value) => (value == null || value.isEmpty) ? 'Ingresa un nombre' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                  validator: (value) => (value == null || value.isEmpty) ? 'Ingresa una descripción' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(labelText: 'Precio', prefixText: 'CLP \$'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Ingresa un precio';
                          if (double.tryParse(value) == null) return 'Precio inválido';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _stockController,
                        decoration: const InputDecoration(labelText: 'Stock'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Ingresa el stock';
                          if (int.tryParse(value) == null) return 'Stock inválido';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar Cambios'),
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
        ),
      ),
    );
  }
}
