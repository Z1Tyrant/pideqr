// lib/features/auth/auth_checker.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pideqr/features/auth/auth_providers.dart';
import 'package:pideqr/features/auth/login_screen.dart'; 
import 'package:pideqr/features/orders/order_history_screen.dart'; // <-- NUEVA IMPORTACIÓN
import 'qr_scanner_screen.dart'; 

// Pantallas de ejemplo
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userModelProvider);
    final role = userAsync.when(
      data: (user) => user?.role.toString().split('.').last ?? 'Desconocido',
      loading: () => 'Cargando...',
      error: (e, st) => 'Error',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('PideQR'),
        // --- ACCIONES ACTUALIZADAS ---
        actions: [
          // Botón para ver el historial de pedidos
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Mis Pedidos',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const OrderHistoryScreen()),
              );
            },
          ),
          // Botón para cerrar sesión
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () => ref.read(authServiceProvider).signOut(),
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Bienvenido, rol: ${role.toUpperCase()}'),
            const SizedBox(height: 32),
            const Text(
              'Escanea el QR de la tienda para empezar el pedido:', 
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
    );
  }
}

class AuthChecker extends ConsumerWidget {
  const AuthChecker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(userModelProvider);

    return authState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
      data: (user) {
        if (user != null) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}