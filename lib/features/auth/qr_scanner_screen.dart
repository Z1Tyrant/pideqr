// lib/features/auth/qr_scanner_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import '../menu/menu_providers.dart';
import '../menu/menu_screen.dart'; 

class QRScannerScreen extends ConsumerStatefulWidget {
  const QRScannerScreen({super.key});

  @override
  ConsumerState<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends ConsumerState<QRScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool isScanned = false;

  @override
  void reassemble() {
    super.reassemble();
    controller?.pauseCamera();
    controller?.resumeCamera();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  // Lógica principal de escaneo
  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (isScanned) return;

      if (scanData.code != null) {
        // Detener la cámara y procesar
        isScanned = true;
        controller.pauseCamera();
        
        // 1. EL VALOR CLAVE: El código QR contiene el ID del locatario
        final locatarioId = scanData.code!; 
        
        // 2. ACTUALIZAR EL PROVIDER: Informar a la aplicación qué menú cargar
        ref.read(currentLocatarioIdProvider.notifier).state = locatarioId;
        
        // 3. REDIRECCIÓN: Cerrar el escáner y navegar al Menú
        // Usamos pushReplacement para evitar que el usuario vuelva al escáner con el botón de atrás
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MenuScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear QR de Mesa/Locatario'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 4,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: Colors.red,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 300,
              ),
            ),
          ),
          const Expanded(
            flex: 1,
            child: Center(
              child: Text('Apunta la cámara al QR del local para ver el menú.'),
            ),
          )
        ],
      ),
    );
  }
}