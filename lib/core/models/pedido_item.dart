// lib/core/models/pedido_item.dart

class PedidoItem {
  final String productId;
  final String productName;
  final double unitPrice; // Precio inmutable al momento de la compra
  final int quantity;

  PedidoItem({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
  });

  // Getters útiles
  double get subtotal => unitPrice * quantity;

  // --- MÉTODO copyWith AÑADIDO ---
  PedidoItem copyWith({
    String? productId,
    String? productName,
    double? unitPrice,
    int? quantity,
  }) {
    return PedidoItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
    );
  }

  // Método para convertir el objeto a un mapa para guardarlo en Firestore
  Map<String, dynamic> toMap() {
    return {
      'product_id': productId,
      'product_name': productName,
      'unit_price': unitPrice,
      'quantity': quantity,
    };
  }

  // Permite recrear un PedidoItem a partir de un Mapa (por ejemplo, desde la DB)
  factory PedidoItem.fromMap(Map<String, dynamic> data) {
    return PedidoItem(
      productId: data['product_id'] ?? '',
      productName: data['product_name'] ?? 'Producto Desconocido',
      unitPrice: (data['unit_price'] as num?)?.toDouble() ?? 0.0,
      quantity: data['quantity'] ?? 0,
    );
  }
}