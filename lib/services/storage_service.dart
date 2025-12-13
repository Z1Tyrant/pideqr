import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

final storageServiceProvider = Provider((ref) => StorageService());

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- NUEVO MÉTODO USANDO LA API REST DIRECTA ---
  Future<String> uploadProductImage(
    {
    required XFile image,
    required String productId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuario no autenticado. No se puede subir la imagen.');
    }

    // 1. Obtener el token de autenticación para autorizar la petición.
    final token = await user.getIdToken();

    // 2. Construir la URL del endpoint de la API REST de Firebase Storage.
    final bucket = _storage.bucket;
    final filePath = 'products/$productId.jpg';
    final uri = Uri.parse('https://firebasestorage.googleapis.com/v0/b/$bucket/o?name=$filePath');

    try {
      // 3. Leer los bytes del archivo de imagen.
      final imageBytes = await image.readAsBytes();

      // 4. Realizar la petición POST con los bytes y el token.
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'image/jpeg', 
        },
        body: imageBytes,
      );

      // 5. Procesar la respuesta.
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final downloadToken = body['downloadTokens'];
        final encodedPath = Uri.encodeComponent(filePath);
        
        // 6. Construir la URL pública y devolverla.
        final downloadUrl = 'https://firebasestorage.googleapis.com/v0/b/$bucket/o/$encodedPath?alt=media&token=$downloadToken';
        return downloadUrl;
      } else {
        throw Exception('Error al subir la imagen a la API: ${response.body}');
      }
    } catch (e) {
      throw Exception('Excepción al intentar subir la imagen: $e');
    }
  }
}
