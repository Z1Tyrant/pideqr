// lib/features/auth/qr_scanner_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../menu/menu_providers.dart';
import '../menu/menu_screen.dart';

class QRScannerScreen extends ConsumerStatefulWidget {
  const QRScannerScreen({super.key});

  @override
  ConsumerState<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends ConsumerState<QRScannerScreen> {
  bool isScanned = false;
  MobileScannerController controller = MobileScannerController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (isScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if (code != null) {
        if (!mounted) return;

        isScanned = true;
        // The camera is automatically paused on detection.

        final tiendaId = code;
        // Se actualiza el provider con el nombre correcto
        ref.read(currentTiendaIdProvider.notifier).updateId(tiendaId);

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MenuScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear QR de Tienda'), // Título actualizado
      ),
      body: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
          ),
          Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.red,
                width: 4,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const Positioned(
            bottom: 50,
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Apunta la cámara al QR de la tienda para ver el menú.',
                style: TextStyle(color: Colors.white, backgroundColor: Colors.black54),
              ),
            ),
          )
        ],
      ),
    );
  }
}
