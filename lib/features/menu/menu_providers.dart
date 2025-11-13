// lib/features/menu/menu_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/firestore_service.dart';
import '../../core/models/producto.dart';

// Provider para exponer la instancia de FirestoreService
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

// StateProvider para el Locatario actual que estamos viendo (¡Simulación!)
// En el MVP final, este ID vendrá del escaneo del QR.
final currentLocatarioIdProvider = StateProvider<String>((ref) => 'loc_test_hamburguesas'); 

// StreamProvider para obtener la lista de productos en tiempo real
final productosStreamProvider = StreamProvider.autoDispose<List<Producto>>((ref) {
  // Observa el ID del locatario que estamos viendo
  final locatarioId = ref.watch(currentLocatarioIdProvider);
  
  // Llama al servicio de Firestore
  final firestoreService = ref.watch(firestoreServiceProvider);

  // Retorna el stream
  return firestoreService.streamProductosPorLocatario(locatarioId);
});