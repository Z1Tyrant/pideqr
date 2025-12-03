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
    final tiendaId = ref.watch(currentTiendaIdProvider);
    final productosAsyncValue = ref.watch(productosStreamProvider(tiendaId));
    final carrito = ref.watch(orderNotifierProvider);
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
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CartScreen())),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text('${carrito.totalItems}', style: const TextStyle(color: Colors.white, fontSize: 10), textAlign: TextAlign.center),
                  ),
                ),
              ],
            )
          else
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined),
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('El carrito está vacío. Añade productos primero.')),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const HomeScreen())),
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
            padding: const EdgeInsets.only(bottom: 80, top: 8),
            itemCount: productos.length,
            itemBuilder: (context, index) => ProductoTile(producto: productos[index]),
          );
        },
      ),
      bottomNavigationBar: carrito.items.isEmpty
          ? null
          : BottomAppBar(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total: \$${carrito.subtotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.shopping_cart_checkout),
                      label: const Text('Ver Mi Pedido'),
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CartScreen())),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// --- WIDGET DE PRODUCTO TOTALMENTE REDISEÑADO ---
class ProductoTile extends ConsumerWidget {
  final Producto producto;
  const ProductoTile({required this.producto, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderNotifier = ref.read(orderNotifierProvider.notifier);
    final tiendaId = ref.watch(currentTiendaIdProvider);
    final bool isOutOfStock = producto.stock <= 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // --- Columna Izquierda: Imagen ---
            SizedBox(
              width: 80,
              height: 80,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: producto.imageUrl != null
                    ? Image.network(producto.imageUrl!, fit: BoxFit.cover, errorBuilder: (c, e, st) => const Icon(Icons.error))
                    : const Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
              ),
            ),
            const SizedBox(width: 16),
            // --- Columna Central: Texto (expandida) ---
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(producto.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(producto.description, style: Theme.of(context).textTheme.bodyMedium, maxLines: 3, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // --- Columna Derecha: Precio y Botón ---
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('\$${producto.price.toStringAsFixed(0)}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: Icon(
                    isOutOfStock ? Icons.remove_shopping_cart_outlined : Icons.add_shopping_cart,
                    color: isOutOfStock ? Colors.grey : Theme.of(context).colorScheme.primary,
                    size: 30,
                  ),
                  onPressed: isOutOfStock ? null : () {
                    try {
                      orderNotifier.addItemToCart(producto: producto, quantity: 1, tiendaId: tiendaId);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${producto.name} añadido al carrito'), duration: const Duration(seconds: 1)),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.redAccent),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
