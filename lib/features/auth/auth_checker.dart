// lib/features/auth/auth_checker.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pideqr/core/models/user_model.dart';
import 'package:pideqr/features/auth/auth_providers.dart';
import 'package:pideqr/features/auth/login_screen.dart';
import 'package:pideqr/features/orders/order_history_screen.dart';
import 'package:pideqr/features/seller/seller_screen.dart';
import 'qr_scanner_screen.dart';

// La HomeScreen del cliente se mantiene igual
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
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Mis Pedidos',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const OrderHistoryScreen()),
              );
            },
          ),
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

// --- AUTH CHECKER CORREGIDO ---
class AuthChecker extends ConsumerWidget {
  const AuthChecker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Observamos el estado de autenticación básico de Firebase.
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Error de autenticación: $error')),
      ),
      data: (user) {
        // Si el usuario de Firebase es null, vamos al Login.
        if (user == null) {
          return const LoginScreen();
        }

        // Si hay un usuario, ahora SÍ observamos el userModelProvider para decidir a dónde ir.
        final userModelAsync = ref.watch(userModelProvider);
        return userModelAsync.when(
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (err, stack) => Scaffold(
            body: Center(child: Text('Error al cargar datos de usuario: $err')),
          ),
          data: (userModel) {
            if (userModel?.role == UserRole.vendedor) {
              return const SellerScreen();
            } else {
              return const HomeScreen();
            }
          },
        );
      },
    );
  }
}
