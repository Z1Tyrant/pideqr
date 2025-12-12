// lib/features/orders/cart_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pideqr/features/orders/payment_screen.dart';
import 'package:pideqr/features/menu/menu_providers.dart';
import 'order_provider.dart';

// Screen 1: The Shopping Cart
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final carrito = ref.watch(orderNotifierProvider);
    final orderNotifier = ref.read(orderNotifierProvider.notifier);
    final tiendaId = carrito.currentTiendaId ?? '';
    final productosAsync = ref.watch(productosStreamProvider(tiendaId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Pedido'),
        actions: [
          if (carrito.items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.red),
              tooltip: 'Vaciar Carrito',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Confirmar'),
                    content: const Text('¿Seguro que quieres vaciar el carrito?'),
                    actions: [
                      TextButton(
                        child: const Text('No'),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                      TextButton(
                        child: const Text('Sí, Vaciar', style: TextStyle(color: Colors.red)),
                        onPressed: () {
                          orderNotifier.clearCart();
                          Navigator.of(ctx).pop();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: carrito.items.isEmpty
          ? const Center(
              child: Text('Tu carrito está vacío', style: TextStyle(fontSize: 18, color: Colors.grey)),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: carrito.items.length,
              itemBuilder: (context, index) {
                final item = carrito.items[index];
                final productoOriginal = productosAsync.when(
                  data: (productos) {
                    try {
                      return productos.firstWhere((p) => p.id == item.productId);
                    } catch (e) {
                      return null;
                    }
                  },
                  loading: () => null,
                  error: (_, __) => null,
                );

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: SizedBox(
                      width: 70,
                      height: 70,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: productoOriginal?.imageUrl != null
                            ? Image.network(productoOriginal!.imageUrl!, fit: BoxFit.cover, errorBuilder: (c, e, st) => const Icon(Icons.error))
                            : const Icon(Icons.image_not_supported, color: Colors.grey),
                      ),
                    ),
                    title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Subtotal: \$${item.subtotal.toStringAsFixed(0)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => orderNotifier.decrementItemQuantity(item.productId)),
                        Text(item.quantity.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: (productoOriginal != null && item.quantity >= productoOriginal.stock) ? null : () {
                            if (productoOriginal != null) {
                              orderNotifier.addItemToCart(producto: productoOriginal, quantity: 1, tiendaId: tiendaId);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
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
                      icon: const Icon(Icons.payment),
                      label: const Text('Ir a Pagar'),
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ConfirmOrderScreen())),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// Screen 2: The Confirmation Screen (Restored)
class ConfirmOrderScreen extends ConsumerWidget {
  const ConfirmOrderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final carrito = ref.watch(orderNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Confirmar y Pagar')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Resumen de tu pedido:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: carrito.items.length,
              itemBuilder: (context, index) {
                final item = carrito.items[index];
                return ListTile(
                  title: Text(item.productName),
                  subtitle: Text('Cantidad: ${item.quantity}'),
                  trailing: Text('\$${item.subtotal.toStringAsFixed(0)}'),
                );
              },
            ),
          ),
          const Divider(thickness: 2),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total a pagar:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text('\$${carrito.subtotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea( // Use SafeArea to avoid system intrusions
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Pagar Ahora', style: TextStyle(fontSize: 18)),
                  onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const PaymentScreen())),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
