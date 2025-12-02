// lib/features/orders/cart_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pideqr/features/orders/payment_screen.dart';
import 'package:pideqr/features/menu/menu_providers.dart';
import 'package:pideqr/core/models/producto.dart';
import 'order_provider.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final carrito = ref.watch(orderNotifierProvider);
    final orderNotifier = ref.read(orderNotifierProvider.notifier);
    final productosAsync = ref.watch(productosStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Pedido'),
        actions: [
          if (carrito.items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.red),
              onPressed: () => orderNotifier.clearCart(),
            )
        ],
      ),
      body: carrito.items.isEmpty
          ? const Center(
              child: Text('Tu carrito está vacío', style: TextStyle(fontSize: 18, color: Colors.grey)),
            )
          : ListView.builder(
              itemCount: carrito.items.length,
              itemBuilder: (context, index) {
                final item = carrito.items[index];
                
                final Producto? productoOriginal = productosAsync.when(
                  data: (productos) => productos.firstWhere((p) => p.id == item.productId, orElse: () => null as Producto),
                  loading: () => null,
                  error: (e, st) => null,
                );

                return ListTile(
                  title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Subtotal: \$${item.subtotal.toStringAsFixed(0)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () {
                          orderNotifier.decrementItemQuantity(item.productId);
                        },
                      ),
                      Text(item.quantity.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: (productoOriginal != null && item.quantity >= productoOriginal.stock)
                            ? null 
                            : () {
                                if (productoOriginal != null) {
                                  orderNotifier.addItemToCart(producto: productoOriginal, quantity: 1, tiendaId: ref.read(currentTiendaIdProvider));
                                }
                              },
                      ),
                    ],
                  ),
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
                    Text('Total: \$${carrito.subtotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.payment),
                      label: const Text('Ir a Pagar'),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const ConfirmOrderScreen()),
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

class ConfirmOrderScreen extends ConsumerWidget {
  const ConfirmOrderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final carrito = ref.watch(orderNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmar y Pagar'),
      ),
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
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 16), 
              Expanded(
                child: ElevatedButton(
                  child: const Text('Pagar ahora', style: TextStyle(fontSize: 18)),
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const PaymentScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
