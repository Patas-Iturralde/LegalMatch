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
        .where('specialty', isEqualTo: specialty)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Lawyer.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Buscar abogados por nombre
  Stream<List<Lawyer>> searchLawyersByName(String query) {
    // Convertir la consulta a minúsculas para búsqueda insensible a mayúsculas
    String searchQuery = query.toLowerCase();
    
    // Firebase no soporta directamente búsquedas insensibles a mayúsculas,
    // así que obtenemos todos y filtramos
    return _firestore.collection('lawyers').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Lawyer.fromMap(doc.data(), doc.id))
          .where((lawyer) => lawyer.name.toLowerCase().contains(searchQuery))
          .toList();
    });
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

  // Agregar comentario para un abogado
  Future<void> addReview({
    required String lawyerId,
    required String clientId,
    required String clientName,
    required String text,
    required double rating,
  }) async {
    // Crear nuevo comentario
    DocumentReference reviewRef = await _firestore.collection('reviews').add({
      'lawyerId': lawyerId,
      'clientId': clientId,
      'clientName': clientName,
      'text': text,
      'rating': rating,
      'createdAt': Timestamp.now(),
    });

    // Actualizar la calificación promedio del abogado
    DocumentSnapshot lawyerDoc = await _firestore.collection('lawyers').doc(lawyerId).get();
    if (lawyerDoc.exists) {
      Map<String, dynamic> lawyerData = lawyerDoc.data() as Map<String, dynamic>;
      int reviewCount = (lawyerData['reviewCount'] ?? 0) + 1;
      double currentRating = (lawyerData['rating'] ?? 0.0).toDouble();
      
      // Calcular nueva calificación promedio
      double newRating = ((currentRating * (reviewCount - 1)) + rating) / reviewCount;
      
      // Actualizar documento del abogado
      await _firestore.collection('lawyers').doc(lawyerId).update({
        'rating': newRating,
        'reviewCount': reviewCount,
      });
    }
  }

  // Obtener lista de especialidades disponibles
  Future<List<String>> getSpecialties() async {
    QuerySnapshot snapshot = await _firestore.collection('specialties').get();
    return snapshot.docs
        .map((doc) => doc['name'] as String)
        .toList();
  }
}