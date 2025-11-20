// lib/features/orders/order_history_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pideqr/features/orders/order_details_screen.dart';
import 'order_provider.dart';

class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsyncValue = ref.watch(userOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Pedidos'),
      ),
      body: ordersAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error al cargar el historial: $error'),
        ),
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(
              child: Text(
                'Aún no has realizado ningún pedido.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }
          
          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final formattedDate = DateFormat('dd/MM/yyyy, hh:mm a').format(order.timestamp);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(
                    'Pedido #${order.id?.substring(0, 6)}...',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Fecha: $formattedDate\nTotal: \$${order.total.toStringAsFixed(0)}',
                  ),
                  trailing: Chip(
                    label: Text(
                      order.status,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: _getStatusColor(order.status),
                  ),
                  isThreeLine: true,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => OrderDetailsScreen(orderId: order.id!),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- FUNCIÓN DE COLOR ACTUALIZADA ---
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pagado':
        return Colors.green;
      case 'en_preparacion':
        return Colors.orange;
      case 'listo_para_entrega': // <-- NUEVO ESTADO
        return Colors.blueAccent;
      case 'listo_para_retirar':
        return Colors.blue;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
