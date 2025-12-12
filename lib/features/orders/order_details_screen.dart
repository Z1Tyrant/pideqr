import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pideqr/core/models/pedido.dart';
import 'package:pideqr/core/models/pedido_item.dart';
import 'package:pideqr/core/models/user_model.dart';
import 'package:pideqr/features/auth/auth_providers.dart';
import 'package:pideqr/features/menu/menu_providers.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

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
  final Map<String, bool> _checkedItems = {}; // Usamos un Mapa para asociar productId con su estado
  bool _areAllItemsChecked = false;

  void _onItemCheckChanged(String productId, bool isChecked, int totalItems) {
    setState(() {
      _checkedItems[productId] = isChecked;
      _areAllItemsChecked = _checkedItems.values.where((c) => c).length == totalItems;
    });
  }


  Future<void> _printOrder(Pedido order, List<PedidoItem> items) async {
    final doc = pw.Document();
    final customer = await ref.read(userDataProvider(order.userId).future);
    final tienda = await ref.read(tiendaDetailsProvider(order.tiendaId).future);
    const pageFormat = PdfPageFormat(58 * PdfPageFormat.mm, double.infinity, marginAll: 5 * PdfPageFormat.mm);

    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(tienda.name, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Divider(thickness: 1),
            pw.Text('Pedido: #${order.id!.substring(order.id!.length - 6)}'),
            pw.Text('Cliente: ${customer?.name ?? 'N/A'}'),
            if (order.deliveryZone != null && order.deliveryZone!.isNotEmpty)
              pw.Text('Zona Entrega: ${order.deliveryZone}'),
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
        ),
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
                data: (items) => IconButton(icon: const Icon(Icons.print), onPressed: () => _printOrder(order, items), tooltip: 'Imprimir Comanda'),
                loading: () => const SizedBox.shrink(), error: (_, __) => const SizedBox.shrink(),
              ),
              loading: () => const SizedBox.shrink(), error: (_, __) => const SizedBox.shrink(),
            )
        ],
      ),
      body: orderDetailsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error al cargar el pedido: $e')),
        data: (order) => Column(
          children: [
            Expanded(
              child: itemsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Error al cargar productos del pedido: $e')),
                data: (items) {
                  if (items.isEmpty) {
                    return const Center(child: Text('Este pedido no tiene productos.'));
                  }

                  bool isSellerView = currentUser?.role == UserRole.vendedor;
                  
                  // --- LÓGICA DE CHECKBOX ACTUALIZADA ---
                  return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return OrderItemDetailsTile(
                        item: item,
                        tiendaId: order.tiendaId,
                        isCheckable: isSellerView && order.status == OrderStatus.en_preparacion.name,
                        onCheckedChanged: (isChecked) => _onItemCheckChanged(item.productId, isChecked, items.length),
                      );
                    },
                  );
                },
              ),
            ),
            
            if (currentUser?.role == UserRole.vendedor && order.status == OrderStatus.en_preparacion.name)
              _buildMarkAsReadyButton(order) // <-- SE IMPLEMENTA ESTE WIDGET
            else if (currentUser?.role == UserRole.cliente)
              _buildQrCodeSection(order)
            else
              const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  // --- WIDGET COMPLETAMENTE IMPLEMENTADO ---
  Widget _buildMarkAsReadyButton(Pedido order) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Marcar como Listo para Entrega'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _areAllItemsChecked ? Colors.blueAccent : Colors.grey,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: !_areAllItemsChecked
              ? null // El botón está deshabilitado si no están todos marcados
              : () async {
                  // Lógica para actualizar el estado del pedido
                  try {
                    await ref.read(firestoreServiceProvider).updateOrderStatus(order.id!, OrderStatus.listo_para_entrega);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('¡Pedido actualizado! El cliente será notificado.'), backgroundColor: Colors.green),
                      );
                      Navigator.of(context).pop(); // Regresa a la pantalla anterior
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error al actualizar el pedido: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
        ),
      ),
    );
  }

  // --- WIDGET IMPLEMENTADO (SIN CAMBIOS FUNCIONALES) ---
  Widget _buildQrCodeSection(Pedido order) {
    if (order.status != OrderStatus.listo_para_entrega.name) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Column(
          children: [
            if (order.deliveryZone != null) Text('Retira tu pedido en: ${order.deliveryZone}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade800, fontSize: 16)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8), 
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
              child: QrImageView(data: order.id!, version: QrVersions.auto, size: 150.0),
            ),
            const SizedBox(height: 8),
            const Text('Muestra este QR al vendedor para la entrega', style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// --- WIDGET CONVERTIDO A STATEFULWIDGET ---
class OrderItemDetailsTile extends ConsumerStatefulWidget {
  final PedidoItem item;
  final String tiendaId;
  final bool isCheckable;
  final ValueChanged<bool>? onCheckedChanged;

  const OrderItemDetailsTile({
    super.key,
    required this.item,
    required this.tiendaId,
    this.isCheckable = false,
    this.onCheckedChanged,
  });

  @override
  ConsumerState<OrderItemDetailsTile> createState() => _OrderItemDetailsTileState();
}

class _OrderItemDetailsTileState extends ConsumerState<OrderItemDetailsTile> {
  bool _isChecked = false;

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailsProvider((tiendaId: widget.tiendaId, productoId: widget.item.productId)));

    return productAsync.when(
      loading: () => ListTile(title: Text(widget.item.productName), subtitle: const Text('Cargando detalles...'), leading: const CircularProgressIndicator()),
      error: (err, stack) => ListTile(
        title: Text('${widget.item.productName} (Desconocido)'),
        subtitle: const Text('Error al cargar detalles'),
        leading: const Icon(Icons.error_outline, color: Colors.red),
      ),
      data: (producto) {
        
        final tileContent = ListTile(
          leading: SizedBox(
            width: 56,
            height: 56,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: producto.imageUrl != null && producto.imageUrl!.isNotEmpty
                  ? Image.network(producto.imageUrl!, fit: BoxFit.cover, errorBuilder: (c, e, st) => const Icon(Icons.error))
                  : const Icon(Icons.image_not_supported, color: Colors.grey),
            ),
          ),
          title: Text(producto.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Cantidad: ${widget.item.quantity}'),
          trailing: Text('\$${widget.item.subtotal.toStringAsFixed(0)}'),
        );

        if (widget.isCheckable) {
          return CheckboxListTile(
            value: _isChecked,
            onChanged: (bool? value) {
              if (value == null) return;
              setState(() {
                _isChecked = value;
              });
              if (widget.onCheckedChanged != null) {
                widget.onCheckedChanged!(value);
              }
            },
            title: tileContent,
            controlAffinity: ListTileControlAffinity.leading,
          );
        } else {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: tileContent,
          );
        }
      },
    );
  }
}
