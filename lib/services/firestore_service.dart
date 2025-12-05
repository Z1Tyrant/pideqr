import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pideqr/core/models/user_model.dart';
import '../core/models/producto.dart';
import '../core/models/pedido.dart';
import '../core/models/pedido_item.dart';
import '../core/models/tienda.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String getNewDocumentId(String collectionPath) {
    return _db.collection(collectionPath).doc().id;
  }

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

  Future<String> createStore(String name) async {
    final docRef = await _db.collection('tiendas').add({'name': name});
    return docRef.id;
  }

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

  Future<void> addDeliveryZone(String tiendaId, String zoneName) {
    if (zoneName.trim().isEmpty) return Future.value();
    return _db.collection('tiendas').doc(tiendaId).update({
      'deliveryZones': FieldValue.arrayUnion([zoneName.trim()])
    });
  }

  Future<void> removeDeliveryZone(String tiendaId, String zoneName) {
    return _db.collection('tiendas').doc(tiendaId).update({
      'deliveryZones': FieldValue.arrayRemove([zoneName])
    });
  }

  Future<void> addFcmToken({required String userId, required String token}) {
    return _db.collection('users').doc(userId).update({
      'fcmTokens': FieldValue.arrayUnion([token])
    });
  }

  Future<void> removeFcmToken({required String userId, required String token}) {
    return _db.collection('users').doc(userId).update({
      'fcmTokens': FieldValue.arrayRemove([token])
    });
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

  Future<String> placeOrder({
    required Pedido pedido,
    required List<PedidoItem> items,
  }) {
    return _db.runTransaction<String>((transaction) async {
      final pedidoRef = _db.collection('pedidos').doc();
      transaction.set(pedidoRef, pedido.toMap());
      for (var item in items) {
        final itemRef = pedidoRef.collection('items').doc();
        transaction.set(itemRef, item.toMap());
      }
      return pedidoRef.id;
    });
  }

  Future<bool> claimOrderAndUpdateStock({
    required String orderId,
    required String sellerName,
    String? sellerZone,
  }) {
    final orderRef = _db.collection('pedidos').doc(orderId);
    return _db.runTransaction<bool>((transaction) async {
      final orderDoc = await transaction.get(orderRef);
      if (!orderDoc.exists) throw Exception("Este pedido ya no existe.");
      if (orderDoc.data()?['status'] != OrderStatus.pagado.name) throw Exception("Este pedido ya fue reclamado.");

      final String tiendaId = orderDoc.data()!['tiendaId'];
      // ... (resto de la lógica de stock)

      transaction.update(orderRef, {
        'status': OrderStatus.en_preparacion.name,
        'preparedBy': sellerName,
        'deliveryZone': sellerZone,
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

  Future<void> assignZoneToSeller(String userId, String? zone) {
    return _db.collection('users').doc(userId).update({
      'deliveryZone': zone,
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

  // --- NUEVA FUNCIÓN PARA PEDIDOS ACTIVOS ---
  Stream<List<Pedido>> streamActiveUserOrders(String userId) {
    return _db
        .collection('pedidos')
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: [
          OrderStatus.pagado.name,
          OrderStatus.en_preparacion.name,
          OrderStatus.listo_para_entrega.name,
        ])
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
        .where('status', whereIn: [OrderStatus.pagado.name, OrderStatus.en_preparacion.name, OrderStatus.listo_para_entrega.name])
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Pedido.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<Pedido>> streamDeliveredOrdersForStore(String tiendaId) {
    return _db
        .collection('pedidos')
        .where('tiendaId', isEqualTo: tiendaId)
        .where('status', isEqualTo: OrderStatus.entregado.name)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Pedido.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) {
    final dataToUpdate = <String, dynamic>{'status': newStatus.name};
    if (newStatus == OrderStatus.entregado) {
      dataToUpdate['deliveredAt'] = FieldValue.serverTimestamp();
    }
    return _db.collection('pedidos').doc(orderId).update(dataToUpdate);
  }

  Future<void> updateUserName(String userId, String newName) {
    return _db.collection('users').doc(userId).update({'name': newName});
  }
}
