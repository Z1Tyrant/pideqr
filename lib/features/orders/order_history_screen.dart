// lib/features/orders/order_history_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // Para formatear fechas
import 'order_provider.dart';

class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escucha el nuevo provider que creamos para el historial de pedidos
    final ordersAsyncValue = ref.watch(userOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Pedidos'),
      ),
      body: ordersAsyncValue.when(
        // --- 1. Estado de Carga ---
        loading: () => const Center(child: CircularProgressIndicator()),
        
        // --- 2. Estado de Error ---
        error: (error, stack) => Center(
          child: Text('Error al cargar el historial: $error'),
        ),
        
        // --- 3. Estado con Datos ---
        data: (orders) {
          // Si la lista de pedidos está vacía
          if (orders.isEmpty) {
            return const Center(
              child: Text(
                'Aún no has realizado ningún pedido.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }
          
          // Si hay pedidos, los muestra en una lista
          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              // Formateador para la fecha
              final formattedDate = DateFormat('dd/MM/yyyy, hh:mm a').format(order.timestamp);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(
                    'Pedido #${order.id?.substring(0, 6)}...', // Muestra una parte del ID
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
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Función de ayuda para dar un color a cada estado del pedido
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pagado':
        return Colors.green;
      case 'en_preparacion':
        return Colors.orange;
      case 'listo_para_retirar':
        return Colors.blue;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
