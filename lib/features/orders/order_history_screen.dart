// lib/features/orders/order_history_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pideqr/core/models/pedido.dart';
import 'package:pideqr/features/orders/order_details_screen.dart';
import 'order_provider.dart';

class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  String _getReadableStatus(String status) {
    return status.replaceAll('_', ' ').replaceFirstMapped(
      RegExp(r'\w'), (match) => match.group(0)!.toUpperCase(),
    );
  }

  // --- FUNCIÓN PARA OBTENER EL PESO DE CADA ESTADO ---
  int _getStatusSortWeight(String status) {
    switch (status.toLowerCase()) {
      case 'listo_para_entrega':
        return 1;
      case 'en_preparacion':
        return 2;
      case 'pagado':
        return 3;
      case 'entregado':
        return 4;
      default:
        return 5; // Otros estados al final
    }
  }

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

          // --- LÓGICA DE ORDENAMIENTO ---
          final sortedOrders = List<Pedido>.from(orders);
          sortedOrders.sort((a, b) {
            int weightA = _getStatusSortWeight(a.status);
            int weightB = _getStatusSortWeight(b.status);
            return weightA.compareTo(weightB);
          });

          return ListView.builder(
            itemCount: sortedOrders.length,
            itemBuilder: (context, index) {
              final order = sortedOrders[index];
              final formattedDate = DateFormat('dd/MM/yyyy, hh:mm a').format(order.timestamp);
              final displayId = '#...${order.id!.substring(order.id!.length - 6)}';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text('Pedido $displayId', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Fecha: $formattedDate\nTotal: \$${order.total.toStringAsFixed(0)}'),
                  trailing: Chip(
                    label: Text(
                      _getReadableStatus(order.status),
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'listo_para_entrega':
        return Colors.blueAccent;
      case 'en_preparacion':
        return Colors.orange;
      case 'pagado':
        return Colors.green;
      case 'entregado':
        return Colors.grey; // <-- COLOR ACTUALIZADO
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
