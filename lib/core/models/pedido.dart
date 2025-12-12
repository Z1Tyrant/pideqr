import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus {
  pagado,
  en_preparacion,
  listo_para_entrega,
  entregado,
  cancelado
}

class Pedido {
  final String? id;
  final String userId;
  final String tiendaId;
  final double total;
  final String status;
  final DateTime timestamp;
  final String? preparedBy;
  final String? deliveryZone;
  final DateTime? deliveredAt;

  Pedido({
    this.id,
    required this.userId,
    required this.tiendaId,
    required this.total,
    required this.status,
    required this.timestamp,
    this.preparedBy,
    this.deliveryZone,
    this.deliveredAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'tienda_id': tiendaId,
      'total': total,
      'status': status,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory Pedido.fromMap(Map<String, dynamic> data, String id) {
    return Pedido(
      id: id,
      userId: data['user_id'] ?? '',
      tiendaId: data['tienda_id'] ?? '',
      total: (data['total'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] ?? 'pagado',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      preparedBy: data['prepared_by'] as String?,
      deliveryZone: data['delivery_zone'] as String?,
      deliveredAt: (data['delivered_at'] as Timestamp?)?.toDate(),
    );
  }
}
