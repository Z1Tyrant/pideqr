import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pideqr/core/models/user_model.dart';
import 'package:pideqr/features/admin/store_qr_code_screen.dart';
import 'package:pideqr/features/auth/auth_providers.dart';
import 'package:pideqr/features/menu/menu_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _nameController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: ref.read(userModelProvider).value?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _updateName() async {
    // ... (lógica existente sin cambios)
  }

  Future<void> _sendPasswordReset() async {
    // ... (lógica existente sin cambios)
  }

  @override
  Widget build(BuildContext context) {
    final userModelAsync = ref.watch(userModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil')),
      body: userModelAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (userModel) {
          if (userModel == null) {
            return const Center(child: Text('No se pudo cargar la información del usuario.'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildProfileInfoCard(userModel),
                const SizedBox(height: 24),
                // --- NUEVA SECCIÓN PARA VENDEDORES ---
                if (userModel.role == UserRole.vendedor && userModel.tiendaId != null)
                  _buildSellerAssignmentCard(userModel),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton.icon(
                          icon: const Icon(Icons.save),
                          label: const Text('Guardar Nombre'),
                          onPressed: _updateName,
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                        ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: _sendPasswordReset,
                    child: const Text('Cambiar mi contraseña'),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileInfoCard(UserModel userModel) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Información General', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            const SizedBox(height: 8),
            Text('Correo Electrónico', style: Theme.of(context).textTheme.bodySmall),
            Text(userModel.email, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Text('Rol', style: Theme.of(context).textTheme.bodySmall),
            Text(userModel.role.name, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            const Text('Nombre de Usuario', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: 'Tu nombre o apodo'),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET PARA LA NUEVA SECCIÓN DE VENDEDOR ---
  Widget _buildSellerAssignmentCard(UserModel userModel) {
    final tiendaId = userModel.tiendaId!;
    final assignedZone = userModel.deliveryZone;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mi Asignación', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            const SizedBox(height: 8),
            Text('Tienda', style: Theme.of(context).textTheme.bodySmall),
            Consumer(builder: (context, ref, child) {
              final tiendaAsync = ref.watch(tiendaDetailsProvider(tiendaId));
              return tiendaAsync.when(
                loading: () => const Text('Cargando...', style: TextStyle(fontStyle: FontStyle.italic)),
                error: (e, st) => const Text('No se pudo cargar la tienda', style: TextStyle(color: Colors.red)),
                data: (tienda) => Text(tienda.name, style: Theme.of(context).textTheme.titleMedium),
              );
            }),
            const SizedBox(height: 16),
            Text('Zona Asignada', style: Theme.of(context).textTheme.bodySmall),
            Text(
              assignedZone ?? 'Ninguna',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontStyle: assignedZone == null ? FontStyle.italic : FontStyle.normal,
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.qr_code_2),
                label: const Text('Ver QR de la Tienda'),
                onPressed: () {
                   final tiendaAsync = ref.read(tiendaDetailsProvider(tiendaId));
                   final tienda = tiendaAsync.value;
                   if (tienda != null) {
                     Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => StoreQrCodeScreen(storeId: tienda.id, storeName: tienda.name),
                    ));
                   }
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
