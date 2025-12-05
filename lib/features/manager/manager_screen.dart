import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pideqr/core/models/user_model.dart';
import 'package:pideqr/features/admin/widgets/user_management_tile.dart';
import 'package:pideqr/features/auth/auth_checker.dart';
import 'package:pideqr/features/auth/auth_providers.dart';
import 'package:pideqr/features/manager/manager_providers.dart';
import 'package:pideqr/features/admin/product_management_screen.dart';
import 'package:pideqr/features/admin/manage_zones_screen.dart';
import 'package:pideqr/features/admin/store_qr_code_screen.dart';
import 'package:pideqr/features/orders/order_provider.dart';
import 'package:pideqr/features/auth/profile_screen.dart';
import 'package:pideqr/services/notification_service.dart'; // <-- NUEVA IMPORTACIÓN

class ManagerScreen extends ConsumerWidget {
  const ManagerScreen({super.key});

  // --- LÓGICA DE LOGOUT ACTUALIZADA ---
  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(notificationServiceProvider).removeTokenFromDatabase();
    ref.read(orderNotifierProvider.notifier).clearCart();
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
    final manager = ref.watch(userModelProvider).value;
    final storeAsync = ref.watch(managerStoreProvider);

    if (manager == null || manager.tiendaId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error de Asignación'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Cerrar Sesión',
              onPressed: () => _logout(context, ref),
            ),
          ],
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'No tienes una tienda asignada. Por favor, contacta a un administrador.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Panel de Manager'),
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
              onPressed: () => _logout(context, ref),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.storefront), text: 'Mi Tienda'),
              Tab(icon: Icon(Icons.people_outline), text: 'Vendedores')
            ],
          ),
        ),
        body: TabBarView(
          children: [
            storeAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
              data: (store) => ListView(
                children: [
                  ListTile(
                    leading: const Icon(Icons.article_outlined),
                    title: const Text('Gestionar Productos'),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => ProductManagementScreen(tiendaId: store.id, tiendaName: store.name)),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.map_outlined),
                    title: const Text('Gestionar Zonas de Entrega'),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => ManageZonesScreen(tienda: store)),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.qr_code),
                    title: const Text('Ver Código QR de la Tienda'),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => StoreQrCodeScreen(storeId: store.id, storeName: store.name)),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.exit_to_app, color: Colors.red),
                    title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
                    onTap: () => _logout(context, ref),
                  ),
                ],
              ),
            ),
            ref.watch(sellersInStoreProvider).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
              data: (vendedores) => ListView.builder(
                itemCount: vendedores.length,
                itemBuilder: (context, index) => UserManagementTile(user: vendedores[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
