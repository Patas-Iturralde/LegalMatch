import 'package:cloud_firestore/cloud_firestore.dart';

class DataInitializer {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Inicializar especialidades de abogados
  Future<void> initializeSpecialties() async {
    // Lista de especialidades comunes
    final List<String> specialties = [
      'Derecho Civil',
      'Derecho Penal',
      'Derecho Laboral',
      'Derecho Familiar',
      'Derecho Mercantil',
      'Derecho Fiscal',
      'Derecho Administrativo',
      'Derecho Constitucional',
      'Propiedad Intelectual',
      'Derecho Corporativo',
      'Derecho Bancario',
      'Derecho Inmobiliario',
      'Derecho Ambiental',
      'Derecho Migratorio',
      'Derecho Internacional',
    ];

    // Verificar si ya existen especialidades
    final specialtiesRef = _firestore.collection('specialties');
    final snapshot = await specialtiesRef.get();
    
    if (snapshot.docs.isEmpty) {
      // Si no hay especialidades, las creamos
      for (String specialty in specialties) {
        await specialtiesRef.add({
          'name': specialty,
          'createdAt': Timestamp.now(),
        });
      }
      print('Especialidades inicializadas con éxito');
    } else {
      print('Las especialidades ya existen en la base de datos');
    }
  }

  // Inicializar datos de muestra de abogados (opcional)
  Future<void> initializeSampleLawyers() async {
    // Verificar si ya hay abogados en la base de datos
    final lawyersRef = _firestore.collection('lawyers');
    final snapshot = await lawyersRef.limit(1).get();
    
    if (snapshot.docs.isEmpty) {
      // Datos de ejemplo de abogados (solo para desarrollo)
      final List<Map<String, dynamic>> sampleLawyers = [
        {
          'id': 'sample1',
          'name': 'Carlos Rodríguez',
          'specialty': 'Derecho Penal',
          'photoBase64': '', // La foto en base64 se añadiría desde la app
          'consultationPrice': 75.0,
          'email': 'carlos.rodriguez@example.com',
          'description': 'Abogado penalista con 15 años de experiencia en casos de alta complejidad. Especializado en defensa criminal y derecho procesal penal.',
          'rating': 4.7,
          'reviewCount': 24,
        },
        {
          'id': 'sample2',
          'name': 'María González',
          'specialty': 'Derecho Familiar',
          'photoBase64': '', // La foto en base64 se añadiría desde la app
          'consultationPrice': 65.0,
          'email': 'maria.gonzalez@example.com',
          'description': 'Especialista en derecho familiar con enfoque en procesos de divorcio, custodia de menores y pensiones alimenticias. Mediadora certificada en conflictos familiares.',
          'rating': 4.9,
          'reviewCount': 36,
        },
        {
          'id': 'sample3',
          'name': 'Alejandro Méndez',
          'specialty': 'Derecho Laboral',
          'photoBase64': '', // La foto en base64 se añadiría desde la app
          'consultationPrice': 60.0,
          'email': 'alejandro.mendez@example.com',
          'description': 'Abogado laboralista especializado en defensa de derechos de los trabajadores, despidos injustificados y negociaciones colectivas.',
          'rating': 4.5,
          'reviewCount': 18,
        },
      ];
      
      // Crear documentos para cada abogado de ejemplo
      for (var lawyer in sampleLawyers) {
        // Creamos un documento con ID personalizado
        await lawyersRef.doc(lawyer['id']).set({
          'name': lawyer['name'],
          'specialty': lawyer['specialty'],
          'photoBase64': lawyer['photoBase64'],
          'consultationPrice': lawyer['consultationPrice'],
          'email': lawyer['email'],
          'description': lawyer['description'],
          'rating': lawyer['rating'],
          'reviewCount': lawyer['reviewCount'],
          'createdAt': Timestamp.now(),
        });
      }
      
      print('Datos de muestra de abogados inicializados con éxito');
    } else {
      print('Ya existen abogados en la base de datos');
    }
  }

  // Inicializar comentarios de muestra (opcional)
  Future<void> initializeSampleReviews() async {
    // Verificar si ya hay comentarios en la base de datos
    final reviewsRef = _firestore.collection('reviews');
    final snapshot = await reviewsRef.limit(1).get();
    
    if (snapshot.docs.isEmpty) {
      // Datos de ejemplo de comentarios (solo para desarrollo)
      final List<Map<String, dynamic>> sampleReviews = [
        {
          'lawyerId': 'sample1',
          'clientId': 'client1',
          'clientName': 'Juan Pérez',
          'text': 'Excelente abogado, me ayudó a resolver mi caso en tiempo récord. Muy profesional.',
          'rating': 5.0,
          'createdAt': Timestamp.fromDate(DateTime.now().subtract(Duration(days: 5))),
        },
        {
          'lawyerId': 'sample1',
          'clientId': 'client2',
          'clientName': 'Ana López',
          'text': 'Buen servicio, aunque los tiempos de respuesta podrían mejorar. En general satisfecho con los resultados.',
          'rating': 4.0,
          'createdAt': Timestamp.fromDate(DateTime.now().subtract(Duration(days: 10))),
        },
        {
          'lawyerId': 'sample2',
          'clientId': 'client3',
          'clientName': 'Roberto Gómez',
          'text': 'La Dra. González fue muy empática con mi situación familiar. Su asesoría fue fundamental para llegar a un acuerdo beneficioso para todas las partes.',
          'rating': 5.0,
          'createdAt': Timestamp.fromDate(DateTime.now().subtract(Duration(days: 7))),
        },
        {
          'lawyerId': 'sample3',
          'clientId': 'client4',
          'clientName': 'Laura Sánchez',
          'text': 'Gran experiencia. El abogado Méndez conoce a fondo la legislación laboral y me ayudó a recibir la indemnización que me correspondía.',
          'rating': 4.5,
          'createdAt': Timestamp.fromDate(DateTime.now().subtract(Duration(days: 15))),
        },
      ];
      
      // Crear documentos para cada comentario de ejemplo
      for (var review in sampleReviews) {
        await reviewsRef.add({
          'lawyerId': review['lawyerId'],
          'clientId': review['clientId'],
          'clientName': review['clientName'],
          'text': review['text'],
          'rating': review['rating'],
          'createdAt': review['createdAt'],
        });
      }
      
      print('Datos de muestra de comentarios inicializados con éxito');
    } else {
      print('Ya existen comentarios en la base de datos');
    }
  }

