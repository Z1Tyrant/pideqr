import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:pideqr/features/auth/auth_checker.dart';
import 'package:pideqr/services/payment_service.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'order_provider.dart';

// Provider que inicia la transacción en Transbank y obtiene la URL de pago.
final paymentUrlProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final paymentService = ref.watch(paymentServiceProvider);
  final carrito = ref.watch(orderNotifierProvider);
  
  final tiendaId = carrito.currentTiendaId;
  if (tiendaId == null || tiendaId.isEmpty) {
    throw Exception('No se pudo identificar la tienda para el pago.');
  }

  final buyOrder = 'pideqr_${DateTime.now().millisecondsSinceEpoch}';
  final amount = carrito.subtotal;

  if (amount <= 0) {
    throw Exception('El monto debe ser mayor a cero.');
  }

  return paymentService.createTransaction(tiendaId, buyOrder, amount);
});

// PANTALLA PRINCIPAL QUE ORQUESTA EL PROCESO DE PAGO
class PaymentScreen extends ConsumerWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentUrlAsync = ref.watch(paymentUrlProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagar con Webpay'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: paymentUrlAsync.when(
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Conectando con Transbank...'),
            ],
          ),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Error al iniciar el pago: $err\n\nAsegúrate de que la Cloud Function esté desplegada y configurada correctamente.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (transactionData) {
          final url = transactionData['url'];
          final token = transactionData['token'];

          if (url == null || token == null) {
            return const Center(child: Text('Respuesta inválida del servidor.'));
          }

          // Si todo va bien, muestra el WebView para el pago.
          return PaymentWebView(url: url, token: token);
        },
      ),
    );
  }
}

// WIDGET QUE CONTIENE EL WEBVIEW Y LA LÓGICA DE REDIRECCIÓN
class PaymentWebView extends ConsumerStatefulWidget {
  final String url;
  final String token;

  const PaymentWebView({super.key, required this.url, required this.token});

  @override
  ConsumerState<PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends ConsumerState<PaymentWebView> {
  late final WebViewController _controller;
  bool _isConfirming = false;

  @override
  void initState() {
    super.initState();

    const String returnUrl = "https://pideqr.app/payment_return";

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith(returnUrl)) {
              final uri = Uri.parse(request.url);
              final tokenWs = uri.queryParameters['token_ws'];

              // Si la URL contiene 'token_ws', el pago fue exitoso y debemos confirmarlo.
              if (tokenWs != null) {
                _handlePaymentSuccess(tokenWs);
              } 
              // Si no, significa que el usuario canceló o el pago fue rechazado.
              else {
                _handlePaymentFailure("El pago fue cancelado o rechazado.");
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

    // Construimos un formulario HTML para redirigir a Webpay
    final htmlContent = """
      <html>
        <body onload="document.forms[0].submit()">
          <form action="${widget.url}" method="POST">
            <input type="hidden" name="token_ws" value="${widget.token}" />
          </form>
        </body>
      </html>
    """;

    _controller.loadHtmlString(htmlContent);
  }

  // Maneja el éxito del pago, llamando a la función de confirmación.
  Future<void> _handlePaymentSuccess(String tokenWs) async {
    setState(() {
      _isConfirming = true;
    });

    try {
      final paymentService = ref.read(paymentServiceProvider);
      final carrito = ref.read(orderNotifierProvider);
      final tiendaId = carrito.currentTiendaId!;

      await paymentService.confirmTransaction(
        tokenWs: tokenWs,
        tiendaId: tiendaId,
        items: carrito.items,
        total: carrito.subtotal,
      );
      
      if (mounted) {
        // Navegamos a HomeScreen con una bandera para mostrar el éxito.
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen(paymentJustCompleted: true)),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = "Ocurrió un error inesperado al confirmar.";
        if (e is FirebaseFunctionsException) {
          if (e.code == 'aborted') {
            errorMessage = "El pago fue cancelado o rechazado por el banco.";
          } else {
            errorMessage = "Error al confirmar: ${e.message}";
          }
        }
        _handlePaymentFailure(errorMessage);
      }
    }
  }

  // Maneja el fallo o cancelación del pago.
  void _handlePaymentFailure(String message) {
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Muestra una pantalla de carga mientras se confirma el pago en el backend.
    if (_isConfirming) {
      return const Scaffold(
        appBar: null,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text("Confirmando pago y guardando pedido..."),
            ],
          ),
        ),
      );
    }
    // Muestra el WebView de Transbank.
    return WebViewWidget(controller: _controller);
  }
}
