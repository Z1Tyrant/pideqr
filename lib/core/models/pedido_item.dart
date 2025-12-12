// lib/core/models/pedido_item.dart

class PedidoItem {
  final String productId;
  final String productName;
  final double unitPrice;
  final int quantity;

  PedidoItem({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
  });

  double get subtotal => unitPrice * quantity;

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

  Map<String, dynamic> toMap() {
    return {
      'product_id': productId,
      'product_name': productName,
      'unit_price': unitPrice,
      'quantity': quantity,
    };
  }

  factory PedidoItem.fromMap(Map<String, dynamic> data) {
    final String? foundProductId = data['product_id'];

    if (foundProductId == null || foundProductId.isEmpty) {
      throw StateError('Error de datos: El ítem del pedido no tiene un ID de producto válido. Datos recibidos: $data');
    }

    final num foundPrice = data['unit_price'] ?? 0.0;
    final String foundProductName = data['product_name'] ?? 'Producto Desconocido';

    return PedidoItem(
      productId: foundProductId,
      productName: foundProductName,
      unitPrice: foundPrice.toDouble(),
      quantity: data['quantity'] ?? 0,
    );
  }
}
