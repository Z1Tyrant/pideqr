// lib/core/models/pedido.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Pedido {
  final String? id; // Nullable al crearse, se define al guardarse
  final String userId;
  final String tiendaId; // <-- CORREGIDO
  final double total;
  final String status;
  final DateTime timestamp;

  Pedido({
    this.id,
    required this.userId,
    required this.tiendaId, // <-- CORREGIDO
    required this.total,
    required this.status,
    required this.timestamp,
  });

  // Método para guardar el encabezado del Pedido en Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'tiendaId': tiendaId, // <-- CORREGIDO
      'total': total,
      'status': status,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  // El método fromMap no es estrictamente necesario ahora, pero es bueno tenerlo.
  factory Pedido.fromMap(Map<String, dynamic> data, String id) {
    return Pedido(
      id: id,
      userId: data['userId'] ?? '',
      tiendaId: data['tiendaId'] ?? '', // <-- CORREGIDO
      total: (data['total'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] ?? 'pendiente',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
