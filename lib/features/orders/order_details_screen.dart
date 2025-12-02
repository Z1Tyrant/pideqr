// lib/features/orders/order_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pideqr/core/models/pedido.dart';
import 'package:pideqr/core/models/pedido_item.dart';
import 'package:pideqr/core/models/user_model.dart';
import 'package:pideqr/features/auth/auth_providers.dart';
import 'package:pideqr/features/menu/menu_providers.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'order_provider.dart';

final orderItemsProvider = StreamProvider.autoDispose.family<List<PedidoItem>, String>((ref, orderId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamOrderItems(orderId);
});

final orderDetailsProvider = StreamProvider.autoDispose.family<Pedido, String>((ref, orderId) {
  return ref.watch(firestoreServiceProvider).streamOrder(orderId);
});

class OrderDetailsScreen extends ConsumerStatefulWidget {
  final String orderId;
  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends ConsumerState<OrderDetailsScreen> {
  List<bool> _checkedItems = [];
  bool _areAllItemsChecked = false;

  void _updateChecklistState() {
    setState(() {
      _areAllItemsChecked = _checkedItems.isNotEmpty && _checkedItems.every((item) => item == true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderDetailsAsync = ref.watch(orderDetailsProvider(widget.orderId));
    final itemsAsync = ref.watch(orderItemsProvider(widget.orderId));
    final currentUser = ref.watch(userModelProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: orderDetailsAsync.when(
          data: (order) => Text('Pedido #${order.id?.substring(order.id!.length - 6)}'),
          loading: () => const Text('Cargando...'),
          error: (e, st) => const Text('Detalle del Pedido'),
        ),
      ),
      body: orderDetailsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (order) {
          final sellerInfo = ref.watch(sellerForStoreProvider(order.tiendaId));

          return Column(
            children: [
              Expanded(
                child: itemsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Center(child: Text('Error al cargar productos: $e')),
                  data: (items) {
                    if (items.isEmpty) return const Center(child: Text('Este pedido no tiene productos.'));

                    bool isSellerAndViewingPreparingOrder = currentUser?.role == UserRole.vendedor && order.status == 'en_preparacion';

                    if (isSellerAndViewingPreparingOrder) {
                      if (_checkedItems.isEmpty && items.isNotEmpty) {
                        _checkedItems = List<bool>.filled(items.length, false);
                      }
                      return ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return CheckboxListTile(
                            title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Cantidad: ${item.quantity}'),
                            value: _checkedItems.length > index ? _checkedItems[index] : false,
                            onChanged: (bool? value) {
                              setState(() {
                                _checkedItems[index] = value ?? false;
                              });
                              _updateChecklistState();
                            },
                          );
                        },
                      );
                    } else {
                      return ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return ListTile(
                            title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Cantidad: ${item.quantity}'),
                          );
                        },
                      );
                    }
                  },
                ),
              ),
              
              if (currentUser?.role == UserRole.vendedor && order.status == 'en_preparacion')
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _areAllItemsChecked ? Colors.orangeAccent : Colors.grey,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: _areAllItemsChecked
                            ? () {
                                ref.read(firestoreServiceProvider).updateOrderStatus(
                                      widget.orderId,
                                      'listo_para_entrega',
                                    );
                                Navigator.of(context).pop();
                              }
                            : null,
                        child: const Text('Marcar como Listo para Entrega', style: TextStyle(fontSize: 18, color: Colors.white)),
                      ),
                    ),
                  ),
                )
              else if (currentUser?.role == UserRole.cliente && order.status != 'entregado')
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          sellerInfo.when(
                            data: (seller) => Text(
                              'Muestra este código QR a "${seller?.name ?? 'el vendedor'}"',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              textAlign: TextAlign.center,
                            ),
                            loading: () => const SizedBox.shrink(),
                            error: (e, st) => const Text('ID de la Transacción', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            color: Colors.white,
                            child: QrImageView(data: widget.orderId, version: QrVersions.auto, size: 180.0),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else 
                const SizedBox.shrink(),
            ],
          );
        },
      ),
    );
  }
}
