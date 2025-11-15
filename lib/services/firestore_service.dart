// lib/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/models/producto.dart';
// Importamos los demás modelos que usaremos más tarde
import '../core/models/pedido.dart';
import '../core/models/pedido_item.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- NUEVA FUNCIÓN CON SUBCOLECCIONES ---
  // Stream para obtener la lista de productos de una tienda en tiempo real.
  Stream<List<Producto>> streamProductosPorTienda(String tiendaId) {
    return _db
        .collection('tiendas') // 1. Apunta a la colección de tiendas
        .doc(tiendaId)           // 2. Selecciona el documento de la tienda específica
        .collection('productos') // 3. Apunta a su subcolección de productos
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Producto.fromMap(doc.data(), doc.id))
            .toList());
  }


  // --- ESCRITURA DE PEDIDOS (se mantiene igual por ahora) ---
  
  Future<String> saveNewPedido({
    required Pedido pedido, 
    required List<PedidoItem> items,
  }) async {
    // 1. Guardar el encabezado del Pedido
    final pedidoRef = await _db.collection('pedidos').add(pedido.toMap());
    final pedidoId = pedidoRef.id;

    // 2. Guardar los PedidoItems en la subcolección 'items'
    final batch = _db.batch(); 
    
    for (var item in items) {
      final itemRef = _db.collection('pedidos').doc(pedidoId).collection('items').doc();
      batch.set(itemRef, item.toMap());
    }
    
    await batch.commit();
    
    return pedidoId;
  }
}
