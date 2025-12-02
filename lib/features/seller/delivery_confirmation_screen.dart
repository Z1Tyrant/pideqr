// lib/features/seller/delivery_confirmation_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pideqr/core/models/pedido.dart';
import 'package:pideqr/features/auth/auth_providers.dart';
import 'package:pideqr/features/menu/menu_providers.dart';
import 'package:pideqr/features/orders/order_details_screen.dart';

class DeliveryConfirmationScreen extends ConsumerStatefulWidget {
  final Pedido order;
  const DeliveryConfirmationScreen({super.key, required this.order});

  @override
  ConsumerState<DeliveryConfirmationScreen> createState() => _DeliveryConfirmationScreenState();
}

class _DeliveryConfirmationScreenState extends ConsumerState<DeliveryConfirmationScreen> {
  double _sliderValue = 0.0;
  bool _isConfirmed = false;

  void _onSliderChanged(double value) {
    setState(() {
      _sliderValue = value;
      if (value == 1.0 && !_isConfirmed) {
        _isConfirmed = true;
        _confirmDelivery();
      }
    });
  }

  Future<void> _confirmDelivery() async {
    final firestoreService = ref.read(firestoreServiceProvider);
    await firestoreService.updateOrderStatus(widget.order.id!, 'entregado');

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('¡Pedido marcado como entregado!'), backgroundColor: Colors.green),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final customerData = ref.watch(userDataProvider(widget.order.userId));
    final orderItems = ref.watch(orderItemsProvider(widget.order.id!));

    return Scaffold(
      appBar: AppBar(title: const Text('Confirmar Entrega')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pedido #${widget.order.id!.substring(widget.order.id!.length - 6)}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  customerData.when(
                    data: (customer) => Text('Cliente: ${customer?.name ?? 'No especificado'}', style: Theme.of(context).textTheme.titleMedium),
                    loading: () => const Text('Cargando cliente...'),
                    error: (e, st) => const SizedBox.shrink(),
                  ),
                  const Divider(height: 24),
                ],
              ),
            ),
            const Text('Productos a entregar:', style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: orderItems.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => const Center(child: Text('No se pudieron cargar los productos.')),
                data: (items) => ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      title: Text(item.productName),
                      trailing: Text('x${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    );
                  },
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Column(
                  children: [
                    const Text('Desliza para confirmar la entrega', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 16),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 60.0,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 30.0),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 40.0),
                        activeTrackColor: Colors.green.withOpacity(0.5),
                        inactiveTrackColor: Colors.grey.shade300,
                        thumbColor: Colors.green,
                      ),
                      child: Slider(
                        value: _sliderValue,
                        onChanged: _onSliderChanged,
                        min: 0.0,
                        max: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
