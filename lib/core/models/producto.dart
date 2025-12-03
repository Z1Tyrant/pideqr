// lib/core/models/producto.dart

class Producto {
  final String id;
  final String name;
  final double price;
  final String description;
  final int stock;
  final String? imageUrl; // <-- NUEVO CAMPO

  Producto({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.stock,
    this.imageUrl, // <-- NUEVO CAMPO
  });

  factory Producto.fromMap(Map<String, dynamic> data, String id) {
    return Producto(
      id: id,
      name: data['name'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      description: data['description'] ?? '',
      stock: data['stock'] as int? ?? 0,
      imageUrl: data['imageUrl'] as String?, // <-- NUEVO CAMPO
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'description': description,
      'stock': stock,
      'imageUrl': imageUrl,
    };
  }
}
