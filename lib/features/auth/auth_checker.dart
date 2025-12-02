import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pideqr/core/models/user_model.dart';
import 'package:pideqr/features/admin/admin_screen.dart'; // <-- NUEVA IMPORTACIÓN
import 'package:pideqr/features/auth/auth_providers.dart';
import 'package:pideqr/features/auth/login_screen.dart';
import 'package:pideqr/features/orders/order_history_screen.dart';
import 'package:pideqr/features/orders/order_provider.dart';
import 'package:pideqr/features/seller/seller_screen.dart';
import 'qr_scanner_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userModelProvider);

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
            onPressed: () {
              ref.read(orderNotifierProvider.notifier).clearCart();
              ref.read(authServiceProvider).signOut();
            },
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            userAsync.when(
              data: (user) => Text(
                '¡Hola, ${user?.name ?? 'Usuario'}!',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              loading: () => const Text('Cargando...'),
              error: (e, st) => const Text('Bienvenido'),
            ),
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
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Error de autenticación: $error')),
      ),
      data: (user) {
        if (user == null) {
          return const LoginScreen();
        }

        final userModelAsync = ref.watch(userModelProvider);
        return userModelAsync.when(
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (err, stack) => Scaffold(
            body: Center(child: Text('Error al cargar datos de usuario: $err')),
          ),
          // --- LÓGICA DE REDIRECCIÓN MEJORADA ---
          data: (userModel) {
            switch (userModel?.role) {
              case UserRole.admin:
                return const AdminScreen();
              case UserRole.vendedor:
                return const SellerScreen();
              case UserRole.cliente:
              default:
                return const HomeScreen();
            }
          },
        );
      },
    );
  }
}
