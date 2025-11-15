// lib/features/auth/auth_checker.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pideqr/features/auth/auth_providers.dart';
import 'package:pideqr/features/auth/login_screen.dart'; 
import 'qr_scanner_screen.dart'; // Importación de la pantalla del escáner

// Pantallas de ejemplo
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Obtenemos la información del usuario para mostrar el rol (opcional, pero útil)
    final userAsync = ref.watch(userModelProvider);
    final role = userAsync.when(
      data: (user) => user?.role.toString().split('.').last ?? 'Desconocido',
      loading: () => 'Cargando...',
      error: (e, st) => 'Error',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('PideQR'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            // Llama al método signOut del AuthService
            onPressed: () => ref.read(authServiceProvider).signOut(),
          )
        ],
      ),
      // --- ESTRUCTURA MODIFICADA: CENTRO CON BOTÓN QR ---
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Bienvenido, rol: ${role.toUpperCase()}'),
            const SizedBox(height: 32),
            const Text(
              'Escanea el QR de tu mesa o locatario para empezar el pedido:', 
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 150, 
              height: 150,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(24),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Icon(Icons.qr_code, size: 70),
                onPressed: () {
                  // Navegar a la pantalla del escáner
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const QRScannerScreen()),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      // ---------------------------------------------------
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