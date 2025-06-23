import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lawyer.dart';
import '../models/review.dart';

class LawyerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener todos los abogados
  Stream<List<Lawyer>> getLawyers() {
    return _firestore.collection('lawyers').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Lawyer.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Obtener abogados por especialidad
  Stream<List<Lawyer>> getLawyersBySpecialty(String specialty) {
    return _firestore
        .collection('lawyers')
        .where('specialties', arrayContains: specialty)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Lawyer.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Obtener abogados por ciudad
  Stream<List<Lawyer>> getLawyersByCity(String city) {
    return _firestore
        .collection('lawyers')
        .where('city', isEqualTo: city)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Lawyer.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Obtener abogados por especialidad y ciudad
  Stream<List<Lawyer>> getLawyersBySpecialtyAndCity(String specialty, String city) {
    return _firestore
        .collection('lawyers')
        .where('specialties', arrayContains: specialty)
        .where('city', isEqualTo: city)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Lawyer.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Buscar abogados por nombre
  Stream<List<Lawyer>> searchLawyersByName(String query) {
    String searchQuery = query.toLowerCase();
    
    return _firestore.collection('lawyers').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Lawyer.fromMap(doc.data(), doc.id))
          .where((lawyer) => lawyer.name.toLowerCase().contains(searchQuery))
          .toList();
    });
  }

  // Búsqueda avanzada con múltiples filtros
  Future<List<Lawyer>> searchLawyers({
    String? name,
    String? specialty,
    String? city,
    double? minPrice,
    double? maxPrice,
    double? minRating,
  }) async {
    try {
      // Obtener todos los abogados primero
      final querySnapshot = await _firestore.collection('lawyers').get();
      List<Lawyer> lawyers = [];

      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          
          // Validar que tenga los campos básicos antes de crear el objeto
          if (data['name'] != null && data['email'] != null) {
            final lawyer = Lawyer.fromMap(data, doc.id);
            lawyers.add(lawyer);
          }
        } catch (e) {
          print('Error procesando abogado ${doc.id}: $e');
          continue; // Saltar este documento y continuar con el siguiente
        }
      }

      // Aplicar filtros en memoria
      List<Lawyer> filteredLawyers = lawyers.where((lawyer) {
        // Filtro por nombre
        if (name != null && name.isNotEmpty) {
          String searchName = name.toLowerCase();
          if (!lawyer.name.toLowerCase().contains(searchName)) {
            return false;
          }
        }

        // Filtro por especialidad
        if (specialty != null && specialty.isNotEmpty) {
          if (!lawyer.specialties.contains(specialty)) {
            return false;
          }
        }

        // Filtro por ciudad
        if (city != null && city.isNotEmpty) {
          if (lawyer.city != city) {
            return false;
          }
        }

        // Filtro por precio mínimo
        if (minPrice != null) {
          if (lawyer.consultationPrice < minPrice) {
            return false;
          }
        }

        // Filtro por precio máximo
        if (maxPrice != null) {
          if (lawyer.consultationPrice > maxPrice) {
            return false;
          }
        }

        // Filtro por rating mínimo
        if (minRating != null) {
          if (lawyer.rating < minRating) {
            return false;
          }
        }

        return true;
      }).toList();

      // Ordenar por rating descendente
      filteredLawyers.sort((a, b) => b.rating.compareTo(a.rating));

      return filteredLawyers;
    } catch (e) {
      print('Error en búsqueda avanzada: $e');
      return [];
    }
  }

  // Obtener un abogado por ID
  Future<Lawyer?> getLawyerById(String id) async {
    DocumentSnapshot doc = await _firestore.collection('lawyers').doc(id).get();
    if (doc.exists) {
      return Lawyer.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  // Actualizar perfil de abogado
  Future<void> updateLawyerProfile(Lawyer lawyer) async {
    return await _firestore.collection('lawyers').doc(lawyer.id).update(lawyer.toMap());
  }

  // Obtener comentarios de un abogado
  Stream<List<Review>> getLawyerReviews(String lawyerId) {
    return _firestore
        .collection('reviews')
        .where('lawyerId', isEqualTo: lawyerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Review.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Agregar un comentario
  Future<void> addReview(Review review) async {
    await _firestore.collection('reviews').add(review.toMap());
    
    // Actualizar el rating promedio del abogado
    await _updateLawyerRating(review.lawyerId);
  }

  // Método privado para actualizar el rating del abogado
  Future<void> _updateLawyerRating(String lawyerId) async {
    final reviewsSnapshot = await _firestore
        .collection('reviews')
        .where('lawyerId', isEqualTo: lawyerId)
        .get();

    if (reviewsSnapshot.docs.isEmpty) return;

    double totalRating = 0;
    int reviewCount = reviewsSnapshot.docs.length;

    for (var doc in reviewsSnapshot.docs) {
      totalRating += (doc.data()['rating'] ?? 0.0).toDouble();
    }

    double averageRating = totalRating / reviewCount;

    await _firestore.collection('lawyers').doc(lawyerId).update({
      'rating': averageRating,
      'reviewCount': reviewCount,
    });
  }

  // Obtener todas las especialidades disponibles
  Future<List<String>> getSpecialties() async {
    try {
      final snapshot = await _firestore.collection('specialties').get();
      return snapshot.docs.map((doc) => doc['name'] as String).toList();
    } catch (e) {
      // Lista por defecto de especialidades si no hay en la base de datos
      return [
        'Derecho Civil',
        'Derecho Penal',
        'Derecho Laboral',
        'Derecho Familiar',
        'Derecho Comercial',
        'Derecho Tributario',
        'Derecho Constitucional',
        'Derecho Administrativo',
        'Derecho Internacional',
        'Derecho Ambiental',
        'Propiedad Intelectual',
        'Derecho Inmobiliario',
      ];
    }
  }

  // Obtener estadísticas de ciudades con más abogados
  Future<Map<String, int>> getCityStatistics() async {
    try {
      final snapshot = await _firestore.collection('lawyers').get();
      Map<String, int> cityCount = {};

      for (var doc in snapshot.docs) {
        String city = doc.data()['city'] ?? 'No especificada';
        cityCount[city] = (cityCount[city] ?? 0) + 1;
      }

      // Ordenar por cantidad de abogados
      var sortedEntries = cityCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return Map.fromEntries(sortedEntries);
    } catch (e) {
      print('Error al obtener estadísticas de ciudades: $e');
      return {};
    }
  }

  // Obtener ciudades donde hay abogados disponibles
  Future<List<String>> getAvailableCities() async {
    try {
      final snapshot = await _firestore.collection('lawyers').get();
      Set<String> cities = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final city = data['city'];
        
        // Verificar que city no sea null y no esté vacío
        if (city != null && city is String && city.trim().isNotEmpty) {
          cities.add(city.trim());
        }
      }

      List<String> cityList = cities.toList();
      cityList.sort();
      return cityList;
    } catch (e) {
      print('Error al obtener ciudades disponibles: $e');
      // Retornar ciudades principales como fallback
      return [
        'Quito',
        'Guayaquil', 
        'Cuenca',
        'Ambato',
        'Loja',
        'Machala',
        'Riobamba',
        'Portoviejo',
        'Ibarra',
        'Santo Domingo'
      ];
    }
  }
}