import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/widgets.dart' as pw;

class StoreQrCodeScreen extends StatelessWidget {
  final String storeId;
  final String storeName;

  const StoreQrCodeScreen({super.key, required this.storeId, required this.storeName});

  Future<void> _printQrCode(String storeId, String storeName) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageTheme: const pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          orientation: pw.PageOrientation.portrait,
        ),
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(storeName, style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 40),
                // --- WIDGET DE CÓDIGO QR CORREGIDO ---
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: storeId,
                  width: 320,
                  height: 320,
                ),
                pw.SizedBox(height: 20),
                pw.Text('Escanea este código para ver el menú', style: const pw.TextStyle(fontSize: 18)),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => doc.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Código QR de $storeName'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Imprimir QR',
            onPressed: () => _printQrCode(storeId, storeName),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              storeName,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Container(
              color: Colors.white,
              child: QrImageView(
                data: storeId,
                version: QrVersions.auto,
                size: 250.0,
              ),
            ),
            const SizedBox(height: 24),
            const Text('Escanea para ver el menú', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
