import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pideqr/core/models/tienda.dart';
import 'package:pideqr/core/models/user_model.dart';
import 'package:pideqr/features/auth/auth_providers.dart';
import 'package:pideqr/features/menu/menu_providers.dart'; // <-- IMPORTACIÓN AÑADIDA

// --- PROVIDER CORREGIDO ---
// Obtiene los detalles de la tienda del manager actual directamente.
final managerStoreProvider = StreamProvider.autoDispose<Tienda>((ref) {
  final manager = ref.watch(userModelProvider).value;

  if (manager == null || manager.tiendaId == null) {
    return Stream.error('Manager no encontrado o sin tienda asignada.');
  }

  // Llama directamente al servicio para obtener el stream, que es lo correcto.
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamTienda(manager.tiendaId!);
});

// --- PROVIDER CORREGIDO Y OPTIMIZADO ---
// Obtiene solo los vendedores de la tienda del manager actual, de forma eficiente.
final sellersInStoreProvider = StreamProvider.autoDispose<List<UserModel>>((ref) {
  final manager = ref.watch(userModelProvider).value;

  // Si no hay manager o no tiene tiendaId, devuelve una lista vacía.
  if (manager == null || manager.tiendaId == null) {
    return Stream.value([]);
  }

  // Llama directamente a la consulta de Firestore permitida y eficiente.
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamSellersForStore(manager.tiendaId!);
});
