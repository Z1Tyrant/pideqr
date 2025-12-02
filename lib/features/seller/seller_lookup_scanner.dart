// lib/features/seller/seller_lookup_scanner.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pideqr/features/menu/menu_providers.dart';
import 'package:pideqr/core/models/pedido.dart';
import 'delivery_confirmation_screen.dart';

class SellerLookupScannerScreen extends ConsumerStatefulWidget {
  const SellerLookupScannerScreen({super.key});

  @override
  ConsumerState<SellerLookupScannerScreen> createState() => _SellerLookupScannerScreenState();
}

class _SellerLookupScannerScreenState extends ConsumerState<SellerLookupScannerScreen> {
  bool _isProcessing = false;

  Future<void> _handleScannedCode(String scannedCode) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    final firestoreService = ref.read(firestoreServiceProvider);
    final Pedido? order = await firestoreService.getOrderById(scannedCode);

    if (!mounted) return;

    // 1. Si el pedido no existe
    if (order == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Pedido no encontrado.'), backgroundColor: Colors.red),
      );
      _resetScanner();
      return;
    }

    // 2. Si el pedido ya fue entregado
    if (order.status == 'entregado') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aviso: Este pedido ya fue entregado.'), backgroundColor: Colors.orange),
      );
      _resetScanner();
      return;
    }

    // 3. Si el pedido NO está listo para entrega
    if (order.status != 'listo_para_entrega') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Aviso: El pedido aún no está listo para entrega (Estado: ${order.status})'), backgroundColor: Colors.orange),
      );
      _resetScanner();
      return;
    }
    
    // 4. Si el pedido es válido, navegamos a la pantalla de confirmación
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DeliveryConfirmationScreen(order: order),
      ),
    );

    Navigator.of(context).pop();
  }

  void _resetScanner() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buscar Pedido por QR')),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            onDetect: (capture) {
              final scannedCode = capture.barcodes.first.rawValue;
              if (scannedCode != null) {
                _handleScannedCode(scannedCode);
              }
            },
          ),
          const Text(
            'Apunta al QR del pedido del cliente',
            style: TextStyle(color: Colors.white, backgroundColor: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
