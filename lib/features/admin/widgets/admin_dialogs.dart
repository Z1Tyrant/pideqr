import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pideqr/core/models/tienda.dart';
import 'package:pideqr/features/admin/store_qr_code_screen.dart';
import 'package:pideqr/features/menu/menu_providers.dart';

// Clase de utilidad para centralizar los diálogos del panel de administración
class AdminDialogs {
  // Diálogo para CREAR una nueva tienda
  static void showCreateStore(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crear Nueva Tienda'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Nombre de la tienda'),
            validator: (value) => (value == null || value.trim().isEmpty) ? 'El nombre es obligatorio' : null,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final storeName = nameController.text.trim();
                final newStoreId = await ref.read(firestoreServiceProvider).createStore(storeName);
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => StoreQrCodeScreen(storeId: newStoreId, storeName: storeName)),
                );
              }
            },
            child: const Text('Crear y Ver QR'),
          ),
        ],
      ),
    );
  }

  // Diálogo para EDITAR el nombre de una tienda
  static void showEditStoreName(BuildContext context, WidgetRef ref, Tienda store) {
    final nameController = TextEditingController(text: store.name);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Nombre de la Tienda'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Nuevo nombre'),
            validator: (value) => (value == null || value.trim().isEmpty) ? 'El nombre no puede estar vacío' : null,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                ref.read(firestoreServiceProvider).updateStoreName(store.id, nameController.text.trim());
                Navigator.of(context).pop();
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  // Diálogo para CONFIRMAR LA ELIMINACIÓN de una tienda
  static void showDeleteStoreConfirmation(BuildContext context, WidgetRef ref, Tienda store) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Estás seguro de que quieres eliminar la tienda "${store.name}"? Esta acción no se puede deshacer y borrará todos sus productos.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              ref.read(firestoreServiceProvider).deleteStore(store.id);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar Definitivamente'),
          ),
        ],
      ),
    );
  }
}
