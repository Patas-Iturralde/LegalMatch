import 'package:abogados/firebase_options.dart';
import 'package:abogados/utils/data_initializer.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

// Clase para manejar la inicialización de Firebase
class FirebaseInitializer {
  // Inicializar Firebase
  static Future<void> initializeFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('Firebase inicializado con éxito');
    } catch (e) {
      print('Error al inicializar Firebase: $e');
      rethrow;
    }
  }

  // Inicializar datos de ejemplo si es necesario
  static Future<void> initializeAppData() async {
    try {
      final dataInitializer = DataInitializer();
      await dataInitializer.checkAndCreateCollections();
      print('Datos de la aplicación inicializados');
    } catch (e) {
      print('Error al inicializar datos de la aplicación: $e');
    }
  }

  // Inicializar todo el entorno de Firebase
  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    await initializeFirebase();
    await initializeAppData();
  }
}