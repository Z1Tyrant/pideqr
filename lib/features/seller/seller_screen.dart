// lib/features/seller/seller_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pideqr/core/models/pedido.dart';
import 'package:pideqr/features/auth/auth_providers.dart';
import 'package:pideqr/features/auth/profile_screen.dart';
import 'package:pideqr/features/orders/order_details_screen.dart';
import 'package:pideqr/features/orders/order_provider.dart';
import 'package:pideqr/features/menu/menu_providers.dart';
import 'package:pideqr/features/seller/seller_history_screen.dart';
import 'package:pideqr/features/seller/seller_lookup_scanner.dart';

class SellerScreen extends ConsumerWidget {
  const SellerScreen({super.key});

  int _getStatusSortWeight(String status) {
    if (status == OrderStatus.en_preparacion.name) return 1;
    if (status == OrderStatus.pagado.name) return 2;
    if (status == OrderStatus.listo_para_entrega.name) return 3;
    return 4;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsyncValue = ref.watch(pendingOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedidos Pendientes'),
        actions: [
          IconButton(icon: const Icon(Icons.person), tooltip: 'Mi Perfil', onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ProfileScreen()))),
          IconButton(icon: const Icon(Icons.history), tooltip: 'Historial de Entregas', onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SellerHistoryScreen()))),
          IconButton(icon: const Icon(Icons.logout), tooltip: 'Cerrar Sesión', onPressed: () => ref.read(authServiceProvider).signOut()),
        ],
      ),
      body: ordersAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error al cargar pedidos: $error')),
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(child: Text('No hay pedidos pendientes.', style: TextStyle(fontSize: 18, color: Colors.grey)));
          }

          final sortedOrders = List<Pedido>.from(orders);
          sortedOrders.sort((a, b) {
            int weightA = _getStatusSortWeight(a.status);
            int weightB = _getStatusSortWeight(b.status);
            if (weightA != weightB) {
              return weightA.compareTo(weightB);
            }
            return a.timestamp.compareTo(b.timestamp);
          });

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: sortedOrders.length,
            itemBuilder: (context, index) => SellerOrderCard(order: sortedOrders[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Buscar Pedido'),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const SellerLookupScannerScreen()),
          );
        },
      ),
    );
  }
}

class SellerOrderCard extends ConsumerStatefulWidget {
  final Pedido order;
  const SellerOrderCard({required this.order, super.key});

  @override
  ConsumerState<SellerOrderCard> createState() => _SellerOrderCardState();
}

class _SellerOrderCardState extends ConsumerState<SellerOrderCard> {
  bool _isLoading = false;

  String _getReadableStatus(Pedido order) {
    String statusText = order.status.replaceAll('_', ' ').replaceFirstMapped(
      RegExp(r'\w'), (match) => match.group(0)!.toUpperCase(),
    );

    if (order.preparedBy != null && order.preparedBy!.isNotEmpty) {
      statusText += ' (por ${order.preparedBy})';
    }

    return statusText;
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd/MM, hh:mm a').format(widget.order.timestamp);
    final displayId = '#...${widget.order.id!.substring(widget.order.id!.length - 6)}';
    final seller = ref.watch(userModelProvider).value;
    final customerData = ref.watch(userDataProvider(widget.order.userId));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pedido $displayId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            customerData.when(
              data: (customer) => Text('Cliente: ${customer?.name ?? 'No especificado'}', style: Theme.of(context).textTheme.bodyMedium),
              loading: () => const Text('Cargando cliente...'),
              error: (e, st) => const SizedBox.shrink(),
            ),
            const Divider(),
            Text('Fecha: $formattedDate'),
            Text('Total: \$${widget.order.total.toStringAsFixed(0)}'),
            const SizedBox(height: 16),
            
            if (widget.order.status == OrderStatus.pagado.name)
              SizedBox(
                width: double.infinity,
                child: _isLoading 
                  ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.pan_tool_sharp),
                      label: const Text('Reclamar y Preparar'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      onPressed: () async {
                        // --- COMPROBACIÓN DE NULABILIDAD AÑADIDA ---
                        if (seller == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Error: No se pudo cargar tu perfil de vendedor.'), backgroundColor: Colors.red),
                          );
                          return;
                        }

                        if (seller.deliveryZone == null) {
                           ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Error: No tienes una zona de entrega asignada.'), backgroundColor: Colors.red),
                          );
                          return;
                        }

                        setState(() { _isLoading = true; });
                        try {
                          final success = await ref.read(firestoreServiceProvider).claimOrderAndUpdateStock(
                            orderId: widget.order.id!,
                            sellerName: seller.name,
                            sellerZone: seller.deliveryZone,
                          );
                          if (success && mounted) {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => OrderDetailsScreen(orderId: widget.order.id!)),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
                            );
                          }
                        } finally {
                          if (mounted) {
                             setState(() { _isLoading = false; });
                          }
                        }
                      },
                    ),
              )
            else if (widget.order.status == OrderStatus.en_preparacion.name)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.kitchen),
                  label: const Text('Continuar Preparación'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => OrderDetailsScreen(orderId: widget.order.id!)),
                    );
                  },
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: _getStatusColor(widget.order.status),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getReadableStatus(widget.order),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status == OrderStatus.pagado.name) return Colors.green;
    if (status == OrderStatus.en_preparacion.name) return Colors.deepOrange;
    if (status == OrderStatus.listo_para_entrega.name) return Colors.orangeAccent;
    return Colors.grey;
  }
}
