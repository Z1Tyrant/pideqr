// lib/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/models/producto.dart';
// Importamos los demás modelos que usaremos más tarde
import '../core/models/pedido.dart';
import '../core/models/pedido_item.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream para obtener la lista de productos de un locatario en tiempo real
  Stream<List<Producto>> streamProductosPorLocatario(String locatarioId) {
    return _db
        .collection('productos')
        .where('locatario_id', isEqualTo: locatarioId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Producto.fromMap(doc.data(), doc.id))
            .toList());
  }


  // --- ESCRITURA DE PEDIDOS ---
  
  Future<String> saveNewPedido({
    required Pedido pedido, 
    required List<PedidoItem> items,
  }) async {
    // 1. Guardar el encabezado del Pedido
    final pedidoRef = await _db.collection('pedidos').add(pedido.toMap());
    final pedidoId = pedidoRef.id;

    // 2. Guardar los PedidoItems en la subcolección 'items'
    final batch = _db.batch(); // Usamos un batch para asegurar que todo el pedido se guarde junto
    
    for (var item in items) {
      final itemRef = _db.collection('pedidos').doc(pedidoId).collection('items').doc();
      batch.set(itemRef, item.toMap());
    }
    
    await batch.commit();
    
    return pedidoId;
  }
}