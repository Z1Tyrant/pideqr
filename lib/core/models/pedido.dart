// lib/core/models/pedido.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Pedido {
  final String? id;
  final String userId;
  final String tiendaId;
  final double total;
  final String status;
  final DateTime timestamp;
  final String? preparedBy;

  Pedido({
    this.id,
    required this.userId,
    required this.tiendaId,
    required this.total,
    required this.status,
    required this.timestamp,
    this.preparedBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'tiendaId': tiendaId,
      'total': total,
      'status': status,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory Pedido.fromMap(Map<String, dynamic> data, String id) {
    return Pedido(
      id: id,
      userId: data['userId'] ?? '',
      tiendaId: data['tiendaId'] ?? '',
      total: (data['total'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] ?? 'pendiente',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      preparedBy: data['preparedBy'] as String?,
    );
  }
}
