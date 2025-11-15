// lib/features/orders/confirmation_screen.dart

import 'package:flutter/material.dart';
import 'package:pideqr/features/auth/auth_checker.dart';
import 'package:qr_flutter/qr_flutter.dart'; // <-- NUEVA IMPORTACIÓN

class ConfirmationScreen extends StatelessWidget {
  final String orderId;

  const ConfirmationScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedido Confirmado'),
        automaticallyImplyLeading: false, // Oculta el botón de retroceso
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.green, size: 100),
                const SizedBox(height: 24),
                const Text(
                  '¡Tu pedido ha sido confirmado!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // --- WIDGET DE QR AÑADIDO ---
                QrImageView(
                  data: orderId, // El QR contiene el ID del pedido
                  version: QrVersions.auto,
                  size: 180.0,
                  backgroundColor: Colors.white,
                ),
                // ---------------------------
                const SizedBox(height: 24),
                Text(
                  'ID del Pedido:',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  orderId,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  icon: const Icon(Icons.home),
                  label: const Text('Volver al Inicio'),
                  onPressed: () {
                    // Navega de vuelta a la pantalla principal, limpiando el historial
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const HomeScreen()),
                      (Route<dynamic> route) => false, // Elimina todas las rutas anteriores
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
