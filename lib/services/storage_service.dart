import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

// Provider para nuestro nuevo servicio
final storageServiceProvider = Provider((ref) => StorageService());

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Sube una imagen de producto y devuelve la URL de descarga.
  Future<String> uploadProductImage({
    required XFile image,
    required String productId,
  }) async {
    try {
      // --- RUTA CORREGIDA ---
      // Ahora coincide con la regla de seguridad de lectura: 'products/{allPaths=**}'
      final filePath = 'products/$productId.jpg';
      final ref = _storage.ref(filePath);

      // Sube el archivo
      final uploadTask = await ref.putFile(File(image.path));

      // Obtiene la URL de descarga
      final url = await uploadTask.ref.getDownloadURL();
      return url;
    } on FirebaseException catch (e) {
      throw Exception('Error al subir la imagen: ${e.message}');
    }
  }
}
