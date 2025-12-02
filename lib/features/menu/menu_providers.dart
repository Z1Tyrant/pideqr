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

// --- PROVIDER DE DETALLES DE LA TIENDA CORREGIDO ---
final tiendaDetailsProvider = StreamProvider.autoDispose.family<Tienda, String>((ref, tiendaId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  if (tiendaId.isEmpty) {
    return Stream.error('ID de la tienda no puede estar vacío');
  }
  return firestoreService.streamTienda(tiendaId);
});

final productosStreamProvider = StreamProvider.autoDispose<List<Producto>>((ref) {
  final tiendaId = ref.watch(currentTiendaIdProvider);
  if (tiendaId.isEmpty) {
    return Stream.value([]);
  }
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamProductosPorTienda(tiendaId);
});
