import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pideqr/core/models/user_model.dart';
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

  Stream<List<Tienda>> streamAllStores() {
    return _db.collection('tiendas').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Tienda.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> updateStoreName(String tiendaId, String newName) {
    return _db.collection('tiendas').doc(tiendaId).update({'name': newName});
  }

  Future<void> createStore(String name) {
    return _db.collection('tiendas').add({'name': name});
  }

  // --- NUEVA FUNCIÓN PARA ELIMINAR TIENDAS Y SUS PRODUCTOS ---
  Future<void> deleteStore(String tiendaId) async {
    final storeRef = _db.collection('tiendas').doc(tiendaId);
    final productosSnapshot = await storeRef.collection('productos').get();

    final WriteBatch batch = _db.batch();

    for (final doc in productosSnapshot.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
    await storeRef.delete();
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

  Future<void> upsertProduct({
    required String tiendaId,
    String? productoId,
    required Map<String, dynamic> data,
  }) {
    final docRef = _db.collection('tiendas').doc(tiendaId).collection('productos').doc(productoId);
    return docRef.set(data, SetOptions(merge: true));
  }

  Stream<Pedido> streamOrder(String orderId) {
    return _db
        .collection('pedidos')
        .doc(orderId)
        .snapshots()
        .map((snapshot) => Pedido.fromMap(snapshot.data()!, snapshot.id));
  }

  Future<Pedido?> getOrderById(String orderId) async {
    final doc = await _db.collection('pedidos').doc(orderId).get();
    if (doc.exists) {
      return Pedido.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  Future<bool> claimOrderForPreparation({required String orderId, required String sellerName}) {
    final orderRef = _db.collection('pedidos').doc(orderId);

    return _db.runTransaction<bool>((transaction) async {
      final orderDoc = await transaction.get(orderRef);

      if (!orderDoc.exists) {
        throw Exception("Este pedido ya no existe.");
      }

      if (orderDoc.data()?['status'] != 'pagado') {
        throw Exception("Este pedido ya fue reclamado o procesado.");
      }

      transaction.update(orderRef, {
        'status': 'en_preparacion',
        'preparedBy': sellerName,
      });
      return true;
    });
  }

  Stream<UserModel?> getSellerForStore(String tiendaId) {
    return _db
        .collection('users')
        .where('tiendaId', isEqualTo: tiendaId)
        .where('role', isEqualTo: 'vendedor')
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return UserModel.fromFirestore(snapshot.docs.first.data(), snapshot.docs.first.id);
    });
  }

  Stream<List<UserModel>> streamAllUsers() {
    return _db.collection('users').snapshots().map((snapshot) => snapshot.docs
        .map((doc) => UserModel.fromFirestore(doc.data(), doc.id))
        .toList());
  }

  Future<void> updateUserRole(String userId, UserRole newRole) {
    return _db.collection('users').doc(userId).update({
      'role': newRole.name,
    });
  }

  Future<void> assignStoreToSeller(String userId, String? storeId) {
    return _db.collection('users').doc(userId).update({
      'tiendaId': storeId,
    });
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

  Stream<List<Pedido>> streamPendingOrdersForStore(String tiendaId) {
    return _db
        .collection('pedidos')
        .where('tiendaId', isEqualTo: tiendaId)
        .where('status', whereIn: ['pagado', 'en_preparacion', 'listo_para_entrega'])
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Pedido.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<Pedido>> streamDeliveredOrdersForStore(String tiendaId) {
    return _db
        .collection('pedidos')
        .where('tiendaId', isEqualTo: tiendaId)
        .where('status', isEqualTo: 'entregado')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Pedido.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> updateOrderStatus(String orderId, String newStatus, {String? preparedBy}) {
    final dataToUpdate = <String, dynamic>{'status': newStatus};
    if (preparedBy != null) {
      dataToUpdate['preparedBy'] = preparedBy;
    }
    return _db.collection('pedidos').doc(orderId).update(dataToUpdate);
  }

  Future<void> updateUserName(String userId, String newName) {
    return _db.collection('users').doc(userId).update({'name': newName});
  }

  Future<String> placeOrderAndUpdateStock({
    required Pedido pedido,
    required List<PedidoItem> items,
  }) {
    return _db.runTransaction<String>((transaction) async {
      final pedidoRef = _db.collection('pedidos').doc();
      final List<Map<String, dynamic>> stockUpdates = [];
      for (final item in items) {
        final productoRef = _db.collection('tiendas').doc(pedido.tiendaId).collection('productos').doc(item.productId);
        final productoDoc = await transaction.get(productoRef);
        if (!productoDoc.exists) {
          throw Exception("El producto ${item.productName} ya no existe.");
        }
        final currentStock = productoDoc.data()!['stock'] as int;
        if (currentStock < item.quantity) {
          throw Exception("No hay suficiente stock para ${item.productName}. Solo quedan $currentStock.");
        }
        stockUpdates.add({
          'ref': productoRef,
          'newStock': currentStock - item.quantity,
        });
      }
      transaction.set(pedidoRef, pedido.toMap());
      for (var update in stockUpdates) {
        transaction.update(update['ref'] as DocumentReference, {'stock': update['newStock']});
      }
      for (var item in items) {
        final itemRef = pedidoRef.collection('items').doc();
        transaction.set(itemRef, item.toMap());
      }
      return pedidoRef.id;
    });
  }
}
