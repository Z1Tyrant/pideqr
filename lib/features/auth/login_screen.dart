// lib/features/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_providers.dart'; 
import 'register_screen.dart'; // Necesario para navegar al registro

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // Controladores para obtener el texto de los campos
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // Lógica para iniciar sesión
  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Acceder al servicio de autenticación usando Riverpod
      final authService = ref.read(authServiceProvider);
      
      // 2. Llamada al servicio de Firebase
      await authService.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Si es exitoso, el AuthChecker detecta el cambio de estado y navega a HomeScreen

    } catch (e) {
      // 3. Manejo de errores y feedback al usuario
      if (!mounted) return; // <-- CORRECCIÓN APLICADA
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al iniciar sesión: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // 4. Detener el indicador de carga
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar Sesión en PideQR')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
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
                labelText: 'Contraseña',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32.0),
            
            // Botón de Login
            SizedBox(
              width: double.infinity,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _signIn,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Entrar a PideQR',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
            ),
            const SizedBox(height: 16.0),
            
            // Navegación a Registro
            TextButton(
              onPressed: () {
                // Navegar a la pantalla de registro
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const RegisterScreen()),
                );
              },
              child: const Text('¿No tienes cuenta? Regístrate aquí'),
            ),
          ],
        ),
      ),
    );
  }
}
