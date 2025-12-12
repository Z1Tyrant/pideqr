// lib/features/menu/menu_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/firestore_service.dart';
import '../../core/models/producto.dart';
import '../../core/models/tienda.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

class CurrentTiendaIdNotifier extends Notifier<String> {
  @override
  String build() {
    return '';
  }

  void updateId(String newId) {
    state = newId;
  }
}

final currentTiendaIdProvider =
    NotifierProvider<CurrentTiendaIdNotifier, String>(
  CurrentTiendaIdNotifier.new,
);

final tiendaDetailsProvider = StreamProvider.autoDispose.family<Tienda, String>((ref, tiendaId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  if (tiendaId.isEmpty) {
    return Stream.error('ID de la tienda no puede estar vacío');
  }
  return firestoreService.streamTienda(tiendaId);
});

final productosStreamProvider = StreamProvider.autoDispose.family<List<Producto>, String>((ref, tiendaId) {
  if (tiendaId.isEmpty) {
    return Stream.value([]);
  }
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamProductosPorTienda(tiendaId);
});

// --- ¡PROVIDER RESTAURADO! ---
// Obtiene los detalles de un único producto a partir de los IDs de la tienda y del producto.
final productDetailsProvider = StreamProvider.autoDispose.family<Producto, ({String tiendaId, String productoId})>((ref, ids) {
  if (ids.tiendaId.isEmpty || ids.productoId.isEmpty) {
    return Stream.error('El ID de la tienda y del producto no pueden estar vacíos');
  }
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamProducto(ids.tiendaId, ids.productoId);
});
