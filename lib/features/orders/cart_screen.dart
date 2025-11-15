// lib/features/orders/cart_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pideqr/features/orders/payment_screen.dart'; // <-- IMPORTAMOS LA NUEVA PANTALLA
import 'order_provider.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final carrito = ref.watch(orderNotifierProvider);
    final orderNotifier = ref.read(orderNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Pedido'),
        actions: [
          if (carrito.items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.red),
              tooltip: 'Vaciar carrito',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirmar'),
                    content: const Text('¿Estás seguro de que quieres vaciar el carrito?'),
                    actions: [
                      TextButton(
                        child: const Text('Cancelar'),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      TextButton(
                        child: const Text('Vaciar', style: TextStyle(color: Colors.red)),
                        onPressed: () {
                          orderNotifier.clearCart();
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                );
              },
            )
        ],
      ),
      body: carrito.items.isEmpty
          ? const Center(
              child: Text(
                'Tu carrito está vacío',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: carrito.items.length,
              itemBuilder: (context, index) {
                final item = carrito.items[index];
                return ListTile(
                  title: Text(item.productName),
                  subtitle: Text('Precio: \$${item.unitPrice.toStringAsFixed(0)}'),
                  leading: CircleAvatar(
                    child: Text(item.quantity.toString()),
                  ),
                  trailing: Text(
                    'Subtotal: \$${item.subtotal.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onLongPress: () {
                    orderNotifier.removeItemFromCart(item.productId);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${item.productName} eliminado')),
                    );
                  },
                );
              },
            ),
      bottomNavigationBar: carrito.items.isEmpty
          ? null
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
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Confirmar Pedido'),
                      // --- LÓGICA DE NAVEGACIÓN ACTUALIZADA ---
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const PaymentScreen()),
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
