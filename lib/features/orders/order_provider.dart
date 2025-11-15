// lib/features/orders/order_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/pedido_item.dart';
import '../../core/models/producto.dart'; // Necesario para la función addItemToCart

// --- 1. Estado del Carrito (Actualizado) ---

class Carrito {
  final List<PedidoItem> items;
  // Almacena el ID de la tienda actual. Solo se permiten items de una sola tienda.
  final String? currentTiendaId; 

  Carrito({
    required this.items,
    this.currentTiendaId,
  });

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.subtotal);

  Carrito copyWith({
    List<PedidoItem>? items,
    String? currentTiendaId,
  }) {
    return Carrito(
      items: items ?? this.items,
      currentTiendaId: currentTiendaId ?? this.currentTiendaId,
    );
  }
}

// --- 2. Controlador de Lógica (OrderNotifier - Actualizado) ---

class OrderNotifier extends Notifier<Carrito> {
  @override
  Carrito build() {
    return Carrito(items: []);
  }

  // --- FUNCIÓN addItemToCart ACTUALIZADA ---
  void addItemToCart({
    required Producto producto,
    required int quantity,
    required String tiendaId, // <-- Parámetro nuevo y requerido
  }) {
    // 1. Verificar si hay items de otra tienda
    if (state.currentTiendaId != null && state.currentTiendaId != tiendaId) {
      throw Exception('El carrito ya contiene productos de otra tienda.');
    }

    final existingIndex = state.items.indexWhere(
      (item) => item.productId == producto.id,
    );
    
    final currentQuantityInCart = existingIndex != -1 ? state.items[existingIndex].quantity : 0;

    // 2. NUEVO: Verificar si hay stock suficiente
    if (currentQuantityInCart + quantity > producto.stock) {
      throw Exception('No hay suficiente stock. Disponibles: ${producto.stock}');
    }

    // 3. Lógica para añadir o actualizar (se mantiene similar)
    if (existingIndex != -1) {
      // Ítem existe: actualizar la cantidad
      final updatedItems = List<PedidoItem>.from(state.items);
      final existingItem = updatedItems[existingIndex];
      final newItem = existingItem.copyWith(quantity: existingItem.quantity + quantity);
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
        currentTiendaId: tiendaId, // Asignar la tienda
      );
    }
  }

  void removeItemFromCart(String productId) {
    final updatedItems =
        state.items.where((item) => item.productId != productId).toList();

    final newTiendaId = updatedItems.isEmpty ? null : state.currentTiendaId;

    state = state.copyWith(
      items: updatedItems,
      currentTiendaId: newTiendaId,
    );
  }

  void clearCart() {
    state = Carrito(items: []);
  }
}

// --- 3. Provider Público ---

final orderNotifierProvider = NotifierProvider<OrderNotifier, Carrito>(
  OrderNotifier.new,
);
