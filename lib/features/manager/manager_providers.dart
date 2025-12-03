import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pideqr/core/models/tienda.dart';
import 'package:pideqr/core/models/user_model.dart';
import 'package:pideqr/features/admin/admin_providers.dart';
import 'package:pideqr/features/auth/auth_providers.dart';
import 'package:pideqr/features/menu/menu_providers.dart';

// Provider que obtiene los detalles de la tienda del manager actual.
final managerStoreProvider = FutureProvider<Tienda>((ref) async {
  final manager = await ref.watch(userModelProvider.future);
  if (manager == null || manager.tiendaId == null) {
    throw Exception('Manager no encontrado o sin tienda asignada.');
  }
  // Reutilizamos el provider que ya teníamos para obtener los detalles de una tienda.
  return ref.watch(tiendaDetailsProvider(manager.tiendaId!).future);
});

// Provider que obtiene solo los vendedores de la tienda del manager actual.
final sellersInStoreProvider = FutureProvider<List<UserModel>>((ref) async {
  final manager = await ref.watch(userModelProvider.future);
  final allUsers = await ref.watch(allUsersProvider.future);

  if (manager == null || manager.tiendaId == null) {
    throw Exception('Manager no encontrado o sin tienda asignada.');
  }

  return allUsers.where((user) => 
    user.role == UserRole.vendedor && user.tiendaId == manager.tiendaId
  ).toList();
});
