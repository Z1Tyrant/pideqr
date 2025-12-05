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
  final DateTime? deliveredAt; // <-- NUEVO CAMPO

  Pedido({
    this.id,
    required this.userId,
    required this.tiendaId,
    required this.total,
    required this.status,
    required this.timestamp,
    this.preparedBy,
    this.deliveryZone,
    this.deliveredAt, // <-- NUEVO CAMPO
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'tiendaId': tiendaId,
      'total': total,
      'status': status,
      'timestamp': Timestamp.fromDate(timestamp),
      // Los demás campos se actualizan en transacciones separadas
    };
  }

  factory Pedido.fromMap(Map<String, dynamic> data, String id) {
    return Pedido(
      id: id,
      userId: data['userId'] ?? '',
      tiendaId: data['tiendaId'] ?? '',
      total: (data['total'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] ?? 'pagado',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      preparedBy: data['preparedBy'] as String?,
      deliveryZone: data['deliveryZone'] as String?,
      deliveredAt: (data['deliveredAt'] as Timestamp?)?.toDate(), // <-- NUEVO CAMPO
    );
  }
}
