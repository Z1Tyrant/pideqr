import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pideqr/core/models/user_model.dart';
import '../core/models/producto.dart';
import '../core/models/pedido.dart';
import '../core/models/pedido_item.dart';
import '../core/models/tienda.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ... (otros métodos existentes sin cambios) ...

  // --- FUNCIÓN RESTAURADA --- 
  // Obtiene un producto específico de una tienda.
  Stream<Producto> streamProducto(String tiendaId, String productoId) {
    return _db
        .collection('tiendas')
        .doc(tiendaId)
        .collection('productos')
        .doc(productoId)
        .snapshots()
        .map((snapshot) => Producto.fromMap(snapshot.data() ?? {}, snapshot.id));
  }

  // --- NUEVA FUNCIÓN PARA EL MANAGER ---
  Future<void> addSellerToStoreByEmail({
    required String email,
    required String storeId,
  }) async {
    // 1. Buscar al usuario por su email.
    final querySnapshot = await _db
        .collection('users')
        .where('email', isEqualTo: email.trim().toLowerCase())
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      throw Exception('No se encontró ningún usuario con ese correo electrónico.');
    }

    final userDoc = querySnapshot.docs.first;
    final userToAssign = UserModel.fromFirestore(userDoc.data(), userDoc.id);

    // 2. Validar al usuario.
    if (userToAssign.role != UserRole.cliente) {
      throw Exception('Solo se pueden añadir usuarios con el rol de Cliente.');
    }
    if (userToAssign.tiendaId != null) {
      throw Exception('Este usuario ya está asignado a otra tienda.');
    }

    // 3. Ejecutar la promoción y asignación en una transacción.
    final userRef = _db.collection('users').doc(userToAssign.uid);
    final sellerInStoreRef = _db.collection('tiendas').doc(storeId).collection('vendedores').doc(userToAssign.uid);

    return _db.runTransaction((transaction) async {
      // Actualiza el documento principal del usuario
      transaction.update(userRef, {
        'role': UserRole.vendedor.name,
        'tienda_id': storeId,
      });

      // Crea la copia del vendedor en la sub-colección de la tienda
      transaction.set(sellerInStoreRef, {
        'name': userToAssign.name,
        'email': userToAssign.email,
        'role': UserRole.vendedor.name,
      });
    });
  }

  // ... (resto de los métodos existentes sin cambios) ...

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
    final productsSnapshot = await storeRef.collection('productos').get();
    final WriteBatch batch = _db.batch();
    for (final doc in productsSnapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    await storeRef.delete();
  }

  Future<void> addDeliveryZone(String tiendaId, String zoneName) {
    if (zoneName.trim().isEmpty) return Future.value();
    return _db.collection('tiendas').doc(tiendaId).update({
      'delivery_zones': FieldValue.arrayUnion([zoneName.trim()])
    });
  }

  Future<void> removeDeliveryZone(String tiendaId, String zoneName) {
    return _db.collection('tiendas').doc(tiendaId).update({
      'delivery_zones': FieldValue.arrayRemove([zoneName])
    });
  }

  Future<void> addFcmToken({required String userId, required String token}) {
    return _db.collection('users').doc(userId).update({
      'fcm_tokens': FieldValue.arrayUnion([token])
    });
  }

  Future<void> removeFcmToken({required String userId, required String token}) {
    return _db.collection('users').doc(userId).update({
      'fcm_tokens': FieldValue.arrayRemove([token])
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

  Future<void> upsertProduct(
      {required String tiendaId, String? productoId, required Map<String, dynamic> data}) {
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

  Future<String> placeOrder({required Pedido pedido, required List<PedidoItem> items}) {
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

  Future<bool> claimOrderAndUpdateStock(
      {required String orderId, required String sellerName, String? sellerZone}) {
    final orderRef = _db.collection('pedidos').doc(orderId);
    return _db.runTransaction<bool>((transaction) async {
      final orderDoc = await transaction.get(orderRef);
      if (!orderDoc.exists) throw Exception("Este pedido ya no existe.");
      if (orderDoc.data()?['status'] != OrderStatus.pagado.name) throw Exception("Este pedido ya fue reclamado.");

      transaction.update(orderRef, {
        'status': OrderStatus.en_preparacion.name,
        'prepared_by': sellerName,
        'delivery_zone': sellerZone,
      });

      return true;
    });
  }

  Future<void> updateSellerStoreAssignment({
    required String userId,
    required String? newStoreId,
    String? oldStoreId,
  }) async {
    final userRef = _db.collection('users').doc(userId);

    if (newStoreId == oldStoreId) return;

    await _db.runTransaction((transaction) async {
      final userSnapshot = await transaction.get(userRef);
      if (!userSnapshot.exists) {
        throw Exception("Error: El usuario a asignar no existe.");
      }
      final userData = userSnapshot.data()!;

      if (oldStoreId != null) {
        final oldSellerRef = _db.collection('tiendas').doc(oldStoreId).collection('vendedores').doc(userId);
        transaction.delete(oldSellerRef);
      }

      if (newStoreId != null) {
        final newSellerRef = _db.collection('tiendas').doc(newStoreId).collection('vendedores').doc(userId);
        transaction.set(newSellerRef, {
          'name': userData['name'],
          'email': userData['email'],
          'role': userData['role'],
        });
      }

      transaction.update(userRef, {'tienda_id': newStoreId, 'delivery_zone': null});
    });
  }

  Stream<List<UserModel>> streamSellersForStore(String tiendaId) {
    return _db
        .collection('tiendas')
        .doc(tiendaId)
        .collection('vendedores')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  Stream<UserModel?> getSellerForStore(String tiendaId) {
    return _db
        .collection('users')
        .where('tienda_id', isEqualTo: tiendaId)
        .where('role', isEqualTo: 'vendedor')
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return UserModel.fromFirestore(snapshot.docs.first.data(), snapshot.docs.first.id);
    });
  }

  Stream<List<UserModel>> streamAllUsers() {
    return _db.collection('users').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => UserModel.fromFirestore(doc.data(), doc.id)).toList());
  }

  Future<void> updateUserRole(String userId, UserRole newRole) {
    return _db.collection('users').doc(userId).update({'role': newRole.name});
  }

  Future<void> assignZoneToSeller(String userId, String? zone) {
    return _db.collection('users').doc(userId).update({'delivery_zone': zone});
  }

  Stream<List<Pedido>> streamUserOrders(String userId) {
    return _db
        .collection('pedidos')
        .where('user_id', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Pedido.fromMap(doc.data(), doc.id)).toList());
  }

  Stream<List<Pedido>> streamActiveUserOrders(String userId) {
    return _db
        .collection('pedidos')
        .where('user_id', isEqualTo: userId)
        .where('status', whereIn: [
          OrderStatus.pagado.name,
          OrderStatus.en_preparacion.name,
          OrderStatus.listo_para_entrega.name
        ])
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Pedido.fromMap(doc.data(), doc.id)).toList());
  }

  Stream<List<PedidoItem>> streamOrderItems(String orderId) {
    return _db
        .collection('pedidos')
        .doc(orderId)
        .collection('items')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PedidoItem.fromMap(doc.data())).toList());
  }

  Stream<List<Pedido>> streamPendingOrdersForStore(String tiendaId) {
    return _db
        .collection('pedidos')
        .where('tienda_id', isEqualTo: tiendaId)
        .where('status', whereIn: [
          OrderStatus.pagado.name,
          OrderStatus.en_preparacion.name,
          OrderStatus.listo_para_entrega.name
        ])
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Pedido.fromMap(doc.data(), doc.id)).toList());
  }

  Stream<List<Pedido>> streamDeliveredOrdersForStore(String tiendaId) {
    return _db
        .collection('pedidos')
        .where('tienda_id', isEqualTo: tiendaId)
        .where('status', isEqualTo: OrderStatus.entregado.name)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Pedido.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) {
    final dataToUpdate = <String, dynamic>{'status': newStatus.name};
    if (newStatus == OrderStatus.entregado) {
      dataToUpdate['delivered_at'] = FieldValue.serverTimestamp();
    }
    return _db.collection('pedidos').doc(orderId).update(dataToUpdate);
  }

  Future<void> updateUserName(String userId, String newName) {
    return _db.collection('users').doc(userId).update({'name': newName});
  }
}
