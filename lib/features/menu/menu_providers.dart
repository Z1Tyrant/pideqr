// lib/features/menu/menu_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/firestore_service.dart';
import '../../core/models/producto.dart';
import '../../core/models/tienda.dart'; // <-- NUEVA IMPORTACIÓN

// Provider para exponer la instancia de FirestoreService
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

// --- Provider para la Tienda Actual ---

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

// --- NUEVO PROVIDER PARA LOS DETALLES DE LA TIENDA ---
final tiendaDetailsProvider = StreamProvider.autoDispose<Tienda>((ref) {
  final tiendaId = ref.watch(currentTiendaIdProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);

  if (tiendaId.isNotEmpty) {
    return firestoreService.streamTienda(tiendaId);
  }
  // Devolvemos un stream que nunca emite nada si no hay ID
  return Stream.value(Tienda(id: '', name: 'Cargando...')); 
});
// -----------------------------------------------------

// StreamProvider para obtener la lista de productos en tiempo real
final productosStreamProvider = StreamProvider.autoDispose<List<Producto>>((ref) {
  final tiendaId = ref.watch(currentTiendaIdProvider);

  if (tiendaId.isEmpty) {
    return Stream.value([]);
  }

  final firestoreService = ref.watch(firestoreServiceProvider);

  return firestoreService.streamProductosPorTienda(tiendaId);
});
