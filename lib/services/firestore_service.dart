// lib/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/models/producto.dart';
import '../core/models/pedido.dart';
import '../core/models/pedido_item.dart';
import '../core/models/tienda.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<Tienda> streamTienda(String tiendaId) {
    return _db
        .collection('tiendas')
        .doc(tiendaId)
        .snapshots()
        .map((snapshot) => Tienda.fromMap(snapshot.data() ?? {}, snapshot.id));
  }

  Stream<List<Producto>> streamProductosPorTienda(String tiendaId) {
    return _db
        .collection('tiendas')
        .doc(tiendaId)
        .collection('productos')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Producto.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<Pedido>> streamUserOrders(String userId) {
    return _db
        .collection('pedidos')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Pedido.fromMap(doc.data(), doc.id))
            .toList());
  }

  // --- NUEVA FUNCIÓN PARA OBTENER LOS ITEMS DE UN PEDIDO ---
  Stream<List<PedidoItem>> streamOrderItems(String orderId) {
    return _db
        .collection('pedidos')
        .doc(orderId)
        .collection('items')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PedidoItem.fromMap(doc.data()))
            .toList());
  }
  // -----------------------------------------------------

  Stream<List<Pedido>> streamPaidOrdersForStore(String tiendaId) {
    return _db
        .collection('pedidos')
        .where('tiendaId', isEqualTo: tiendaId)
        .where('status', isEqualTo: 'pagado')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Pedido.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) {
    return _db.collection('pedidos').doc(orderId).update({'status': newStatus});
  }

  Future<String> saveNewPedido({
    required Pedido pedido, 
    required List<PedidoItem> items,
  }) async {
    final pedidoRef = await _db.collection('pedidos').add(pedido.toMap());
    final pedidoId = pedidoRef.id;

    final batch = _db.batch(); 
    
    for (var item in items) {
      final itemRef = _db.collection('pedidos').doc(pedidoId).collection('items').doc();
      batch.set(itemRef, item.toMap());
    }
    
    await batch.commit();
    
    return pedidoId;
  }
}
