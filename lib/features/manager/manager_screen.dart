import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pideqr/core/models/tienda.dart';
import 'package:pideqr/core/models/user_model.dart';
import 'package:pideqr/features/auth/auth_checker.dart';
import 'package:pideqr/features/auth/auth_providers.dart';
import 'package:pideqr/features/manager/manager_providers.dart';
import 'package:pideqr/features/admin/product_management_screen.dart';
import 'package:pideqr/features/admin/manage_zones_screen.dart';
import 'package:pideqr/features/admin/store_qr_code_screen.dart';
import 'package:pideqr/features/menu/menu_providers.dart';
import 'package:pideqr/features/auth/profile_screen.dart';
import 'package:pideqr/services/notification_service.dart';

final functionsProvider = Provider((ref) => FirebaseFunctions.instanceFor(region: 'us-central1'));

class ManagerScreen extends ConsumerStatefulWidget {
  const ManagerScreen({super.key});

  @override
  ConsumerState<ManagerScreen> createState() => _ManagerScreenState();
}

class _ManagerScreenState extends ConsumerState<ManagerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _currentTabIndex = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await ref.read(notificationServiceProvider).removeTokenFromDatabase();
    await ref.read(authServiceProvider).signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthChecker()),
        (route) => false,
      );
    }
  }

  Future<void> _showAddSellerDialog() async {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Añadir Vendedor por Correo'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Ingresa el correo del usuario (con rol Cliente) que deseas añadir a tu tienda.'),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Correo electrónico', border: OutlineInputBorder()),
                validator: (value) => (value?.trim().isEmpty ?? true) ? 'Campo requerido' : null,
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          ElevatedButton.icon(
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Añadir'),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(ctx);

                navigator.pop(); 
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('Promoviendo usuario...'), duration: Duration(seconds: 10)),
                );

                try {
                  final promoteFunction = ref.read(functionsProvider).httpsCallable('promoteUserToSeller');
                  final result = await promoteFunction.call({'email': emailController.text.trim()});

                  scaffoldMessenger.hideCurrentSnackBar();
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text(result.data['message'] ?? '¡Vendedor añadido con éxito!'), backgroundColor: Colors.green),
                  );
                } on FirebaseFunctionsException catch (e) {
                  scaffoldMessenger.hideCurrentSnackBar();
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('Error: ${e.message}'), backgroundColor: Colors.red),
                  );
                } catch (e) {
                  scaffoldMessenger.hideCurrentSnackBar();
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('Ocurrió un error inesperado: ${e.toString()}'), backgroundColor: Colors.red),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final manager = ref.watch(userModelProvider).value;

    if (manager == null || manager.tiendaId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error de Asignación')),
        body: const Center(child: Text('No tienes una tienda asignada.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Manager'),
        actions: [
          IconButton(icon: const Icon(Icons.person_outline), tooltip: 'Mi Perfil', onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ProfileScreen()))),
          IconButton(icon: const Icon(Icons.logout), tooltip: 'Cerrar Sesión', onPressed: _logout),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.storefront), text: 'Mi Tienda'),
            Tab(icon: Icon(Icons.people_outline), text: 'Vendedores')
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const _StoreManagementView(), // Contenido restaurado aquí
          const _SellersManagementView(),
        ],
      ),
      floatingActionButton: _currentTabIndex == 1
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: const Text('Añadir Vendedor'),
              onPressed: _showAddSellerDialog,
            )
          : null,
    );
  }
}

// --- VISTA RESTAURADA ---
class _StoreManagementView extends ConsumerWidget {
  const _StoreManagementView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storeAsync = ref.watch(managerStoreProvider);
    return storeAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
      data: (store) => ListView(
        children: [
          ListTile(title: Text(store.name, style: Theme.of(context).textTheme.headlineSmall), subtitle: const Text('Nombre de la tienda')),
          const Divider(),
          ListTile(leading: const Icon(Icons.article_outlined), title: const Text('Gestionar Productos'), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => ProductManagementScreen(tiendaId: store.id, tiendaName: store.name)))),
          ListTile(leading: const Icon(Icons.map_outlined), title: const Text('Gestionar Zonas de Entrega'), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => ManageZonesScreen(tienda: store)))),
          ListTile(leading: const Icon(Icons.qr_code), title: const Text('Ver Código QR de la Tienda'), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => StoreQrCodeScreen(storeId: store.id, storeName: store.name)))),
        ],
      ),
    );
  }
}

class _SellersManagementView extends ConsumerWidget {
  const _SellersManagementView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sellersAsync = ref.watch(sellersInStoreProvider);
    final storeAsync = ref.watch(managerStoreProvider);

    return storeAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error cargando tienda: $e')),
      data: (store) => sellersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error cargando vendedores: $e')),
        data: (vendedores) {
          if (vendedores.isEmpty) {
            return const Center(child: Text('No tienes vendedores asignados.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: vendedores.length,
            itemBuilder: (context, index) => _SellerTile(
              seller: vendedores[index],
              deliveryZones: store.deliveryZones,
            ),
          );
        },
      ),
    );
  }
}

class _SellerTile extends ConsumerStatefulWidget {
  final UserModel seller;
  final List<String> deliveryZones;

  const _SellerTile({required this.seller, required this.deliveryZones});

  @override
  ConsumerState<_SellerTile> createState() => _SellerTileState();
}

class _SellerTileState extends ConsumerState<_SellerTile> {
  bool _isUpdating = false;

  Future<void> _updateZone(String? newZone) async {
    setState(() => _isUpdating = true);
    try {
      await ref.read(firestoreServiceProvider).assignZoneToSeller(widget.seller.uid, newZone);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _showRemoveSellerConfirmation() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitar Vendedor'),
        content: Text('¿Estás seguro de que quieres quitar a ${widget.seller.name} de la tienda? Su rol volverá a ser "Cliente".'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(ctx);
              navigator.pop();
              scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Quitando vendedor...'), duration: Duration(seconds: 10)));

              try {
                final demoteFunction = ref.read(functionsProvider).httpsCallable('demoteSellerToCustomer');
                await demoteFunction.call({'sellerId': widget.seller.uid});

                scaffoldMessenger.hideCurrentSnackBar();
                scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Vendedor quitado con éxito.'), backgroundColor: Colors.green));
              } on FirebaseFunctionsException catch (e) {
                scaffoldMessenger.hideCurrentSnackBar();
                scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error: ${e.message}'), backgroundColor: Colors.red));
              } catch (e) {
                scaffoldMessenger.hideCurrentSnackBar();
                scaffoldMessenger.showSnackBar(SnackBar(content: Text('Ocurrió un error inesperado: ${e.toString()}'), backgroundColor: Colors.red));
              }
            },
            child: const Text('Sí, quitar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sellerData = ref.watch(userDataProvider(widget.seller.uid)).value;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(widget.seller.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(widget.seller.email),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'remove') {
                  _showRemoveSellerConfirmation();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'remove',
                  child: ListTile(leading: Icon(Icons.person_remove_outlined, color: Colors.red), title: Text('Quitar de la tienda')),
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Zona:', style: TextStyle(color: Colors.grey)),
                if (_isUpdating)
                  const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                else
                  DropdownButton<String?>(
                    value: sellerData?.deliveryZone,
                    hint: const Text('Asignar...'),
                    onChanged: _updateZone,
                    items: widget.deliveryZones
                        .map((zone) => DropdownMenuItem(value: zone, child: Text(zone)))
                        .toList()..insert(0, const DropdownMenuItem(value: null, child: Text('Ninguna'))),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
