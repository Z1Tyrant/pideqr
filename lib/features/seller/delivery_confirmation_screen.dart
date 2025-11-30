// lib/features/seller/delivery_confirmation_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pideqr/core/models/pedido.dart';
import 'package:pideqr/features/menu/menu_providers.dart';

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

    // Cerramos la pantalla de confirmación (vuelve al escáner, que luego se cierra solo)
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd/MM, hh:mm a').format(widget.order.timestamp);
    final displayId = '#...${widget.order.id!.substring(widget.order.id!.length - 6)}';

    return Scaffold(
      appBar: AppBar(title: const Text('Confirmar Entrega')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Resumen del pedido
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pedido $displayId', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const Divider(height: 32),
                Text('Fecha: $formattedDate'),
                Text('Total: \$${widget.order.total.toStringAsFixed(0)}'),
                Text('Estado actual: ${widget.order.status}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ],
            ),

            // Slider de confirmación
            Column(
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
          ],
        ),
      ),
    );
  }
}
