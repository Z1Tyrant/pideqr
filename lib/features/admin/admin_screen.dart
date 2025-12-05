import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pideqr/core/models/user_model.dart';
import 'package:pideqr/core/models/tienda.dart';
import 'package:pideqr/features/admin/admin_providers.dart';
import 'package:pideqr/features/admin/product_management_screen.dart';
import 'package:pideqr/features/admin/store_qr_code_screen.dart';
import 'package:pideqr/features/admin/manage_zones_screen.dart';
import 'package:pideqr/features/auth/auth_checker.dart';
import 'package:pideqr/features/auth/auth_providers.dart';
import 'package:pideqr/features/admin/widgets/admin_dialogs.dart';
import 'package:pideqr/features/admin/widgets/user_management_tile.dart';
import 'package:pideqr/features/auth/profile_screen.dart';
import 'package:pideqr/services/notification_service.dart'; // <-- NUEVA IMPORTACIÓN

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  // --- LÓGICA DE LOGOUT ACTUALIZADA ---
  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(notificationServiceProvider).removeTokenFromDatabase();
    await ref.read(authServiceProvider).signOut();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthChecker()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Panel de Administración'),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_outline),
              tooltip: 'Mi Perfil',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Cerrar Sesión',
              onPressed: () => _logout(context, ref), // Llama a la nueva función
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.people), text: 'Usuarios'),
              Tab(icon: Icon(Icons.store), text: 'Tiendas'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            UsersManagementView(),
            StoresManagementView(),
          ],
        ),
      ),
    );
  }
}

class UsersManagementView extends ConsumerWidget {
  const UsersManagementView({super.key});

  int _getRoleWeight(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 1;
      case UserRole.manager:
        return 2;
      case UserRole.vendedor:
        return 3;
      case UserRole.cliente:
      default:
        return 4;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);
    return usersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
      data: (users) {
        final sortedUsers = List<UserModel>.from(users);
        sortedUsers.sort((a, b) {
          final roleComparison = _getRoleWeight(a.role).compareTo(_getRoleWeight(b.role));
          if (roleComparison != 0) return roleComparison;
          return a.name.compareTo(b.name);
        });

        return ListView.builder(
          itemCount: sortedUsers.length,
          itemBuilder: (context, index) => UserManagementTile(user: sortedUsers[index]),
        );
      },
    );
  }
}

enum StoreAction { editName, manageZones, viewQr, delete }

class StoresManagementView extends ConsumerWidget {
  const StoresManagementView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storesAsync = ref.watch(allStoresProvider);
    return Scaffold(
      body: storesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (stores) => ListView.builder(
          itemCount: stores.length,
          itemBuilder: (context, index) {
            final store = stores[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                leading: const Icon(Icons.storefront, size: 40),
                title: Text(store.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Toca para gestionar productos'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => ProductManagementScreen(tiendaId: store.id, tiendaName: store.name)),
                ),
                trailing: PopupMenuButton<StoreAction>(
                  onSelected: (action) {
                    switch (action) {
                      case StoreAction.editName:
                        AdminDialogs.showEditStoreName(context, ref, store);
                        break;
                      case StoreAction.manageZones:
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => ManageZonesScreen(tienda: store)));
                        break;
                      case StoreAction.viewQr:
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => StoreQrCodeScreen(storeId: store.id, storeName: store.name)));
                        break;
                      case StoreAction.delete:
                        AdminDialogs.showDeleteStoreConfirmation(context, ref, store);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: StoreAction.editName,
                      child: ListTile(leading: Icon(Icons.edit), title: Text('Editar Nombre')),
                    ),
                    const PopupMenuItem(
                      value: StoreAction.manageZones,
                      child: ListTile(leading: Icon(Icons.map_outlined), title: Text('Gestionar Zonas')),
                    ),
                    const PopupMenuItem(
                      value: StoreAction.viewQr,
                      child: ListTile(leading: Icon(Icons.qr_code), title: Text('Ver QR')),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: StoreAction.delete,
                      child: ListTile(
                        leading: Icon(Icons.delete_forever, color: Colors.red),
                        title: Text('Eliminar', style: TextStyle(color: Colors.red)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => AdminDialogs.showCreateStore(context, ref),
        tooltip: 'Nueva Tienda',
        child: const Icon(Icons.add),
      ),
    );
  }
}
