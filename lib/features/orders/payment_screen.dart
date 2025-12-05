import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pideqr/core/models/pedido.dart';
import 'package:pideqr/features/auth/auth_checker.dart';
import 'package:pideqr/features/auth/auth_providers.dart';
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

  Future<void> _showSuccessDialogAndRedirect() async {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false, // El usuario no puede cerrarlo tocando fuera
      builder: (BuildContext context) {
        return const PopScope(
          canPop: false, // Previene que el botón "atrás" del sistema lo cierre
          child: Dialog(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40.0, horizontal: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.green, size: 80),
                  SizedBox(height: 24),
                  Text(
                    '¡Pago Exitoso!',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tu pedido ha sido registrado.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    // Espera 3 segundos antes de continuar
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      // Navega a la pantalla de inicio y elimina todas las rutas anteriores
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  Future<void> _processPayment() async {
    setState(() {
      _isProcessing = true;
    });

    final carrito = ref.read(orderNotifierProvider);
    final firestoreService = ref.read(firestoreServiceProvider);
    final userId = ref.read(userModelProvider).value?.uid;
    final tiendaId = ref.read(currentTiendaIdProvider);

    if (userId == null || tiendaId.isEmpty) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: No se pudo identificar al usuario o la tienda.')),
        );
      }
      setState(() => _isProcessing = false);
      return;
    }

    final nuevoPedido = Pedido(
      userId: userId,
      tiendaId: tiendaId,
      total: carrito.subtotal,
      timestamp: DateTime.now(),
      status: OrderStatus.pagado.name,
    );

    try {
      await firestoreService.placeOrder(
        pedido: nuevoPedido,
        items: carrito.items,
      );
      
      ref.read(orderNotifierProvider.notifier).clearCart();

      // --- NUEVO FLUJO DE ÉXITO ---
      await _showSuccessDialogAndRedirect();

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar el pedido: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final carrito = ref.watch(orderNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Procesando Pago'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: _isProcessing
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _processPayment,
                      child: const Text('Pagar Ahora (Simulación)', style: TextStyle(fontSize: 18)),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
