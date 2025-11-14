// lib/features/menu/menu_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/firestore_service.dart';
import '../../core/models/producto.dart';

// Provider para exponer la instancia de FirestoreService
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

// --- Provider para el Locatario Actual ---

// Notifier que gestiona el estado del ID del locatario.
class CurrentLocatarioIdNotifier extends Notifier<String> {
  @override
  String build() {
    // Valor inicial simulado. En el futuro, podría estar vacío.
    return 'loc_test_hamburguesas';
  }

  // Método para actualizar el ID del locatario.
  void updateId(String newId) {
    state = newId;
  }
}

// El provider público que expone el Notifier.
final currentLocatarioIdProvider =
    NotifierProvider<CurrentLocatarioIdNotifier, String>(
  CurrentLocatarioIdNotifier.new,
);

// ----------------------------------------

// StreamProvider para obtener la lista de productos en tiempo real
final productosStreamProvider = StreamProvider.autoDispose<List<Producto>>((ref) {
  // Observa el ID del locatario que estamos viendo
  final locatarioId = ref.watch(currentLocatarioIdProvider);

  // Si no hay ID, no hay nada que mostrar (se puede manejar en la UI)
  if (locatarioId.isEmpty) {
    return Stream.value([]);
  }

  // Llama al servicio de Firestore
  final firestoreService = ref.watch(firestoreServiceProvider);

  // Retorna el stream
  return firestoreService.streamProductosPorLocatario(locatarioId);
});
