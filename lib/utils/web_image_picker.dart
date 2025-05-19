// lib/utils/web_image_picker.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

/// Clase para manejar la selección de imágenes en plataformas web y móviles
class WebImagePicker {
  /// Selecciona una imagen y la devuelve en formato base64
  static Future<String?> pickImage() async {
    // Para compilaciones móviles, usamos la implementación móvil
    return _pickImageMobile();
  }

  /// Implementación para plataformas móviles
  static Future<String?> _pickImageMobile() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 80,
      );
      
      if (image != null) {
        final bytes = await image.readAsBytes();
        return base64Encode(bytes);
      }
    } catch (e) {
      print('Error al seleccionar imagen: $e');
    }
    return null;
  }
}