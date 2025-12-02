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

    // --- LÓGICA DE PROVIDER CORREGIDA ---
    final tiendaId = ref.watch(currentTiendaIdProvider);
    final tiendaAsyncValue = ref.watch(tiendaDetailsProvider(tiendaId));

    return Scaffold(
      appBar: AppBar(
        title: tiendaAsyncValue.when(
          data: (tienda) => Text(tienda.name),
          loading: () => const Text('Cargando menú...'),
          error: (e, st) => const Text('Menú'),
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
          // Añadimos un Padding para que el último elemento no quede oculto por el BottomAppBar
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80), // Espacio para el botón flotante
            itemCount: productos.length,
            itemBuilder: (context, index) {
              final producto = productos[index];
              return ProductoTile(producto: producto);
            },
          );
        },
      ),
      // --- BARRA INFERIOR CON BOTÓN DE CARRITO ---
      bottomNavigationBar: carrito.items.isEmpty
          ? null // No muestra nada si el carrito está vacío
          : BottomAppBar(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total: \$${carrito.subtotal.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.shopping_cart_checkout),
                      label: const Text('Ver Mi Pedido'),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const CartScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
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
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.toString().replaceAll('Exception: ', '🛑 ')),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating, 
                          margin: const EdgeInsets.all(12),
                          duration: const Duration(seconds: 2),
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
