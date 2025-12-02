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
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: orders.length,
            itemBuilder: (context, index) => SellerOrderCard(order: orders[index]),
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
    final sellerName = ref.watch(userModelProvider).value?.name ?? 'Vendedor';
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
            
            if (widget.order.status == 'pagado')
              SizedBox(
                width: double.infinity,
                child: _isLoading 
                  ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.pan_tool_sharp),
                      label: const Text('Reclamar y Preparar'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      onPressed: () async {
                        setState(() { _isLoading = true; });
                        try {
                          final success = await ref.read(firestoreServiceProvider).claimOrderForPreparation(
                            orderId: widget.order.id!,
                            sellerName: sellerName,
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
    switch (status.toLowerCase()) {
      case 'pagado':
        return Colors.green;
      case 'en_preparacion':
        return Colors.deepOrange;
      case 'listo_para_entrega':
        return Colors.orangeAccent;
      default:
        return Colors.grey;
    }
  }
}
