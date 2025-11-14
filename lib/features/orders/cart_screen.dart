// lib/features/orders/cart_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/pedido.dart'; // Para PedidoStatus
import '../auth/auth_providers.dart';
import 'order_provider.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Observar el estado del carrito
    final carrito = ref.watch(orderNotifierProvider);
    final orderNotifier = ref.read(orderNotifierProvider.notifier);
    
    // El ID del usuario autenticado (necesario para el pedido)
    final userId = ref.watch(userModelProvider).value?.uid;

    // Si el carrito está vacío, no hay nada que mostrar
    if (carrito.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tu Pedido')),
        body: const Center(child: Text('El carrito está vacío.')),
      );
    }
    
    // Función de simulación de pago
    void submitOrder() async {
      if (userId == null || carrito.currentLocatarioId == null) return;

      // 1. Construir el objeto Pedido
      final newPedido = Pedido(
        userId: userId,
        locatarioId: carrito.currentLocatarioId!,
        totalAmount: carrito.subtotal,
        status: PedidoStatus.pagado, // Simular que el pago es exitoso
        createdAt: DateTime.now(),
      );

      // 2. Aquí llamaríamos a la función de guardado en Firestore.
      // 🚨 Pendiente: Implementar el guardado real en FirestoreService
      
      // 3. Limpiar el carrito después de la "simulación" de pago exitosa
      orderNotifier.clearCart(); 

      // 4. Redirigir a la pantalla de confirmación/QR de la orden
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Pago simulado exitoso!')),
      );
      // TODO: Navegar a OrderConfirmationScreen(pedidoId: id)
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Confirmar Pedido')),
      body: Column(
        children: [
          // --- Lista de Ítems del Carrito ---
          Expanded(
            child: ListView.builder(
              itemCount: carrito.items.length,
              itemBuilder: (context, index) {
                final item = carrito.items[index];
                return ListTile(
                  title: Text('${item.productName} x ${item.quantity}'),
                  subtitle: Text('Precio unitario: \$${item.unitPrice.toStringAsFixed(0)}'),
                  trailing: Text('\$${item.subtotal.toStringAsFixed(0)}'),
                  
                );
              },
            ),
          ),
          
          // --- Resumen y Botón de Pago ---
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'TOTAL: \$${carrito.subtotal.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: submitOrder,
                  icon: const Icon(Icons.payment),
                  label: const Text('Simular Pago y Ordenar'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}