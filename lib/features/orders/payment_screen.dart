// lib/features/orders/payment_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pideqr/core/models/pedido.dart';
import 'package:pideqr/features/auth/auth_providers.dart';
import 'package:pideqr/features/orders/confirmation_screen.dart';
import 'package:pideqr/services/firestore_service.dart';
import '../menu/menu_providers.dart';
import 'order_provider.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  bool _isProcessing = false;

  Future<void> _processPayment() async {
    setState(() {
      _isProcessing = true;
    });

    final carrito = ref.read(orderNotifierProvider);
    final firestoreService = ref.read(firestoreServiceProvider);
    
    // --- CORREGIDO: Usamos el provider correcto para obtener el usuario ---
    final user = ref.read(authStateChangesProvider).value;
    final userId = user?.uid;
    // ------------------------------------------------------------------

    final tiendaId = ref.read(currentTiendaIdProvider);

    if (userId == null || tiendaId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No se pudo identificar al usuario o la tienda.')),
      );
      setState(() {
        _isProcessing = false;
      });
      return;
    }

    // 1. Crear el objeto Pedido
    final nuevoPedido = Pedido(
      userId: userId,
      tiendaId: tiendaId,
      total: carrito.subtotal,
      timestamp: DateTime.now(),
      status: 'pagado', // Estado inicial
    );

    try {
      // 2. Guardar el pedido en Firestore
      final newOrderId = await firestoreService.saveNewPedido(
        pedido: nuevoPedido,
        items: carrito.items,
      );
      
      // 3. Limpiar el carrito local
      ref.read(orderNotifierProvider.notifier).clearCart();

      // 4. Navegar a la pantalla de confirmación
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => ConfirmationScreen(orderId: newOrderId),
          ),
          (Route<dynamic> route) => false,
        );
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al procesar el pedido: $e')),
      );
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final carrito = ref.watch(orderNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmar y Pagar'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Resumen del Pedido', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 32),
            Text('Total de productos: ${carrito.totalItems}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            Text('Monto a pagar: \$${carrito.subtotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Spacer(),
            if (_isProcessing)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _processPayment,
                child: const Text('Pagar Ahora (Simulación)', style: TextStyle(fontSize: 18)),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
