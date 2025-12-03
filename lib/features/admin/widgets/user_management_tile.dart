import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pideqr/core/models/tienda.dart';
import 'package:pideqr/core/models/user_model.dart';
import 'package:pideqr/features/admin/admin_providers.dart';
import 'package:pideqr/features/auth/auth_providers.dart';
import 'package:pideqr/features/menu/menu_providers.dart';

class UserManagementTile extends ConsumerStatefulWidget {
  final UserModel user;
  const UserManagementTile({super.key, required this.user});

  @override
  ConsumerState<UserManagementTile> createState() => _UserManagementTileState();
}

class _UserManagementTileState extends ConsumerState<UserManagementTile> {
  bool _isUpdating = false;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(userModelProvider).value;
    final isSelf = currentUser?.uid == widget.user.uid;
    final isAdmin = currentUser?.role == UserRole.admin;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.user.name, style: Theme.of(context).textTheme.titleLarge),
            Text(widget.user.email, style: Theme.of(context).textTheme.bodySmall),
            const Divider(),
            // --- Sección de Rol (siempre visible) ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Rol:'),
                if (_isUpdating) const CircularProgressIndicator(),
                if (!_isUpdating)
                  DropdownButton<UserRole>(
                    value: widget.user.role,
                    onChanged: (isAdmin && !isSelf) ? _updateRole : null,
                    items: UserRole.values
                        .where((role) => role != UserRole.desconocido)
                        .map((role) => DropdownMenuItem(value: role, child: Text(role.name)))
                        .toList(),
                  ),
              ],
            ),

            // --- Sección de Tienda (Visible para Vendedor y Manager) ---
            if (widget.user.role == UserRole.vendedor || widget.user.role == UserRole.manager)
              Column(
                children: [
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tienda:'),
                      DropdownButton<String?>(
                        value: widget.user.tiendaId,
                        hint: const Text('Asignar...'),
                        onChanged: isAdmin ? _updateStore : null, // Solo el admin puede cambiar la tienda
                        items: ref.watch(allStoresProvider).when(
                              data: (stores) => stores
                                  .map((store) => DropdownMenuItem(value: store.id, child: Text(store.name)))
                                  .toList()..add(const DropdownMenuItem(value: null, child: Text('Ninguna'))),
                              loading: () => [],
                              error: (e, st) => [],
                            ),
                      ),
                    ],
                  ),
                ],
              ),

            // --- Sección de Zona (Solo visible para Vendedores con tienda asignada) ---
            if (widget.user.role == UserRole.vendedor && widget.user.tiendaId != null)
              ref.watch(tiendaDetailsProvider(widget.user.tiendaId!)).when(
                    loading: () => const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, st) => const SizedBox.shrink(), // Oculta si hay error cargando la tienda
                    data: (tienda) => Column(
                      children: [
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Zona:'),
                            DropdownButton<String?>(
                              value: widget.user.deliveryZone,
                              hint: const Text('Asignar...'),
                              onChanged: (isAdmin || (currentUser?.role == UserRole.manager && currentUser?.tiendaId == widget.user.tiendaId)) 
                                  ? _updateZone 
                                  : null,
                              items: tienda.deliveryZones
                                  .map((zone) => DropdownMenuItem(value: zone, child: Text(zone)))
                                  .toList()..add(const DropdownMenuItem(value: null, child: Text('Ninguna'))),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateRole(UserRole? newRole) async {
    if (newRole == null) return;
    setState(() => _isUpdating = true);
    await ref.read(firestoreServiceProvider).updateUserRole(widget.user.uid, newRole);
    // Si el rol cambia, es buena práctica desasignar tienda y zona.
    await ref.read(firestoreServiceProvider).assignStoreToSeller(widget.user.uid, null);
    await ref.read(firestoreServiceProvider).assignZoneToSeller(widget.user.uid, null);
    if (mounted) setState(() => _isUpdating = false);
  }

  Future<void> _updateStore(String? newStoreId) async {
    setState(() => _isUpdating = true);
    await ref.read(firestoreServiceProvider).assignStoreToSeller(widget.user.uid, newStoreId);
    // Al cambiar de tienda, siempre se desasigna la zona anterior.
    await ref.read(firestoreServiceProvider).assignZoneToSeller(widget.user.uid, null);
    if (mounted) setState(() => _isUpdating = false);
  }

  Future<void> _updateZone(String? newZone) async {
    setState(() => _isUpdating = true);
    await ref.read(firestoreServiceProvider).assignZoneToSeller(widget.user.uid, newZone);
    if (mounted) setState(() => _isUpdating = false);
  }
}
