import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
            if (widget.user.role == UserRole.vendedor || widget.user.role == UserRole.manager)
              _buildStoreSection(isAdmin),
            if (widget.user.role == UserRole.vendedor && widget.user.tiendaId != null)
              _buildZoneSection(currentUser),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreSection(bool isAdmin) {
    return Column(
      children: [
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Tienda:'),
            DropdownButton<String?>(
              value: widget.user.tiendaId,
              hint: const Text('Asignar...'),
              onChanged: isAdmin ? _updateStore : null,
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
    );
  }

  Widget _buildZoneSection(UserModel? currentUser) {
    return ref.watch(tiendaDetailsProvider(widget.user.tiendaId!)).when(
          loading: () => const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, st) => const SizedBox.shrink(),
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
                    onChanged: (currentUser?.role == UserRole.admin || (currentUser?.role == UserRole.manager && currentUser?.tiendaId == widget.user.tiendaId)) 
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
        );
  }

  Future<void> _updateRole(UserRole? newRole) async {
    if (newRole == null) return;
    setState(() => _isUpdating = true);

    final firestore = ref.read(firestoreServiceProvider);
    final userId = widget.user.uid;
    final currentStoreId = widget.user.tiendaId;

    try {
      await firestore.updateUserRole(userId, newRole);
      if (currentStoreId != null && newRole != UserRole.vendedor && newRole != UserRole.manager) {
        await firestore.updateSellerStoreAssignment(
          userId: userId,
          oldStoreId: currentStoreId,
          newStoreId: null, // Se desasigna de la tienda
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  // --- LÓGICA DE ACTUALIZACIÓN DE TIENDA CORREGIDA Y ATÓMICA ---
  Future<void> _updateStore(String? newStoreId) async {
    setState(() => _isUpdating = true);

    final firestore = ref.read(firestoreServiceProvider);

    try {
      // Llama a la nueva función atómica y segura
      await firestore.updateSellerStoreAssignment(
        userId: widget.user.uid,
        oldStoreId: widget.user.tiendaId,
        newStoreId: newStoreId,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _updateZone(String? newZone) async {
    setState(() => _isUpdating = true);
    await ref.read(firestoreServiceProvider).assignZoneToSeller(widget.user.uid, newZone);
    if (mounted) setState(() => _isUpdating = false);
  }
}
