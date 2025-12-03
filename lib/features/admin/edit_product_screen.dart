import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pideqr/core/models/producto.dart';
import 'package:pideqr/features/menu/menu_providers.dart';
import 'package:pideqr/services/storage_service.dart'; // <-- NUEVA IMPORTACIÓN

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
  XFile? _imageFile; // <-- Variable para la nueva imagen seleccionada
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.producto?.name ?? '');
    _descriptionController = TextEditingController(text: widget.producto?.description ?? '');
    _priceController = TextEditingController(text: widget.producto?.price.toStringAsFixed(0) ?? '');
    _stockController = TextEditingController(text: widget.producto?.stock.toString() ?? '0');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() {
        _imageFile = image;
      });
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      String? imageUrl = widget.producto?.imageUrl;

      // 1. Si se seleccionó una nueva imagen, subirla
      if (_imageFile != null) {
        final productId = widget.producto?.id ?? ref.read(firestoreServiceProvider).getNewDocumentId('tiendas/${widget.tiendaId}/productos');
        imageUrl = await ref.read(storageServiceProvider).uploadProductImage(
          image: _imageFile!,
          productId: productId,
        );
      }

      // 2. Preparar los datos del producto
      final productData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'stock': int.tryParse(_stockController.text) ?? 0,
        'imageUrl': imageUrl,
      };

      // 3. Guardar en Firestore
      await ref.read(firestoreServiceProvider).upsertProduct(
        tiendaId: widget.tiendaId,
        productoId: widget.producto?.id,
        data: productData,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Producto ${widget.producto == null ? "creado" : "actualizado"} con éxito.')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      // ... (manejo de errores)
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.producto != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Producto' : 'Nuevo Producto'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // --- SECCIÓN DE IMAGEN ---
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                    image: _imageFile != null 
                        ? DecorationImage(image: FileImage(File(_imageFile!.path)), fit: BoxFit.cover)
                        : (widget.producto?.imageUrl != null 
                            ? DecorationImage(image: NetworkImage(widget.producto!.imageUrl!), fit: BoxFit.cover) 
                            : null),
                  ),
                  child: _imageFile == null && widget.producto?.imageUrl == null 
                      ? const Center(child: Icon(Icons.add_a_photo, size: 50, color: Colors.grey)) 
                      : null,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              // ... (resto de los campos de texto)
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar Cambios'),
                  onPressed: _saveProduct,
                ),
        ),
      ),
    );
  }
}
