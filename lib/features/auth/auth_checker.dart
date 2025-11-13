import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pideqr/features/auth/auth_providers.dart';
import 'package:pideqr/features/auth/login_screen.dart'; 
// Necesario para el signOut de prueba

// Pantallas de ejemplo
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PideQR - Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            // Al presionar, llama al método signOut del AuthService
            onPressed: () => ref.read(authServiceProvider).signOut(),
          )
        ],
      ),
      body: const Center(child: Text('Bienvenido, ¡sesión iniciada!')),
    );
  }
}

class AuthChecker extends ConsumerWidget {
  const AuthChecker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Observar el estado completo del usuario (UserModel)
    final authState = ref.watch(userModelProvider);

    return authState.when(
      // Muestra un spinner mientras carga el estado de Firebase
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
      // Si hay datos: verifica si el usuario es null
      data: (user) {
        if (user != null) {
          // Si el usuario existe, va a la Home Screen (está logueado)
          return const HomeScreen();
        }
        // Si el usuario es null, va a la Login Screen (no logueado)
        return const LoginScreen();
      },
    );
  }
}