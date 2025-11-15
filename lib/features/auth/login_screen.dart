// lib/features/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_providers.dart'; 
import 'register_screen.dart'; 
// 🚨 IMPORTACIÓN DEL WIDGET MODULAR ESTILIZADO
import '../../shared/widgets/custom_text_input.dart'; 


class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // Lógica de _signIn... (MANTENER LA LÓGICA DE FIREBASE AQUÍ)
  Future<void> _signIn() async {
    setState(() { _isLoading = true; });
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al iniciar sesión: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- REEMPLAZO DEL WIDGET BUILD ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Quitamos el AppBar para un diseño de pantalla completa
      body: Stack( 
        children: [
          // 1. Fondo Oscuro con Degradado
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF000000), Color(0xFF212121)], // Negro a Gris Oscuro
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          
          // 2. Contenido Principal (Scrollable)
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Título de la Aplicación
                  const Text(
                    'PideQR',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 60.0),

                  // 🚨 CAMPO DE CORREO (Usando CustomTextInput)
                  CustomTextInput(
                    controller: _emailController,
                    hintText: 'Correo Electrónico',
                    icon: Icons.person_outline,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16.0),
                  
                  // 🚨 CAMPO DE CONTRASEÑA (Usando CustomTextInput)
                  CustomTextInput(
                    controller: _passwordController,
                    hintText: 'Contraseña',
                    icon: Icons.lock_outline,
                    obscureText: true,
                  ),
                  const SizedBox(height: 40.0),
                  
                  // Botón de Login Estilizado
                  SizedBox(
                    width: double.infinity,
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator(color: Colors.white))
                        : ElevatedButton(
                            onPressed: _signIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.secondary, // Color Cian de acento
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'INICIAR SESIÓN',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                            ),
                          ),
                  ),
                  const SizedBox(height: 24.0),
                  
                  // Botón de Registro
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const RegisterScreen()),
                      );
                    },
                    child: const Text(
                      '¿No tienes cuenta? Regístrate aquí',
                      style: TextStyle(color: Colors.white70, decoration: TextDecoration.underline),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}