import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pideqr/core/models/pedido.dart';
import 'package:pideqr/core/models/user_model.dart';
import 'package:pideqr/features/admin/admin_screen.dart';
import 'package:pideqr/features/auth/auth_providers.dart';
import 'package:pideqr/features/auth/login_screen.dart';
import 'package:pideqr/features/auth/profile_screen.dart';
import 'package:pideqr/features/manager/manager_screen.dart';
import 'package:pideqr/features/orders/order_details_screen.dart';
import 'package:pideqr/features/orders/order_history_screen.dart';
import 'package:pideqr/features/orders/order_provider.dart';
import 'package:pideqr/features/seller/seller_screen.dart';
import 'package:pideqr/services/notification_service.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'qr_scanner_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _navigateToScanner(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const QRScannerScreen()));
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(notificationServiceProvider).removeTokenFromDatabase();
    ref.read(orderNotifierProvider.notifier).clearCart();
    await ref.read(authServiceProvider).signOut();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthChecker()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userModelProvider);
    final activeOrdersAsync = ref.watch(activeUserOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('¡Hola, ${userAsync.value?.name ?? ""}!'),
        actions: [
          IconButton(icon: const Icon(Icons.person_outline), tooltip: 'Mi Perfil', onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ProfileScreen()))),
          IconButton(icon: const Icon(Icons.history), tooltip: 'Historial de Pedidos', onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const OrderHistoryScreen()))),
          IconButton(icon: const Icon(Icons.logout), tooltip: 'Cerrar Sesión', onPressed: () => _logout(context, ref)),
        ],
      ),
      floatingActionButton: activeOrdersAsync.maybeWhen(
        data: (orders) => orders.isNotEmpty
            ? FloatingActionButton.extended(
                onPressed: () => _navigateToScanner(context),
                label: const Text('Escanear QR'),
                icon: const Icon(Icons.qr_code_scanner),
              )
            : null,
        orElse: () => null,
      ),
      body: activeOrdersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error al cargar pedidos: $err')),
        data: (orders) {
          if (orders.isEmpty) {
            return GestureDetector(
              onTap: () => _navigateToScanner(context),
              behavior: HitTestBehavior.opaque,
              child: const _AnimatedEmptyState(),
            );
          }
          return _buildOrdersList(orders);
        },
      ),
    );
  }
}

// --- WIDGET DE ESTADO VACÍO CON ANIMACIÓN CORREGIDA ---
class _AnimatedEmptyState extends StatefulWidget {
  const _AnimatedEmptyState();

  @override
  State<_AnimatedEmptyState> createState() => _AnimatedEmptyStateState();
}

class _AnimatedEmptyStateState extends State<_AnimatedEmptyState> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800), // <-- ANIMACIÓN MÁS RÁPIDA
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _glowAnimation = Tween<double>(begin: 4.0, end: 10.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Usamos el color secundario para asegurar contraste en modo oscuro
    final accentColor = theme.colorScheme.secondary;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        // <-- COLOR CORREGIDO PARA MEJOR CONTRASTE
                        color: accentColor.withOpacity(0.4),
                        blurRadius: _glowAnimation.value * 2,
                        spreadRadius: _glowAnimation.value,
                      ),
                    ],
                  ),
                  child: child,
                ),
              );
            },
            child: Icon(
              Icons.qr_code_scanner_rounded,
              size: 100,
              // <-- COLOR CORREGIDO PARA MEJOR CONTRASTE
              color: accentColor,
            ),
          ),
          const SizedBox(height: 60),
          Text(
            'No tienes pedidos activos',
            style: theme.textTheme.headlineSmall?.copyWith(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 12),
          Text(
            'Toca la pantalla para escanear y empezar',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}


class _buildOrdersList extends StatelessWidget {
  final List<Pedido> orders;
  const _buildOrdersList(this.orders);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 88),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: Text('Tus Pedidos Activos', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ),
        ...orders.map((order) => _ActiveOrderCard(order: order)),
      ],
    );
  }
}

class _ActiveOrderCard extends StatelessWidget {
  final Pedido order;
  const _ActiveOrderCard({required this.order});

  String _getReadableStatus(String status) {
    return status.replaceAll('_', ' ').replaceFirstMapped(RegExp(r'\w'), (m) => m.group(0)!.toUpperCase());
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pagado': return Colors.green;
      case 'en_preparacion': return Colors.orange;
      case 'listo_para_entrega': return Colors.blueAccent;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd/MM, hh:mm a').format(order.timestamp);
    final displayId = '#...${order.id!.substring(order.id!.length - 6)}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Pedido $displayId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Chip(
                  label: Text(_getReadableStatus(order.status), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  backgroundColor: _getStatusColor(order.status),
                ),
              ],
            ),
            Text(formattedDate),
            const SizedBox(height: 8),
            if (order.status == OrderStatus.listo_para_entrega.name)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Center(
                  child: Column(
                    children: [
                      if (order.deliveryZone != null) Text('Retira tu pedido en: ${order.deliveryZone}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8), 
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                        child: QrImageView(data: order.id!, version: QrVersions.auto, size: 140.0),
                      ),
                      const SizedBox(height: 8),
                      const Text('Muestra este QR para la entrega', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            if (order.status != OrderStatus.listo_para_entrega.name)
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => OrderDetailsScreen(orderId: order.id!))),
                  child: const Text('Ver Detalles'),
                ),
              ),
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
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(body: Center(child: Text('Error de autenticación: $error'))),
      data: (user) {
        if (user == null) return const LoginScreen();

        final userModelAsync = ref.watch(userModelProvider);
        return userModelAsync.when(
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (err, stack) => Scaffold(body: Center(child: Text('Error al cargar datos de usuario: $err'))),
          data: (userModel) {
            if (userModel != null) ref.read(notificationServiceProvider).initNotifications();

            switch (userModel?.role) {
              case UserRole.admin: return const AdminScreen();
              case UserRole.manager: return const ManagerScreen();
              case UserRole.vendedor: return const SellerScreen();
              case UserRole.cliente:
              default: return const HomeScreen();
            }
          },
        );
      },
    );
  }
<<<<<<< HEAD
}
=======
  
}
>>>>>>> e67c6a4c2d11608daba6986e610b080e0246f443
