// lib/core/models/tienda.dart

class Tienda {
  final String id;
  final String name;
  final List<String> deliveryZones;
  final double? latitude;   // <-- NUEVO CAMPO
  final double? longitude;  // <-- NUEVO CAMPO

  Tienda({
    required this.id,
    required this.name,
    this.deliveryZones = const [],
    this.latitude,         // <-- NUEVO CAMPO
    this.longitude,        // <-- NUEVO CAMPO
  });

  factory Tienda.fromMap(Map<String, dynamic> data, String id) {
    final zonesFromDb = data['deliveryZones'] as List<dynamic>?;

    return Tienda(
      id: id,
      name: data['name'] ?? 'ID no encontrado: $id',
      deliveryZones: zonesFromDb?.map((zone) => zone as String).toList() ?? [],
      // Leemos las coordenadas, asegurando que sean de tipo double
      latitude: (data['latitude'] as num?)?.toDouble(),   // <-- NUEVO CAMPO
      longitude: (data['longitude'] as num?)?.toDouble(), // <-- NUEVO CAMPO
    );
  }

  // Nota: No es necesario un toMap aquí ya que la creación y actualización
  // de tiendas se gestiona en otros lugares del código.
}
