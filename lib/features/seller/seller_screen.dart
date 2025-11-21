// lib/features/seller/seller_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pideqr/features/auth/auth_providers.dart';
import 'package:pideqr/features/orders/order_provider.dart';
import 'package:pideqr/features/menu/menu_providers.dart';
import 'package:pideqr/features/seller/order_delivery_scanner.dart';
import 'package:pideqr/features/seller/seller_history_screen.dart'; // <-- NUEVA IMPORTACIÓN

class SellerScreen extends ConsumerWidget {
  const SellerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsyncValue = ref.watch(pendingOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedidos Pendientes'),
        actions: [
          // --- BOTÓN DE HISTORIAL AÑADIDO ---
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historial de Entregas',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SellerHistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () => ref.read(authServiceProvider).signOut(),
          ),
        ],
      ),
      body: ordersAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error al cargar pedidos: $error'),
        ),
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(
              child: Text(
                'No hay pedidos pendientes.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final formattedDate = DateFormat('dd/MM, hh:mm a').format(order.timestamp);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pedido #${order.id?.substring(0, 6)}...',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const Divider(),
                      Text('Fecha: $formattedDate'),
                      Text('Total: \$${order.total.toStringAsFixed(0)}'),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orangeAccent,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                ref
                                    .read(firestoreServiceProvider)
                                    .updateOrderStatus(order.id!, 'listo_para_entrega');
                              },
                              child: const Text('Preparado'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.qr_code_scanner),
                              label: const Text('Entregar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => OrderDeliveryScannerScreen(
                                      expectedOrderId: order.id!,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
