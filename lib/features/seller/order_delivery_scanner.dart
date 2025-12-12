// lib/features/seller/order_delivery_scanner.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pideqr/core/models/pedido.dart'; // <-- IMPORTACIÓN AÑADIDA
import 'package:pideqr/features/menu/menu_providers.dart';

class OrderDeliveryScannerScreen extends ConsumerStatefulWidget {
  final String expectedOrderId;
  
  const OrderDeliveryScannerScreen({super.key, required this.expectedOrderId});

  @override
  ConsumerState<OrderDeliveryScannerScreen> createState() => _OrderDeliveryScannerScreenState();
}

class _OrderDeliveryScannerScreenState extends ConsumerState<OrderDeliveryScannerScreen> {
  bool _isProcessing = false;

  void _handleDetection(BarcodeCapture capture) {
    if (_isProcessing) return;

    final scannedCode = capture.barcodes.first.rawValue;
    if (scannedCode == null) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    if (scannedCode == widget.expectedOrderId) {
      final firestoreService = ref.read(firestoreServiceProvider);
      
      // --- CORRECCIÓN: Se usa el enum en lugar del string ---
      firestoreService.updateOrderStatus(widget.expectedOrderId, OrderStatus.entregado).then((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Pedido entregado con éxito!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();

      }).catchError((error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar el pedido: $error')),
        );
        setState(() {
          _isProcessing = false;
        });
      });

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QR incorrecto. Este no es el pedido esperado.'),
          backgroundColor: Colors.red,
        ),
      );
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear QR de Entrega')),
      // --- CORRECCIÓN DEFINITIVA USANDO STACK ---
      body: Stack(
        alignment: Alignment.center,
        children: [
          // La vista de la cámara va en el fondo
          MobileScanner(
            onDetect: _handleDetection,
          ),
          // El texto de guía va por encima
          const Text(
            'Apunta al QR del cliente para confirmar la entrega',
            style: TextStyle(color: Colors.white, backgroundColor: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
