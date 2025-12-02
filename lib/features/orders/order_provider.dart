// lib/features/orders/order_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/pedido.dart';
import '../../core/models/pedido_item.dart';
import '../../core/models/producto.dart';
import '../../core/models/user_model.dart';
import '../../services/firestore_service.dart';
import '../auth/auth_providers.dart';
import '../menu/menu_providers.dart'; 

class Carrito { 
  final List<PedidoItem> items;
  final String? currentTiendaId;

  Carrito({
    required this.items,
    this.currentTiendaId,
  });

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.subtotal);
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

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

class OrderNotifier extends Notifier<Carrito> { 
  @override
  Carrito build() {
    return Carrito(items: []);
  }

  void addItemToCart({
    required Producto producto,
    required int quantity,
    required String tiendaId,
  }) {
    if (state.currentTiendaId != null && state.currentTiendaId != tiendaId) {
      throw Exception('El carrito ya contiene productos de otra tienda.');
    }

    final existingIndex = state.items.indexWhere((item) => item.productId == producto.id);
    final currentQuantityInCart = existingIndex != -1 ? state.items[existingIndex].quantity : 0;

    if (currentQuantityInCart + quantity > producto.stock) {
      throw Exception('No hay suficiente stock. Disponibles: ${producto.stock}');
    }

    if (existingIndex != -1) {
      final updatedItems = List<PedidoItem>.from(state.items);
      final existingItem = updatedItems[existingIndex];
      final newItem = existingItem.copyWith(quantity: existingItem.quantity + quantity);
      updatedItems[existingIndex] = newItem;
      state = state.copyWith(items: updatedItems);
    } else {
      final newItem = PedidoItem(
        productId: producto.id,
        productName: producto.name,
        unitPrice: producto.price,
        quantity: quantity,
      );
      state = state.copyWith(
        items: [...state.items, newItem],
        currentTiendaId: tiendaId,
      );
    }
  }

  // --- NUEVA FUNCIÓN PARA DECREMENTAR ---
  void decrementItemQuantity(String productId) {
    final existingIndex = state.items.indexWhere((item) => item.productId == productId);
    if (existingIndex == -1) return; // No hace nada si el item no existe

    final updatedItems = List<PedidoItem>.from(state.items);
    final existingItem = updatedItems[existingIndex];

    if (existingItem.quantity > 1) {
      // Si hay más de 1, solo reduce la cantidad
      final newItem = existingItem.copyWith(quantity: existingItem.quantity - 1);
      updatedItems[existingIndex] = newItem;
      state = state.copyWith(items: updatedItems);
    } else {
      // Si solo queda 1, elimina el producto del carrito
      removeItemFromCart(productId);
    }
  }

  void removeItemFromCart(String productId) {
    final updatedItems = state.items.where((item) => item.productId != productId).toList();
    final newTiendaId = updatedItems.isEmpty ? null : state.currentTiendaId;
    state = state.copyWith(items: updatedItems, currentTiendaId: newTiendaId);
  }

  void clearCart() {
    state = Carrito(items: []);
  }
}

final orderNotifierProvider = NotifierProvider<OrderNotifier, Carrito>(
  OrderNotifier.new,
);

final userOrdersProvider = StreamProvider.autoDispose<List<Pedido>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final user = ref.watch(authStateChangesProvider).value;

  if (user != null) {
    return firestoreService.streamUserOrders(user.uid);
  }
  
  return Stream.value([]);
});

final pendingOrdersProvider = StreamProvider.autoDispose<List<Pedido>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final userModel = ref.watch(userModelProvider).value;

  if (userModel != null && userModel.role == UserRole.vendedor && userModel.tiendaId != null) {
    return firestoreService.streamPendingOrdersForStore(userModel.tiendaId!);
  }
  
  return Stream.value([]);
});
