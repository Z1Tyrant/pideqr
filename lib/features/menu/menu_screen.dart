// lib/features/menu/menu_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/producto.dart';
import '../orders/order_provider.dart';
import 'menu_providers.dart'; 
// Asegúrate de que esta importación sea correcta.
// Si tu HomeScreen de prueba está en auth_checker.dart, ajústala.
import '../auth/auth_checker.dart'; 

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Observar el StreamProvider de productos (conexión a Firestore)
    final productosAsyncValue = ref.watch(productosStreamProvider);
    
    // 2. Observar el estado actual del Carrito
    final carrito = ref.watch(orderNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menú del Locatario'),
        actions: [
          // Botón del carrito: Muestra la cantidad de ítems
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  // Muestra un mensaje temporal con la info del carrito
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Carrito con ${carrito.items.length} items. Subtotal: \$${carrito.subtotal.toStringAsFixed(0)}')),
                  );
                },
              ),
              if (carrito.items.isNotEmpty)
                Positioned(
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      '${carrito.items.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          // Botón para volver a la Home (temporal)
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              // Navegar de vuelta a la Home (donde está el botón de escanear)
              // Usamos HomeScreen, que está definida en auth_checker.dart
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            },
          ),
        ],
      ),
      body: productosAsyncValue.when(
        // a) Carga de datos
        loading: () => const Center(child: CircularProgressIndicator()),
        
        // b) Error en la conexión a Firestore
        error: (e, st) => Center(
          child: Text(
            'Error al cargar productos: $e',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ),
        
        // c) Datos cargados exitosamente
        data: (productos) {
          if (productos.isEmpty) {
            return const Center(child: Text('Este locatario aún no tiene productos.'));
          }

          return ListView.builder(
            itemCount: productos.length,
            itemBuilder: (context, index) {
              final producto = productos[index];
              return ProductoTile(producto: producto);
            },
          );
        },
      ),
    );
  }
}

// --- Widget de Producto Individual (Tile) ---

class ProductoTile extends ConsumerWidget {
  final Producto producto;
  const ProductoTile({required this.producto, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Acceder al controlador del carrito (Notifier)
    final orderNotifier = ref.read(orderNotifierProvider.notifier);

    return ListTile(
      title: Text(producto.name),
      subtitle: Text(producto.description),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('\$${producto.price.toStringAsFixed(0)}'),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.indigo),
            onPressed: () {
              try {
                // Añadir 1 unidad del producto al carrito
                orderNotifier.addItemToCart(producto: producto, quantity: 1);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${producto.name} añadido al carrito!')),
                );
              } catch (e) {
                // Manejar la excepción si el usuario intenta mezclar locatarios
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString().replaceAll('Exception: ', '🛑 '))),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}