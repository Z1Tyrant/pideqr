// lib/core/models/producto.dart

class Producto {
  final String id;
  final String name;
  final double price;
  final String description;
  final String locatarioId;

  Producto({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.locatarioId,
  });

  // Constructor factory para crear un Producto a partir de un documento de Firestore
  factory Producto.fromMap(Map<String, dynamic> data, String id) {
    return Producto(
      id: id,
      name: data['name'] ?? '',
      // Los precios suelen guardarse como int en Firestore para evitar errores de coma flotante.
      // Aquí lo convertimos a double para Dart, asumiendo que está guardado como num.
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      description: data['description'] ?? '',
      locatarioId: data['locatario_id'] ?? '',
    );
  }

  // Método para convertir el objeto a un mapa para guardarlo en Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'description': description,
      'locatario_id': locatarioId,
    };
  }
}