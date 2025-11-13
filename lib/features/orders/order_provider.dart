// lib/features/orders/order_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/pedido_item.dart';
import '../../core/models/producto.dart'; // Necesario para la función addItemToCart

// --- 1. Estado del Carrito ---

class Carrito {
  final List<PedidoItem> items;
  // Almacena el ID del locatario actual. Solo se permiten items de un solo locatario.
  final String? currentLocatarioId; 

  Carrito({
    required this.items,
    this.currentLocatarioId,
  });

  // Cálculo rápido: subtotal de todos los ítems
  double get subtotal => items.fold(0.0, (sum, item) => sum + item.subtotal);

  // Método para crear una copia inmutable del estado (requerido por StateNotifier)
  Carrito copyWith({
    List<PedidoItem>? items,
    String? currentLocatarioId,
  }) {
    return Carrito(
      items: items ?? this.items,
      currentLocatarioId: currentLocatarioId ?? this.currentLocatarioId,
    );
  }
}

// --- 2. Controlador de Lógica (OrderNotifier) ---

class OrderNotifier extends StateNotifier<Carrito> {
  // Inicializa el estado con un carrito vacío.
  OrderNotifier() : super(Carrito(items: []));

  // Función para añadir o actualizar un producto en el carrito
  void addItemToCart({
    required Producto producto,
    required int quantity,
  }) {
    // 1. Verificar si hay items de otro locatario
    if (state.currentLocatarioId != null && state.currentLocatarioId != producto.locatarioId) {
      // Manejar esto como un error o una advertencia en la UI
      throw Exception('El carrito ya contiene productos de otro locatario.');
    }

    // 2. Buscar si el ítem ya existe
    final existingIndex = state.items.indexWhere(
      (item) => item.productId == producto.id,
    );

    if (existingIndex != -1) {
      // Ítem existe: actualizar la cantidad
      final updatedItems = List<PedidoItem>.from(state.items);
      final existingItem = updatedItems[existingIndex];
      final newItem = PedidoItem(
        productId: existingItem.productId,
        productName: existingItem.productName,
        unitPrice: existingItem.unitPrice,
        quantity: existingItem.quantity + quantity, // Aumentar cantidad
      );
      updatedItems[existingIndex] = newItem;
      
      state = state.copyWith(items: updatedItems);
    } else {
      // Ítem nuevo: añadir al carrito
      final newItem = PedidoItem(
        productId: producto.id,
        productName: producto.name,
        unitPrice: producto.price,
        quantity: quantity,
      );
      state = state.copyWith(
        items: [...state.items, newItem],
        currentLocatarioId: producto.locatarioId, // Asignar el locatario
      );
    }
  }

  // Función para eliminar un producto del carrito
  void removeItemFromCart(String productId) {
    final updatedItems = state.items.where((item) => item.productId != productId).toList();
    
    // Si el carrito queda vacío, limpiamos el ID del locatario
    final newLocatarioId = updatedItems.isEmpty ? null : state.currentLocatarioId;

    state = state.copyWith(
      items: updatedItems,
      currentLocatarioId: newLocatarioId,
    );
  }

  // Función para vaciar el carrito
  void clearCart() {
    state = Carrito(items: []);
  }
}

// --- 3. Provider Público ---

// Provider que expone la instancia del Notifier
final orderNotifierProvider = StateNotifierProvider<OrderNotifier, Carrito>((ref) {
  return OrderNotifier();
});