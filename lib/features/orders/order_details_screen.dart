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

import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:intl/intl.dart';

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

  Future<void> _printOrder(Pedido order, List<PedidoItem> items, BuildContext context) async {
    final doc = pw.Document();
    final customer = await ref.read(userDataProvider(order.userId).future);
    // --- OBTENER DATOS DE LA TIENDA ---
    final tienda = await ref.read(tiendaDetailsProvider(order.tiendaId).future);

    const pageFormat = PdfPageFormat(58 * PdfPageFormat.mm, double.infinity, marginAll: 5 * PdfPageFormat.mm);

    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // --- TÍTULO Y DATOS MEJORADOS ---
              pw.Text(tienda.name, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Divider(thickness: 1),
              pw.Text('Pedido: #${order.id!.substring(order.id!.length - 6)}'),
              pw.Text('Cliente: ${customer?.name ?? 'N/A'}'),
              if (order.preparedBy != null && order.preparedBy!.isNotEmpty)
                pw.Text('Procesado por: ${order.preparedBy}'),
              pw.Text('Fecha: ${DateFormat('dd/MM/yy hh:mm').format(order.timestamp)}'),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 10),
              pw.Column(
                children: items.map((item) => pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(child: pw.Text('${item.quantity}x ${item.productName}')),
                    pw.Text('\$${item.subtotal.toStringAsFixed(0)}'),
                  ]
                )).toList(),
              ),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 1),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text('TOTAL: \$${order.total.toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              )
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => doc.save());
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
        actions: [
          if (currentUser?.role == UserRole.vendedor)
            orderDetailsAsync.when(
              data: (order) => itemsAsync.when(
                data: (items) => IconButton(
                  icon: const Icon(Icons.print),
                  onPressed: () => _printOrder(order, items, context),
                  tooltip: 'Imprimir Comanda',
                ),
                loading: () => const SizedBox.shrink(),
                error: (e, st) => const SizedBox.shrink(),
              ),
              loading: () => const SizedBox.shrink(),
              error: (e, st) => const SizedBox.shrink(),
            )
        ],
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
                                ref.read(firestoreServiceProvider).updateOrderStatus(widget.orderId, 'listo_para_entrega');
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
