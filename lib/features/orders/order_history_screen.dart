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

  int _getStatusSortWeight(String status) {
    if (status == OrderStatus.listo_para_entrega.name) return 1;
    if (status == OrderStatus.en_preparacion.name) return 2;
    if (status == OrderStatus.pagado.name) return 3;
    if (status == OrderStatus.entregado.name) return 4;
    return 5; // Otros estados al final
  }

  // --- FUNCIÓN DE MANEJO DE ERRORES ---
  void _showFriendlyError(BuildContext context, Object error) {
    String message = 'Ocurrió un error inesperado.';
    if (error.toString().contains('invalid-email')) {
      message = 'El formato del correo electrónico no es válido.';
    } else if (error.toString().contains('user-not-found') || error.toString().contains('wrong-password')) {
      message = 'Correo o contraseña incorrectos. Por favor, inténtalo de nuevo.';
    } else if (error.toString().contains('network-request-failed')) {
      message = 'Error de red. Por favor, revisa tu conexión a internet.';
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
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
        error: (error, stack) {
          // Usamos la nueva función de errores
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showFriendlyError(context, error);
          });
          return const Center(child: Text('No se pudo cargar el historial.'));
        },
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(
              child: Text('Aún no has realizado ningún pedido.', style: TextStyle(fontSize: 18, color: Colors.grey)),
            );
          }

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
                      MaterialPageRoute(builder: (context) => OrderDetailsScreen(orderId: order.id!)),
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
    if (status == OrderStatus.listo_para_entrega.name) return Colors.blueAccent;
    if (status == OrderStatus.en_preparacion.name) return Colors.orange;
    if (status == OrderStatus.pagado.name) return Colors.green;
    if (status == OrderStatus.entregado.name) return Colors.grey;
    if (status == OrderStatus.cancelado.name) return Colors.red;
    return Colors.grey;
  }
}
