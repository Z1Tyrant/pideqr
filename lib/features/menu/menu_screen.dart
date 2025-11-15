// lib/features/menu/menu_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/producto.dart';
import '../orders/order_provider.dart';
import 'menu_providers.dart'; 
import '../auth/auth_checker.dart'; 

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productosAsyncValue = ref.watch(productosStreamProvider);
    final carrito = ref.watch(orderNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menú de la Tienda'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  if (carrito.items.isEmpty) {
                     ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text('El carrito está vacío. Añade productos primero.')),
                     );
                     return;
                  }
                  // Aquí iría la navegación a la pantalla del carrito
                },
              ),
              if (carrito.items.isNotEmpty)
                Positioned(
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      '${carrito.items.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            },
          ),
        ],
      ),
      body: productosAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error al cargar productos: $e', textAlign: TextAlign.center)),
        data: (productos) {
          if (productos.isEmpty) {
            return const Center(child: Text('Esta tienda aún no tiene productos.'));
          }

          return ListView.builder(
            itemCount: productos.length,
            itemBuilder: (context, index) {
              final producto = productos[index];
              return ProductoTile(producto: producto);
            },
          );
        },
      ),
    );
  }
}

// --- Widget de Producto Individual (Tile - ACTUALIZADO) ---

class ProductoTile extends ConsumerWidget {
  final Producto producto;
  const ProductoTile({required this.producto, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderNotifier = ref.read(orderNotifierProvider.notifier);
    // Obtenemos el ID de la tienda actual para pasarlo al notifier
    final tiendaId = ref.watch(currentTiendaIdProvider);

    // Variable para saber si el producto está agotado
    final bool isOutOfStock = producto.stock <= 0;

    return ListTile(
      isThreeLine: true, // Damos más espacio al subtítulo
      title: Text(producto.name),
      // Subtítulo ahora muestra descripción y stock
      subtitle: Text('${producto.description}\nStock disponible: ${producto.stock}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('\$${producto.price.toStringAsFixed(0)}'),
          const SizedBox(width: 8),
          IconButton(
            // El ícono cambia de color si el producto está agotado
            icon: Icon(
              Icons.add_circle,
              color: isOutOfStock ? Colors.grey : Colors.indigo,
            ),
            // Si está agotado, onPressed es null, lo que deshabilita el botón
            onPressed: isOutOfStock
                ? null
                : () {
                    try {
                      // Llamamos a la función con todos los parámetros requeridos
                      orderNotifier.addItemToCart(
                        producto: producto,
                        quantity: 1,
                        tiendaId: tiendaId, // Pasamos el ID de la tienda
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${producto.name} añadido al carrito!')),
                      );
                    } catch (e) {
                      // Mostramos cualquier error (stock insuficiente, etc.)
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '🛑 '))),
                      );
                    }
                  },
          ),
        ],
      ),
    );
  }
}
