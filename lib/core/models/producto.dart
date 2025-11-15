// lib/core/models/producto.dart

class Producto {
  final String id;
  final String name;
  final double price;
  final String description;
  final int stock; // <-- NUEVO CAMPO

  Producto({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.stock, // <-- NUEVO CAMPO
  });

  // Constructor factory para crear un Producto a partir de un documento de Firestore
  factory Producto.fromMap(Map<String, dynamic> data, String id) {
    return Producto(
      id: id,
      name: data['name'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      description: data['description'] ?? '',
      stock: data['stock'] as int? ?? 0, // <-- NUEVO CAMPO (default a 0 si no existe)
    );
  }

  // Método para convertir el objeto a un mapa para guardarlo en Firestore
  // (No lo usamos para leer, pero es buena práctica tenerlo)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'description': description,
      'stock': stock,
    };
  }
}
