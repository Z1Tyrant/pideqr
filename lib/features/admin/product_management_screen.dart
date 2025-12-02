// lib/features/admin/product_management_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pideqr/core/models/producto.dart';
import 'package:pideqr/features/admin/edit_product_screen.dart'; // <-- IMPORTACIÓN AÑADIDA
import 'package:pideqr/features/menu/menu_providers.dart';

class ProductManagementScreen extends ConsumerWidget {
  final String tiendaId;
  final String tiendaName;

  const ProductManagementScreen({
    super.key,
    required this.tiendaId,
    required this.tiendaName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productosAsync = ref.watch(productosStreamProvider(tiendaId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Productos de $tiendaName'),
      ),
      body: productosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (productos) {
          if (productos.isEmpty) {
            return const Center(child: Text('Esta tienda no tiene productos.'));
          }
          return ListView.builder(
            itemCount: productos.length,
            itemBuilder: (context, index) {
              final producto = productos[index];
              return ListTile(
                title: Text(producto.name),
                subtitle: Text('Stock: ${producto.stock}'),
                trailing: Text('\$${producto.price.toStringAsFixed(0)}'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => EditProductScreen(
                        tiendaId: tiendaId,
                        producto: producto,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Añadir Producto'),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => EditProductScreen(
                tiendaId: tiendaId,
              ),
            ),
          );
        },
      ),
    );
  }
}
