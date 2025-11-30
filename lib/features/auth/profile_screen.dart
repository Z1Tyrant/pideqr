// lib/features/auth/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    // Inicializamos el controlador con el nombre actual del usuario
    _nameController = TextEditingController(text: ref.read(userModelProvider).value?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _updateName() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre no puede estar vacío.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = ref.read(userModelProvider).value!.uid;
      await ref.read(firestoreServiceProvider).updateUserName(userId, _nameController.text.trim());
      
      // Refrescamos el provider para que toda la app se actualice con el nuevo nombre
      ref.refresh(userModelProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Nombre actualizado con éxito!'),
          backgroundColor: Colors.green,
        ),
      );
      
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar el nombre: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userModel = ref.watch(userModelProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil')),
      body: userModel == null
          ? const Center(child: Text('No se pudo cargar la información del usuario.'))
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Correo Electrónico', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(userModel.email),
                  const SizedBox(height: 16),

                  const Text('Rol', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(userModel.role.toString().split('.').last),
                  const SizedBox(height: 24),

                  const Text('Nombre de Usuario', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(hintText: 'Tu nombre o apodo'),
                  ),
                  const SizedBox(height: 32),

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
                ],
              ),
            ),
    );
  }
}
