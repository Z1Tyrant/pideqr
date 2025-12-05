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

    setState(() => _isProcessing = true);

    final firestoreService = ref.read(firestoreServiceProvider);
    final Pedido? order = await firestoreService.getOrderById(scannedCode);

    if (!mounted) return;

    if (order == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Pedido no encontrado.'), backgroundColor: Colors.red),
      );
      _resetScanner();
      return;
    }

    if (order.status == OrderStatus.entregado.name) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aviso: Este pedido ya fue entregado.'), backgroundColor: Colors.orange),
      );
      _resetScanner();
      return;
    }

    if (order.status != OrderStatus.listo_para_entrega.name) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Aviso: El pedido aún no está listo (Estado: ${order.status})'), backgroundColor: Colors.orange),
      );
      _resetScanner();
      return;
    }
    
    // --- NAVEGACIÓN CORREGIDA ---
    // Reemplazamos la pantalla actual por la de confirmación.
    // Ya no hacemos pop() después de esto.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => DeliveryConfirmationScreen(order: order),
      ),
    );
  }

  void _resetScanner() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _isProcessing = false);
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            color: Colors.black54,
            child: const Text(
              'Apunta al QR del pedido del cliente para confirmar la entrega',
              style: TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
