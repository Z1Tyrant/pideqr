import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pideqr/core/models/producto.dart';
import 'package:pideqr/features/auth/auth_checker.dart';
import 'package:pideqr/features/orders/cart_screen.dart';
import 'package:pideqr/features/orders/order_provider.dart';
import 'menu_providers.dart';

// --- PANTALLA DEL MENÚ REDISEÑADA ---
class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tiendaId = ref.watch(currentTiendaIdProvider);
    final productosAsync = ref.watch(productosStreamProvider(tiendaId));
    final tiendaAsync = ref.watch(tiendaDetailsProvider(tiendaId));
    final carrito = ref.watch(orderNotifierProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface, // Un fondo más claro
      appBar: AppBar(
        title: tiendaAsync.when(
          data: (tienda) => Text(tienda.name),
          loading: () => const Text('Cargando...'),
          error: (e, st) => const Text('Menú'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const AuthChecker()),
            (route) => false,
          ),
        ),
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.1),
      ),
      body: productosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error al cargar productos: $e')),
        data: (productos) {
          if (productos.isEmpty) {
            return const Center(
              child: Text(
                'Esta tienda aún no tiene productos disponibles.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 100), // Padding para el FAB
            itemCount: productos.length,
            itemBuilder: (context, index) => ProductoCard(producto: productos[index]),
          );
        },
      ),
      // --- BOTÓN DE CARRITO FLOTANTE ---
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: carrito.items.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CartScreen())),
              label: Text('Ver mi pedido (${carrito.totalItems})'),
              icon: const Icon(Icons.shopping_cart),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            )
          : null,
    );
  }
}

// --- WIDGET DE PRODUCTO REDISEÑADO COMO UNA TARJETA MODERNA ---
class ProductoCard extends ConsumerWidget {
  final Producto producto;
  const ProductoCard({required this.producto, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final bool isOutOfStock = producto.stock <= 0;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isOutOfStock ? null : () => _showAddToCartDialog(context, ref, producto),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Columna de Imagen
              SizedBox(
                width: 90,
                height: 90,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: producto.imageUrl != null && producto.imageUrl!.isNotEmpty
                      ? Image.network(
                          producto.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, st) => const Icon(Icons.broken_image, color: Colors.grey, size: 40),
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              // Columna de Texto (expandida)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(producto.name, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      producto.description,
                      style: textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${producto.price.toStringAsFixed(0)}',
                      style: textTheme.titleMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Diálogo para seleccionar cantidad y añadir al carrito
  void _showAddToCartDialog(BuildContext context, WidgetRef ref, Producto producto) {
    final quantityNotifier = ValueNotifier<int>(1);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        // --- AJUSTE PARA LA BARRA DE NAVEGACIÓN ---
        // El contenido del BottomSheet se envuelve en un Padding que tiene en cuenta
        // tanto el teclado (viewInsets) como la barra de navegación del sistema (viewPadding).
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.of(ctx).viewPadding.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(producto.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(producto.description, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 24),
              ValueListenableBuilder<int>(
                valueListenable: quantityNotifier,
                builder: (context, quantity, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.filled(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          if (quantityNotifier.value > 1) quantityNotifier.value--;
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Text(quantity.toString(), style: Theme.of(context).textTheme.headlineMedium),
                      ),
                      IconButton.filled(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          if (quantityNotifier.value < producto.stock) quantityNotifier.value++;
                        },
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_shopping_cart),
                label: ValueListenableBuilder<int>(
                  valueListenable: quantityNotifier,
                  builder: (context, quantity, child) {
                    final total = producto.price * quantity;
                    return Text('Añadir (\$${total.toStringAsFixed(0)})');
                  },
                ),
                onPressed: () {
                  try {
                    final tiendaId = ref.read(currentTiendaIdProvider);
                    ref.read(orderNotifierProvider.notifier).addItemToCart(
                      producto: producto,
                      quantity: quantityNotifier.value,
                      tiendaId: tiendaId,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${quantityNotifier.value} x ${producto.name} añadido(s)'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    Navigator.of(ctx).pop(); // Cierra el bottom sheet
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.redAccent),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
