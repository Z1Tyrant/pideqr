// lib/core/models/pedido.dart
import 'package:cloud_firestore/cloud_firestore.dart';

// Enum para el estado de la orden
enum PedidoStatus { 
  pendiente, 
  pagado, 
  enPreparacion, 
  listoParaRetirar, 
  entregado, 
  cancelado 
}

class Pedido {
  final String? id; // Nullable al crearse, se define al guardarse
  final String userId;
  final String locatarioId;
  final double totalAmount;
  final PedidoStatus status;
  final DateTime createdAt;
  // Nota: Los PedidoItem no se guardan directamente aquí, sino en una subcolección.

  Pedido({
    this.id,
    required this.userId,
    required this.locatarioId,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
  });

  // Método para guardar el encabezado del Pedido en Firestore
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'locatario_id': locatarioId,
      'total_amount': totalAmount,
      // Guarda el estado como un string (ej: 'pagado')
      'status': status.toString().split('.').last, 
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  // Método factory para crear un Pedido desde Firestore
  factory Pedido.fromMap(Map<String, dynamic> data, String id) {
    return Pedido(
      id: id,
      userId: data['user_id'] ?? '',
      locatarioId: data['locatario_id'] ?? '',
      totalAmount: (data['total_amount'] as num?)?.toDouble() ?? 0.0,
      status: PedidoStatus.values.firstWhere(
        (e) => e.toString().split('.').last == (data['status'] ?? 'pendiente'),
        orElse: () => PedidoStatus.pendiente,
      ),
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}