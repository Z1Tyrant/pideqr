// lib/features/menu/menu_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/firestore_service.dart';
import '../../core/models/producto.dart';

// Provider para exponer la instancia de FirestoreService
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

// --- Provider para la Tienda Actual ---

// Notifier que gestiona el estado del ID de la tienda.
class CurrentTiendaIdNotifier extends Notifier<String> {
  @override
  String build() {
    // El valor inicial es una cadena vacía. 
    // La app no tendrá ninguna tienda seleccionada hasta que se escanee un QR.
    return '';
  }

  // Método para actualizar el ID de la tienda (lo llama el escáner QR).
  void updateId(String newId) {
    state = newId;
  }
}

// El provider público que expone el Notifier.
final currentTiendaIdProvider =
    NotifierProvider<CurrentTiendaIdNotifier, String>(
  CurrentTiendaIdNotifier.new,
);

// ----------------------------------------

// StreamProvider para obtener la lista de productos en tiempo real
final productosStreamProvider = StreamProvider.autoDispose<List<Producto>>((ref) {
  // Observa el ID de la tienda que estamos viendo
  final tiendaId = ref.watch(currentTiendaIdProvider);

  // Si no hay ID, no hay nada que mostrar (se puede manejar en la UI)
  if (tiendaId.isEmpty) {
    return Stream.value([]);
  }

  // Llama al servicio de Firestore
  final firestoreService = ref.watch(firestoreServiceProvider);

  // Retorna el stream de productos para la tienda seleccionada
  return firestoreService.streamProductosPorTienda(tiendaId);
});
