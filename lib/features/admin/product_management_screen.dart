import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pideqr/core/models/producto.dart';
import 'package:pideqr/features/admin/edit_product_screen.dart';
import 'package:pideqr/features/menu/menu_providers.dart';

class ProductManagementScreen extends ConsumerWidget {
  final String tiendaId;
  final String tiendaName;

  const ProductManagementScreen({
    super.key,
    required this.tiendaId,
    required this.tiendaName,
  });

  Future<void> _showDeleteConfirmationDialog(BuildContext context, WidgetRef ref, Producto producto) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: Text('¿Estás seguro de que quieres eliminar el producto "${producto.name}"?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Eliminar'),
              onPressed: () async {
                try {
                  await ref.read(firestoreServiceProvider).deleteProduct(
                        tiendaId: tiendaId,
                        productoId: producto.id,
                      );
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Producto eliminado'), backgroundColor: Colors.green),
                  );
                } catch (e) {
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al eliminar: $e'), backgroundColor: Colors.red),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

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
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: (producto.imageUrl != null && producto.imageUrl!.isNotEmpty)
                      ? SizedBox(
                          width: 50,
                          height: 50,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: CachedNetworkImage(
                              imageUrl: producto.imageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2.0)),
                              errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.red),
                            ),
                          ),
                        )
                      : const SizedBox(
                          width: 50,
                          height: 50,
                          child: Icon(Icons.image_not_supported),
                        ),
                  title: Text(producto.name),
                  subtitle: Text('Stock: ${producto.stock}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('\$${producto.price.toStringAsFixed(0)}'),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () => _showDeleteConfirmationDialog(context, ref, producto),
                        tooltip: 'Eliminar Producto',
                      ),
                    ],
                  ),
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
                ),
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
