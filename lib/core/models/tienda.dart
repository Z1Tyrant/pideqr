// lib/core/models/tienda.dart

class Tienda {
  final String id;
  final String name;
  final List<String> deliveryZones;
  final double? latitude;
  final double? longitude;

  Tienda({
    required this.id,
    required this.name,
    this.deliveryZones = const [],
    this.latitude,
    this.longitude,
  });

  factory Tienda.fromMap(Map<String, dynamic> data, String id) {
    final zonesFromDb = data['delivery_zones'] as List<dynamic>?;

    return Tienda(
      id: id,
      name: data['name'] ?? 'ID no encontrado: $id',
      deliveryZones: zonesFromDb?.map((zone) => zone as String).toList() ?? [],
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'delivery_zones': deliveryZones,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
