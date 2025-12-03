import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pideqr/core/models/tienda.dart';
import 'package:pideqr/features/menu/menu_providers.dart';

class ManageZonesScreen extends ConsumerWidget {
  final Tienda tienda;

  const ManageZonesScreen({super.key, required this.tienda});

  void _showAddZoneDialog(BuildContext context, WidgetRef ref) {
    final zoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Añadir Nueva Zona'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: zoneController,
              decoration: const InputDecoration(labelText: 'Nombre de la zona'),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'El nombre es obligatorio' : null,
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  ref.read(firestoreServiceProvider).addDeliveryZone(tienda.id, zoneController.text.trim());
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Añadir'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tiendaAsync = ref.watch(tiendaDetailsProvider(tienda.id));

    return Scaffold(
      appBar: AppBar(
        title: Text('Zonas de ${tienda.name}'),
      ),
      body: tiendaAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (tiendaData) {
          final zones = tiendaData.deliveryZones;
          if (zones.isEmpty) {
            return const Center(child: Text('Aún no hay zonas de entrega definidas.'));
          }
          return ListView.builder(
            itemCount: zones.length,
            itemBuilder: (context, index) {
              final zone = zones[index];
              return ListTile(
                title: Text(zone),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                  onPressed: () {
                    ref.read(firestoreServiceProvider).removeDeliveryZone(tienda.id, zone);
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddZoneDialog(context, ref),
        tooltip: 'Añadir Zona',
        child: const Icon(Icons.add),
      ),
    );
  }
}
