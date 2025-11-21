// lib/features/seller/seller_history_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pideqr/core/models/user_model.dart';
import 'package:pideqr/features/auth/auth_providers.dart';
import 'package:pideqr/features/menu/menu_providers.dart';
import 'package:pideqr/features/orders/order_details_screen.dart';
import 'package:pideqr/core/models/pedido.dart';

// 1. Provider para obtener el historial de pedidos entregados del vendedor
final deliveredOrdersProvider = StreamProvider.autoDispose<List<Pedido>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final userModel = ref.watch(userModelProvider).value;

  // Solo obtenemos datos si es un vendedor con tienda asignada
  if (userModel != null && userModel.role == UserRole.vendedor && userModel.tiendaId != null) {
    return firestoreService.streamDeliveredOrdersForStore(userModel.tiendaId!);
  }
  
  return Stream.value([]);
});

// 2. Pantalla para mostrar el historial
class SellerHistoryScreen extends ConsumerWidget {
  const SellerHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsyncValue = ref.watch(deliveredOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Entregas'),
      ),
      body: ordersAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(
              child: Text('Aún no se han completado entregas.', style: TextStyle(fontSize: 16, color: Colors.grey)),
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
                  title: Text('Pedido #${order.id?.substring(0, 6)}...', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Fecha: $formattedDate\nTotal: \$${order.total.toStringAsFixed(0)}'),
                  trailing: const Icon(Icons.check_circle, color: Colors.green),
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
}
