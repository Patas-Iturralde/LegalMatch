import 'package:cloud_firestore/cloud_firestore.dart';

class QuickCityMigration {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Ejecutar migración rápida para agregar ciudades
  Future<void> fixCityFieldForAllLawyers() async {
    try {
      print('🔄 Iniciando migración rápida de ciudades...');
      
      // Obtener todos los documentos de abogados
      QuerySnapshot snapshot = await _firestore.collection('lawyers').get();
      
      List<String> cities = [
        'Quito', 'Guayaquil', 'Cuenca', 'Ambato', 'Loja', 
        'Machala', 'Riobamba', 'Portoviejo', 'Ibarra', 'Santo Domingo',
        'Manta', 'Latacunga', 'Babahoyo', 'Tulcán', 'Esmeraldas'
      ];
      
      int updated = 0;
      int errors = 0;
      int skipped = 0;
      
      for (int i = 0; i < snapshot.docs.length; i++) {
        QueryDocumentSnapshot doc = snapshot.docs[i];
        
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          
          // Verificar si necesita actualización
          bool needsUpdate = false;
          Map<String, dynamic> updateData = {};
          
          // Verificar campo ciudad
          if (data['city'] == null || data['city'] == '' || data['city'] is! String) {
            updateData['city'] = cities[i % cities.length];
            needsUpdate = true;
          }
          
          // Verificar especialidades (convertir de string a array si es necesario)
          if (data.containsKey('specialty') && data['specialty'] != null) {
            if (!data.containsKey('specialties') || data['specialties'] == null) {
              updateData['specialties'] = [data['specialty']];
              needsUpdate = true;
            }
          } else if (!data.containsKey('specialties') || data['specialties'] == null) {
            updateData['specialties'] = ['Derecho Civil'];
            needsUpdate = true;
          }
          
          // Verificar otros campos importantes
          if (!data.containsKey('phone') || data['phone'] == null) {
            updateData['phone'] = '';
            needsUpdate = true;
          }
          
          if (!data.containsKey('rating') || data['rating'] == null) {
            updateData['rating'] = 0.0;
            needsUpdate = true;
          }
          
          if (!data.containsKey('reviewCount') || data['reviewCount'] == null) {
            updateData['reviewCount'] = 0;
            needsUpdate = true;
          }
          
          if (!data.containsKey('consultationPrice') || data['consultationPrice'] == null) {
            updateData['consultationPrice'] = 50.0;
            needsUpdate = true;
          }

          // Actualizar si es necesario
          if (needsUpdate) {
            try {
              await doc.reference.update(updateData);
              updated++;
              print('✅ Actualizado: ${data['name']} -> ${updateData['city'] ?? data['city']}');
            } catch (updateError) {
              print('❌ Error actualizando ${data['name']}: $updateError');
              errors++;
            }
          } else {
            skipped++;
          }
          
        } catch (e) {
          errors++;
          print('❌ Error procesando documento ${doc.id}: $e');
        }
      }
      
      print('\n🎉 Migración completada!');
      print('📊 Estadísticas:');
      print('   • Total abogados: ${snapshot.docs.length}');
      print('   • Actualizados: $updated');
      print('   • Errores: $errors');
      print('   • Ya tenían datos: $skipped');
      
      if (errors > 0) {
        print('\n⚠️ Hubieron $errors errores. Esto puede ser normal si:');
        print('   • Las reglas de Firestore aún no se han actualizado');
        print('   • Algunos documentos tienen problemas de formato');
        print('   • Faltan permisos para ciertos documentos');
      }
      
      if (updated > 0) {
        print('\n✅ Se actualizaron $updated abogados exitosamente');
        print('🔄 Recarga la aplicación para ver los cambios');
      }
      
    } catch (e) {
      print('❌ Error general en migración: $e');
    }
  }

  // Verificar estado actual de los datos
  Future<void> checkDataStatus() async {
    try {
      print('🔍 Verificando estado de los datos...');
      
      QuerySnapshot snapshot = await _firestore.collection('lawyers').get();
      
      int withCity = 0;
      int withoutCity = 0;
      int withSpecialties = 0;
      int withoutSpecialties = 0;
      Set<String> foundCities = {};
      
      for (QueryDocumentSnapshot doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        // Verificar ciudad
        if (data['city'] != null && data['city'] != '' && data['city'] is String) {
          withCity++;
          foundCities.add(data['city']);
        } else {
          withoutCity++;
        }
        
        // Verificar especialidades
        if (data['specialties'] != null && data['specialties'] is List) {
          withSpecialties++;
        } else {
          withoutSpecialties++;
        }
      }
      
      print('\n📊 Estado actual de los datos:');
      print('   • Total abogados: ${snapshot.docs.length}');
      print('   • Con ciudad: $withCity');
      print('   • Sin ciudad: $withoutCity');
      print('   • Con especialidades (array): $withSpecialties');
      print('   • Sin especialidades (array): $withoutSpecialties');
      print('   • Ciudades encontradas: ${foundCities.toList()..sort()}');
      
      if (withoutCity > 0) {
        print('\n⚠️  Hay $withoutCity abogados sin ciudad. Ejecuta la migración.');
      } else {
        print('\n✅ Todos los abogados tienen ciudad asignada.');
      }
      
    } catch (e) {
      print('❌ Error verificando datos: $e');
    }
  }

  // Ejecutar verificación y migración si es necesario
  Future<void> autoFix() async {
    await checkDataStatus();
    
    // Preguntar si ejecutar migración (en un contexto real, esto sería automático)
    print('\n🤔 ¿Ejecutar migración automática? (Esto se ejecutará automáticamente)');
    await fixCityFieldForAllLawyers();
    
    print('\n🔍 Verificando después de la migración...');
    await checkDataStatus();
  }
}

// Función helper para ejecutar desde cualquier lugar
Future<void> runQuickCityMigration() async {
  QuickCityMigration migration = QuickCityMigration();
  await migration.autoFix();
}