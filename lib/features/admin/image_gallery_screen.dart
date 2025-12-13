import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pideqr/core/utils/stock_images.dart';

class ImageGalleryScreen extends StatelessWidget {
  const ImageGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Imagen de Stock'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(8.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
        ),
        itemCount: stockImageUrls.length,
        itemBuilder: (context, index) {
          final imageUrl = stockImageUrls[index];
          return InkWell(
            onTap: () {
              Navigator.of(context).pop(imageUrl);
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              // --- WIDGET REEMPLAZADO POR LA VERSIÓN CON CACHÉ ---
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2.0),
                ),
                errorWidget: (context, url, error) => const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
