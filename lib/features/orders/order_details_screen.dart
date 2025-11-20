// lib/features/orders/order_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pideqr/core/models/pedido_item.dart';
import 'package:pideqr/features/menu/menu_providers.dart';
import 'package:qr_flutter/qr_flutter.dart'; // <-- NUEVA IMPORTACIÓN
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

          // Usamos Column para poder añadir el QR debajo de la lista
          return Column(
            children: [
              // La lista de productos ahora ocupa el espacio disponible
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
              // --- WIDGET DE QR AÑADIDO EN LA PARTE INFERIOR ---
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Column(
                    children: [
                      const Text('ID de la Transacción', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      QrImageView(
                        data: orderId, // El QR contiene el ID del pedido
                        version: QrVersions.auto,
                        size: 150.0,
                        backgroundColor: Colors.white,
                      ),
                    ],
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
