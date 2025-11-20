// lib/features/menu/menu_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/producto.dart';
import '../orders/cart_screen.dart';
import '../orders/order_provider.dart';
import 'menu_providers.dart';
import '../auth/auth_checker.dart';

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productosAsyncValue = ref.watch(productosStreamProvider);
    final carrito = ref.watch(orderNotifierProvider);
    // --- 1. Observamos el nuevo provider de los detalles de la tienda ---
    final tiendaAsyncValue = ref.watch(tiendaDetailsProvider);

    return Scaffold(
      appBar: AppBar(
        // --- 2. El título ahora es dinámico ---
        title: tiendaAsyncValue.when(
          data: (tienda) => Text(tienda.name), // Muestra el nombre de la tienda
          loading: () => const Text('Cargando menú...'), // Muestra mientras carga
          error: (e, st) => const Text('Menú'), // Fallback en caso de error
        ),
        actions: [
          if (carrito.items.isNotEmpty)
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const CartScreen()),
                    );
                  },
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${carrito.totalItems}',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            )
          else
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('El carrito está vacío. Añade productos primero.')),
                );
              },
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

class ProductoTile extends ConsumerWidget {
  final Producto producto;
  const ProductoTile({required this.producto, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderNotifier = ref.read(orderNotifierProvider.notifier);
    final tiendaId = ref.watch(currentTiendaIdProvider);
    final bool isOutOfStock = producto.stock <= 0;

    return ListTile(
      isThreeLine: true,
      title: Text(producto.name),
      subtitle: Text('${producto.description}\nStock disponible: ${producto.stock}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('\$${producto.price.toStringAsFixed(0)}'),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              Icons.add_circle,
              color: isOutOfStock ? Colors.grey : Colors.indigo,
            ),
            onPressed: isOutOfStock
                ? null
                : () {
                    try {
                      orderNotifier.addItemToCart(
                        producto: producto,
                        quantity: 1,
                        tiendaId: tiendaId,
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${producto.name} añadido al carrito!'),
                          behavior: SnackBarBehavior.floating, 
                          margin: const EdgeInsets.all(12),      
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.toString().replaceAll('Exception: ', '🛑 ')),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating, 
                          margin: const EdgeInsets.all(12),      
                        ),
                      );
                    }
                  },
          ),
        ],
      ),
    );
  }
}