  // Inicializar usuarios de muestra (opcional)
  Future<void> initializeSampleUsers() async {
    // Verificar si ya hay usuarios en la base de datos
    final usersRef = _firestore.collection('users');
    final snapshot = await usersRef.limit(1).get();
    
    if (snapshot.docs.isEmpty) {
      // Datos de ejemplo de usuarios (solo para desarrollo)
      final List<Map<String, dynamic>> sampleUsers = [
        {
          'id': 'sample1',
          'name': 'Carlos Rodríguez',
          'email': 'carlos.rodriguez@example.com',
          'userType': 'lawyer',
          'createdAt': Timestamp.now(),
        },
        {
          'id': 'sample2',
          'name': 'María González',
          'email': 'maria.gonzalez@example.com',
          'userType': 'lawyer',
          'createdAt': Timestamp.now(),
        },
        {
          'id': 'sample3',
          'name': 'Alejandro Méndez',
          'email': 'alejandro.mendez@example.com',
          'userType': 'lawyer',
          'createdAt': Timestamp.now(),
        },
        {
          'id': 'client1',
          'name': 'Juan Pérez',
          'email': 'juan.perez@example.com',
          'userType': 'client',
          'createdAt': Timestamp.now(),
        },
        {
          'id': 'client2',
          'name': 'Ana López',
          'email': 'ana.lopez@example.com',
          'userType': 'client',
          'createdAt': Timestamp.now(),
        },
        {
          'id': 'client3',
          'name': 'Roberto Gómez',
          'email': 'roberto.gomez@example.com',
          'userType': 'client',
          'createdAt': Timestamp.now(),
        },
        {
          'id': 'client4',
          'name': 'Laura Sánchez',
          'email': 'laura.sanchez@example.com',
          'userType': 'client',
          'createdAt': Timestamp.now(),
        },
      ];
      
      // Crear documentos para cada usuario de ejemplo
      for (var user in sampleUsers) {
        await usersRef.doc(user['id']).set({
          'name': user['name'],
          'email': user['email'],
          'userType': user['userType'],
          'createdAt': user['createdAt'],
        });
      }
      
      print('Datos de muestra de usuarios inicializados con éxito');
    } else {
      print('Ya existen usuarios en la base de datos');
    }
  }

  // Método para verificar y crear colecciones necesarias
  Future<void> checkAndCreateCollections() async {
    try {
      // Verificar que existan las colecciones necesarias
      await _firestore.collection('lawyers').limit(1).get();
      await _firestore.collection('reviews').limit(1).get();
      await _firestore.collection('users').limit(1).get();
      await _firestore.collection('specialties').limit(1).get();
      
      // Inicializar especialidades
      await initializeSpecialties();
      
      // Opcional: Inicializar datos de muestra
      // Descomentar estas líneas para generar datos de prueba
      // await initializeSampleLawyers();
      // await initializeSampleReviews();
      // await initializeSampleUsers();

      print('Todas las colecciones verificadas e inicializadas correctamente');
    } catch (e) {
      print('Error al verificar o crear colecciones: $e');
    }
  }

  // Configurar reglas de seguridad (esto debe hacerse manualmente en la consola de Firebase)
  void printSecurityRules() {
    print('''
    // Reglas de seguridad recomendadas para Firebase
    rules_version = '2';
    service cloud.firestore {
      match /databases/{database}/documents {
        // Acceso público a especialidades
        match /specialties/{document=**} {
          allow read: if true;
          allow write: if false; // Solo administradores deberían modificar esto
        }
        
        // Perfiles de abogados son públicos para leer
        match /lawyers/{lawyerId} {
          allow read: if true;
          allow write: if request.auth != null && request.auth.uid == lawyerId;
        }
        
        // Comentarios pueden ser leídos por todos,
        // pero solo creados por usuarios autenticados
        match /reviews/{reviewId} {
          allow read: if true;
          allow create: if request.auth != null;
          allow update, delete: if request.auth != null && 
                               request.auth.uid == resource.data.clientId;
        }
        
        // Datos de usuarios solo accesibles por el propio usuario
        match /users/{userId} {
          allow read, write: if request.auth != null && 
                            request.auth.uid == userId;
        }
      }
    }
    ''');
  }
}