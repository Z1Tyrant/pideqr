// lib/core/models/tienda.dart

class Tienda {
  final String id;
  final String name;
  final List<String> deliveryZones; // <-- NUEVO CAMPO

  Tienda({
    required this.id,
    required this.name,
    this.deliveryZones = const [], // <-- NUEVO CAMPO
  });

  factory Tienda.fromMap(Map<String, dynamic> data, String id) {
    // Lee la lista desde Firestore, asegurándose de que sea del tipo correcto.
    final zonesFromDb = data['deliveryZones'] as List<dynamic>?;

    return Tienda(
      id: id,
      name: data['name'] ?? 'ID no encontrado: $id',
      deliveryZones: zonesFromDb?.map((zone) => zone as String).toList() ?? [], // <-- NUEVO CAMPO
    );
  }
}
