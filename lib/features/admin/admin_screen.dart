// lib/features/admin/admin_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pideqr/core/models/user_model.dart';
import 'package:pideqr/core/models/tienda.dart';
import 'package:pideqr/features/admin/admin_providers.dart';
import 'package:pideqr/features/admin/product_management_screen.dart';
import 'package:pideqr/features/auth/auth_providers.dart';
import 'package:pideqr/features/menu/menu_providers.dart';

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Panel de Administración'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Cerrar Sesión',
              onPressed: () => ref.read(authServiceProvider).signOut(),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);
    return usersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
      data: (users) => ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) => UserManagementTile(user: users[index]),
      ),
    );
  }
}

class StoresManagementView extends ConsumerWidget {
  const StoresManagementView({super.key});

  void _showEditStoreNameDialog(BuildContext context, WidgetRef ref, Tienda store) {
    final nameController = TextEditingController(text: store.name);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Nombre de la Tienda'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nuevo nombre'),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'El nombre no puede estar vacío' : null,
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  ref.read(firestoreServiceProvider).updateStoreName(store.id, nameController.text.trim());
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _showCreateStoreDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Crear Nueva Tienda'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nombre de la tienda'),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'El nombre es obligatorio' : null,
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  ref.read(firestoreServiceProvider).createStore(nameController.text.trim());
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Crear'),
            ),
          ],
        );
      },
    );
  }

  // --- FUNCIÓN PARA CONFIRMAR ELIMINACIÓN ---
  void _showDeleteStoreConfirmationDialog(BuildContext context, WidgetRef ref, Tienda store) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: Text('¿Estás seguro de que quieres eliminar la tienda \"${store.name}\"? Esta acción no se puede deshacer y borrará todos sus productos.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                ref.read(firestoreServiceProvider).deleteStore(store.id);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

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
                title: Text(store.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit, color: Colors.blue), tooltip: 'Editar Nombre', onPressed: () => _showEditStoreNameDialog(context, ref, store)),
                    IconButton(icon: const Icon(Icons.article_outlined), tooltip: 'Ver Productos', onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => ProductManagementScreen(tiendaId: store.id, tiendaName: store.name)),
                    )),
                    // --- BOTÓN DE ELIMINAR ---
                    IconButton(icon: const Icon(Icons.delete_forever, color: Colors.redAccent), tooltip: 'Eliminar Tienda', onPressed: () => _showDeleteStoreConfirmationDialog(context, ref, store)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateStoreDialog(context, ref),
        tooltip: 'Nueva Tienda',
        child: const Icon(Icons.add),
      ),
    );
  }
}

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
    final allStoresAsync = ref.watch(allStoresProvider);
    final isSelf = currentUser?.uid == widget.user.uid;

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
                    onChanged: isSelf ? null : _updateRole,
                    items: UserRole.values
                      .where((role) => role != UserRole.desconocido)
                      .map<DropdownMenuItem<UserRole>>((UserRole value) {
                        return DropdownMenuItem<UserRole>(value: value, child: Text(value.name));
                      }).toList(),
                  ),
              ],
            ),
            if (widget.user.role == UserRole.vendedor)
              allStoresAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (e, st) => Text('Error: $e', style: const TextStyle(color: Colors.red)),
                data: (stores) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tienda:'),
                    DropdownButton<String?>(
                      value: widget.user.tiendaId,
                      hint: const Text('Asignar...'),
                      onChanged: _updateStore,
                      items: stores.map<DropdownMenuItem<String?>>((Tienda store) {
                        return DropdownMenuItem<String?>(value: store.id, child: Text(store.name));
                      }).toList()..add(const DropdownMenuItem<String?>(value: null, child: Text('Ninguna'))),
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
    if (newRole != null) {
      setState(() => _isUpdating = true);
      await ref.read(firestoreServiceProvider).updateUserRole(widget.user.uid, newRole);
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _updateStore(String? newStoreId) async {
    setState(() => _isUpdating = true);
    await ref.read(firestoreServiceProvider).assignStoreToSeller(widget.user.uid, newStoreId);
    if (mounted) setState(() => _isUpdating = false);
  }
}
