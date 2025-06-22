import 'package:cloud_firestore/cloud_firestore.dart';

class MigrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Ejecutar todas las migraciones necesarias
  Future<void> runAllMigrations() async {
    print('=== INICIANDO MIGRACIONES ===');
    
    await migrateLawyersCityField();
    await migrateSpecialtiesField();
    await validateDataIntegrity();
    
    print('=== MIGRACIONES COMPLETADAS ===');
  }

  // Migrar campo de ciudad para abogados existentes
  Future<void> migrateLawyersCityField() async {
    try {
      print('Migrando campo de ciudad para abogados...');

      // Obtener todos los documentos de abogados
      QuerySnapshot allLawyers = await _firestore.collection('lawyers').get();
      
      List<String> defaultCities = [
        'Quito', 'Guayaquil', 'Cuenca', 'Ambato', 'Loja', 
        'Machala', 'Riobamba', 'Portoviejo', 'Ibarra', 'Santo Domingo',
        'Manta', 'Latacunga', 'Babahoyo', 'Tulcán', 'Esmeraldas'
      ];

      int updated = 0;
      int cityIndex = 0;
      
      for (QueryDocumentSnapshot doc in allLawyers.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        // Verificar si necesita actualización
        bool needsUpdate = false;
        Map<String, dynamic> updateData = {};
        
        // Verificar campo ciudad
        if (!data.containsKey('city') || data['city'] == null || data['city'] == '') {
          updateData['city'] = defaultCities[cityIndex % defaultCities.length];
          cityIndex++;
          needsUpdate = true;
        }
        
        // Verificar campo especialidades (convertir de string a array si es necesario)
        if (data.containsKey('specialty') && !data.containsKey('specialties')) {
          updateData['specialties'] = [data['specialty']];
          needsUpdate = true;
        } else if (!data.containsKey('specialties')) {
          updateData['specialties'] = ['Derecho Civil']; // Especialidad por defecto
          needsUpdate = true;
        }
        
        // Verificar campos adicionales que podrían faltar
        if (!data.containsKey('phone')) {
          updateData['phone'] = '';
          needsUpdate = true;
        }
        
        if (!data.containsKey('reviewCount')) {
          updateData['reviewCount'] = 0;
          needsUpdate = true;
        }
        
        if (!data.containsKey('rating')) {
          updateData['rating'] = 0.0;
          needsUpdate = true;
        }

        // Actualizar el documento si es necesario
        if (needsUpdate) {
          await doc.reference.update(updateData);
          updated++;
          print('Actualizado abogado: ${data['name']} -> Ciudad: ${updateData['city'] ?? data['city']}');
        }
      }
      
      print('Migración de ciudades completada: $updated abogados actualizados de ${allLawyers.docs.length} total');
      
    } catch (e) {
      print('Error en migración de ciudades: $e');
    }
  }

  // Migrar campo de especialidades (de string a array)
  Future<void> migrateSpecialtiesField() async {
    try {
      print('Migrando campo de especialidades...');

      QuerySnapshot lawyersWithOldSpecialty = await _firestore
          .collection('lawyers')
          .get();
      
      int updated = 0;
      
      for (QueryDocumentSnapshot doc in lawyersWithOldSpecialty.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        // Si tiene el campo 'specialty' pero no 'specialties', migrar
        if (data.containsKey('specialty') && data['specialty'] != null) {
          if (!data.containsKey('specialties') || data['specialties'] == null) {
            await doc.reference.update({
              'specialties': [data['specialty']],
            });
            updated++;
            print('Migrado especialidad de ${data['name']}: ${data['specialty']} -> [${data['specialty']}]');
          }
        }
      }
      
      print('Migración de especialidades completada: $updated abogados actualizados');
      
    } catch (e) {
      print('Error en migración de especialidades: $e');
    }
  }

  // Validar integridad de datos después de la migración
  Future<void> validateDataIntegrity() async {
    try {
      print('Validando integridad de datos...');

      QuerySnapshot allLawyers = await _firestore.collection('lawyers').get();
      
      int validLawyers = 0;
      int invalidLawyers = 0;
      List<String> issues = [];
      
      for (QueryDocumentSnapshot doc in allLawyers.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        bool isValid = true;
        String lawyerName = data['name'] ?? 'Sin nombre';
        
        // Validar campos requeridos
        List<String> requiredFields = ['name', 'email', 'city', 'specialties'];
        for (String field in requiredFields) {
          if (!data.containsKey(field) || data[field] == null) {
            issues.add('$lawyerName: Campo requerido faltante - $field');
            isValid = false;
          }
        }
        
        // Validar que specialties sea una lista
        if (data.containsKey('specialties') && data['specialties'] is! List) {
          issues.add('$lawyerName: Campo specialties no es una lista');
          isValid = false;
        }
        
        // Validar que city no esté vacía
        if (data.containsKey('city') && (data['city'] == null || data['city'] == '')) {
          issues.add('$lawyerName: Ciudad vacía o nula');
          isValid = false;
        }
        
        // Validar tipos de datos numéricos
        if (data.containsKey('consultationPrice') && data['consultationPrice'] is! num) {
          issues.add('$lawyerName: Precio de consulta no es numérico');
          isValid = false;
        }
        
        if (data.containsKey('rating') && data['rating'] is! num) {
          issues.add('$lawyerName: Rating no es numérico');
          isValid = false;
        }
        
        if (isValid) {
          validLawyers++;
        } else {
          invalidLawyers++;
        }
      }
      
      print('=== REPORTE DE VALIDACIÓN ===');
      print('Abogados válidos: $validLawyers');
      print('Abogados con problemas: $invalidLawyers');
      
      if (issues.isNotEmpty) {
        print('Problemas encontrados:');
        for (String issue in issues) {
          print('  - $issue');
        }
      } else {
        print('✅ Todos los datos están íntegros');
      }
      
    } catch (e) {
      print('Error en validación de datos: $e');
    }
  }

  // Crear índices necesarios para consultas eficientes
  Future<void> createDatabaseIndexes() async {
    print('Creando índices de base de datos...');
    print('NOTA: Los índices deben crearse manualmente en Firebase Console:');
    print('1. lawyers: city (Ascending)');
    print('2. lawyers: specialties (Array)');
    print('3. lawyers: city (Ascending), specialties (Array)');
    print('4. lawyers: rating (Descending)');
    print('5. lawyers: consultationPrice (Ascending)');
    print('6. reviews: lawyerId (Ascending), createdAt (Descending)');
  }

  // Obtener estadísticas después de la migración
  Future<void> generateMigrationReport() async {
    try {
      print('\n=== REPORTE POST-MIGRACIÓN ===');

      // Estadísticas generales
      QuerySnapshot lawyers = await _firestore.collection('lawyers').get();
      QuerySnapshot reviews = await _firestore.collection('reviews').get();
      QuerySnapshot users = await _firestore.collection('users').get();
      
      print('Total usuarios: ${users.docs.length}');
      print('Total abogados: ${lawyers.docs.length}');
      print('Total reseñas: ${reviews.docs.length}');
      
      // Estadísticas por ciudad
      Map<String, int> cityStats = {};
      Map<String, List<String>> citySpecialties = {};
      
      for (QueryDocumentSnapshot doc in lawyers.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String city = data['city'] ?? 'Sin especificar';
        List<String> specialties = List<String>.from(data['specialties'] ?? []);
        
        cityStats[city] = (cityStats[city] ?? 0) + 1;
        citySpecialties[city] = (citySpecialties[city] ?? [])..addAll(specialties);
      }
      
      print('\n--- Distribución por ciudades ---');
      var sortedCities = cityStats.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
        
      for (var entry in sortedCities) {
        Set<String> uniqueSpecialties = citySpecialties[entry.key]?.toSet() ?? {};
        print('${entry.key}: ${entry.value} abogados (${uniqueSpecialties.length} especialidades)');
      }
      
      // Estadísticas de precios
      List<double> prices = [];
      for (QueryDocumentSnapshot doc in lawyers.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data['consultationPrice'] != null) {
          prices.add((data['consultationPrice'] as num).toDouble());
        }
      }
      
      if (prices.isNotEmpty) {
        prices.sort();
        double avgPrice = prices.reduce((a, b) => a + b) / prices.length;
        double minPrice = prices.first;
        double maxPrice = prices.last;
        
        print('\n--- Estadísticas de precios ---');
        print('Precio promedio: \$${avgPrice.toStringAsFixed(2)}');
        print('Precio mínimo: \$${minPrice.toStringAsFixed(2)}');
        print('Precio máximo: \$${maxPrice.toStringAsFixed(2)}');
      }
      
      print('\n=== FIN DEL REPORTE ===');
      
    } catch (e) {
      print('Error generando reporte: $e');
    }
  }

  // Método principal para ejecutar migración completa
  Future<void> executeMigration() async {
    try {
      await runAllMigrations();
      await generateMigrationReport();
      createDatabaseIndexes();
      
      print('\n🎉 Migración completada exitosamente!');
      print('Ahora puedes usar la funcionalidad de ciudades en tu aplicación.');
      
    } catch (e) {
      print('❌ Error durante la migración: $e');
    }
  }
}