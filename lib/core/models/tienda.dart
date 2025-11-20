// lib/core/models/tienda.dart

class Tienda {
  final String id;
  final String name;

  Tienda({
    required this.id,
    required this.name,
  });

  factory Tienda.fromMap(Map<String, dynamic> data, String id) {
    // Si el campo 'name' no existe o es nulo en Firestore, 
    // mostramos el ID de la tienda como nombre para depuración.
    return Tienda(
      id: id,
      name: data['name'] ?? 'ID no encontrado: $id',
    );
  }
}
