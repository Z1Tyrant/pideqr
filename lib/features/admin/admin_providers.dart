// lib/features/admin/admin_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pideqr/core/models/user_model.dart';
import 'package:pideqr/core/models/tienda.dart'; // Import del modelo de Tienda
import 'package:pideqr/features/menu/menu_providers.dart';

final allUsersProvider = StreamProvider.autoDispose<List<UserModel>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamAllUsers();
});

// --- NUEVO PROVIDER PARA OBTENER TODAS LAS TIENDAS ---
final allStoresProvider = StreamProvider.autoDispose<List<Tienda>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamAllStores();
});
