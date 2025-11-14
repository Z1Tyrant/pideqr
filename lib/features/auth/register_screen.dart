// lib/features/auth/register_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/user_model.dart'; // Importa el enum UserRole
import 'auth_providers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  // Controladores para capturar la data del formulario
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  
  // Estado para el selector de rol. Por defecto, es 'cliente'.
  UserRole _selectedRole = UserRole.cliente; 
  bool _isLoading = false;

  Future<void> _register() async {
    // Validación básica
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty || _nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, rellena todos los campos.'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Acceder al servicio de autenticación
      final authService = ref.read(authServiceProvider);

      // 2. Llamada al servicio para crear el usuario en Auth y Firestore
      await authService.registerWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
        role: _selectedRole, // Usa el rol seleccionado por el Dropdown
      );

      // 3. Si es exitoso, volvemos a la pantalla de login/home
      if (!mounted) return; // <-- CORRECCIÓN APLICADA
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registro exitoso como ${_selectedRole.toString().split('.').last}.')),
      );
      Navigator.of(context).pop(); 

    } catch (e) {
      if (!mounted) return; // <-- CORRECCIÓN APLICADA
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al registrar: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) { // <-- CORRECCIÓN ADICIONAL POR BUENA PRÁCTICA
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Nuevo Usuario')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView(
          children: <Widget>[
            // Campo de Nombre
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre Completo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            
            // Campo de Correo
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo Electrónico',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            
            // Campo de Contraseña
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contraseña (mínimo 6 caracteres)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32.0),

            // Selector de Rol (DIFICULTAD: El proyecto lo requiere)
            const Text('Selecciona tu Rol:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            DropdownButton<UserRole>(
              isExpanded: true,
              value: _selectedRole,
              onChanged: (UserRole? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedRole = newValue;
                  });
                }
              },
              // Mapea solo los roles que el usuario puede elegir al registrarse (excluyendo admin/desconocido)
              items: UserRole.values
                  .where((role) => role != UserRole.admin && role != UserRole.desconocido)
                  .map<DropdownMenuItem<UserRole>>((UserRole role) {
                return DropdownMenuItem<UserRole>(
                  value: role,
                  // Muestra el nombre del rol en mayúsculas (CLIENTE, VENDEDOR)
                  child: Text(role.toString().split('.').last.toUpperCase()), 
                );
              }).toList(),
            ),
            const SizedBox(height: 32.0),

            // Botón de Registro
            SizedBox(
              width: double.infinity,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Registrarse y Continuar',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}