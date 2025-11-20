// lib/features/orders/order_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pideqr/core/models/pedido_item.dart';
import 'package:pideqr/features/menu/menu_providers.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'order_provider.dart';

final orderItemsProvider = StreamProvider.autoDispose.family<List<PedidoItem>, String>((ref, orderId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamOrderItems(orderId);
});

class OrderDetailsScreen extends ConsumerWidget {
  final String orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsyncValue = ref.watch(orderItemsProvider(orderId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle del Pedido #${orderId.substring(0, 6)}...'),
      ),
      body: itemsAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error al cargar los productos: $error')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Este pedido no tiene productos.'));
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Cantidad: ${item.quantity}\nPrecio unitario: \$${item.unitPrice.toStringAsFixed(0)}'),
                      trailing: Text('Subtotal: \$${item.subtotal.toStringAsFixed(0)}'),
                      isThreeLine: true,
                    );
                  },
                ),
              ),
              // --- BLOQUE DE QR ENVUELTO EN SAFEAREA ---
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0), // Reducimos el padding vertical
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'ID de la Transacción',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          color: Colors.white,
                          child: QrImageView(
                            data: orderId,
                            version: QrVersions.auto,
                            size: 180.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
