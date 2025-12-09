import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pideqr/features/orders/order_provider.dart';

// Provider para acceder fácilmente al servicio de pago
final paymentServiceProvider = Provider((ref) => PaymentService());

class PaymentService {
  final _functions = FirebaseFunctions.instanceFor(region: 'us-central1');

  /// Llama a la Cloud Function para crear una transacción en Transbank.
  Future<Map<String, dynamic>> createTransaction(String tiendaId, String buyOrder, double amount) async {
    try {
      final callable = _functions.httpsCallable('createWebpayTransaction');
      final response = await callable.call(<String, dynamic>{
        'tiendaId': tiendaId,
        'buyOrder': buyOrder,
        'amount': amount,
      });
      return Map<String, dynamic>.from(response.data);
    } on FirebaseFunctionsException catch (e) {
      print('Error al crear la transacción: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Llama a la Cloud Function para confirmar la transacción y guardar el pedido.
  Future<void> confirmTransaction({
    required String tokenWs,
    required String tiendaId,
    required List<OrderItem> items,
    required double total,
  }) async {
    try {
      final callable = _functions.httpsCallable('confirmWebpayTransaction');
      await callable.call(<String, dynamic>{
        'token_ws': tokenWs,
        'tiendaId': tiendaId,
        'items': items.map((item) => item.toMap()).toList(), // Convertimos los items a mapas
        'total': total,
      });
    } on FirebaseFunctionsException catch (e) {
      print('Error al confirmar la transacción: ${e.code} - ${e.message}');
      rethrow;
    }
  }
}
