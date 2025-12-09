import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pideqr/core/models/pedido.dart';
import 'package:pideqr/core/models/producto.dart';
import 'package:pideqr/features/auth/auth_providers.dart';

// --- Modelo para un item dentro del carrito ---
class OrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double subtotal;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  }) : subtotal = quantity * unitPrice;
  
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'subtotal': subtotal,
    };
  }
}

// --- Modelo para el estado del carrito ---
class OrderState {
  final List<OrderItem> items;
  final String? currentTiendaId;
  final double subtotal;
  final int totalItems;

  OrderState({
    this.items = const [],
    this.currentTiendaId,
  })  : subtotal = items.fold(0, (sum, item) => sum + item.subtotal),
        totalItems = items.fold(0, (sum, item) => sum + item.quantity);

  OrderState copyWith({
    List<OrderItem>? items,
    String? currentTiendaId,
  }) {
    return OrderState(
      items: items ?? this.items,
      currentTiendaId: currentTiendaId ?? this.currentTiendaId,
    );
  }
}

// --- Notifier para manejar la lógica del carrito ---
class OrderNotifier extends StateNotifier<OrderState> {
  OrderNotifier() : super(OrderState());

  void addItemToCart({
    required Producto producto,
    required int quantity,
    required String tiendaId,
  }) {
    if (state.currentTiendaId != null && state.currentTiendaId != tiendaId) {
      throw Exception('Solo puedes añadir productos de una tienda a la vez.');
    }

    final updatedItems = List<OrderItem>.from(state.items);
    final existingItemIndex = updatedItems.indexWhere((item) => item.productId == producto.id);

    if (existingItemIndex != -1) {
      final existingItem = updatedItems[existingItemIndex];
      final newQuantity = existingItem.quantity + quantity;

      if (newQuantity > producto.stock) {
        throw Exception('No puedes añadir más productos de los que hay en stock.');
      }

      updatedItems[existingItemIndex] = OrderItem(
        productId: existingItem.productId,
        productName: existingItem.productName,
        quantity: newQuantity,
        unitPrice: existingItem.unitPrice,
      );
    } else {
      if (quantity > producto.stock) {
        throw Exception('No puedes añadir más productos de los que hay en stock.');
      }
      updatedItems.add(OrderItem(
        productId: producto.id,
        productName: producto.name,
        quantity: quantity,
        unitPrice: producto.price,
      ));
    }
    
    state = state.copyWith(items: updatedItems, currentTiendaId: tiendaId);
  }

  void decrementItemQuantity(String productId) {
    final updatedItems = List<OrderItem>.from(state.items);
    final itemIndex = updatedItems.indexWhere((item) => item.productId == productId);

    if (itemIndex != -1) {
      final item = updatedItems[itemIndex];
      if (item.quantity > 1) {
        updatedItems[itemIndex] = OrderItem(
          productId: item.productId,
          productName: item.productName,
          quantity: item.quantity - 1,
          unitPrice: item.unitPrice,
        );
      } else {
        updatedItems.removeAt(itemIndex);
      }
    }

    state = state.copyWith(items: updatedItems);
  }

  void clearCart() {
    state = OrderState();
  }
}

// --- Provider para acceder al notificador del carrito ---
final orderNotifierProvider = StateNotifierProvider<OrderNotifier, OrderState>((ref) {
  return OrderNotifier();
});

// --- Provider para obtener los pedidos ACTIVOS del usuario ---
final activeUserOrdersProvider = StreamProvider.autoDispose<List<Pedido>>((ref) {
  final userId = ref.watch(userModelProvider).value?.uid;
  if (userId == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('pedidos')
      .where('userId', isEqualTo: userId)
      .where('status', whereNotIn: ['entregado', 'cancelado'])
      .orderBy('status')
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => Pedido.fromMap(doc.data(), doc.id)).toList());
});

// --- Provider RECONSTRUIDO para el HISTORIAL de pedidos del usuario ---
final userOrdersProvider = StreamProvider.autoDispose<List<Pedido>>((ref) {
  final userId = ref.watch(userModelProvider).value?.uid;
  if (userId == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('pedidos')
      .where('userId', isEqualTo: userId)
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => Pedido.fromMap(doc.data(), doc.id)).toList());
});

// --- Provider RECONSTRUIDO para los pedidos PENDIENTES del Vendedor ---
final pendingOrdersProvider = StreamProvider.autoDispose<List<Pedido>>((ref) {
  final user = ref.watch(userModelProvider).value;
  if (user == null || user.tiendaId == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('pedidos')
      .where('tiendaId', isEqualTo: user.tiendaId)
      .where('status', whereIn: ['pagado', 'en_preparacion'])
      .orderBy('timestamp', descending: false)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => Pedido.fromMap(doc.data(), doc.id)).toList());
});
