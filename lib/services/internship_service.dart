import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/internship.dart';

class InternshipService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener vacantes activas
  Stream<List<Internship>> getActiveInternships() {
    return _firestore
        .collection('internships')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Internship.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Obtener vacantes por abogado
  Stream<List<Internship>> getInternshipsByLawyer(String lawyerId) {
    return _firestore
        .collection('internships')
        .where('lawyerId', isEqualTo: lawyerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Internship.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Crear nueva vacante
  Future<void> createInternship(Internship internship) async {
    DocumentReference docRef = await _firestore.collection('internships').add(internship.toMap());
    // No es necesario actualizar el ID después de crear, ya que no lo estamos utilizando nuevamente
  }

  // Actualizar estado de la vacante (activar/desactivar)
  Future<void> updateInternshipStatus(String internshipId, bool isActive) async {
    await _firestore.collection('internships').doc(internshipId).update({
      'isActive': isActive,
    });
  }

  // Eliminar vacante
  Future<void> deleteInternship(String internshipId) async {
    await _firestore.collection('internships').doc(internshipId).delete();
  }

  // Aplicar a una vacante
  Future<void> applyForInternship({
    required String internshipId,
    required String clientId,
    required String clientName,
    required String clientEmail,
  }) async {
    // Verificar si ya ha aplicado
    QuerySnapshot existingApplications = await _firestore
        .collection('internship_applications')
        .where('internshipId', isEqualTo: internshipId)
        .where('clientId', isEqualTo: clientId)
        .get();

    if (existingApplications.docs.isNotEmpty) {
      throw Exception('Ya has aplicado a esta vacante');
    }

    // Crear nueva aplicación
    await _firestore.collection('internship_applications').add({
      'internshipId': internshipId,
      'clientId': clientId,
      'clientName': clientName,
      'clientEmail': clientEmail,
      'appliedAt': Timestamp.now(),
      'status': 'pending',
    });
  }

  // Obtener aplicaciones para una vacante
  Stream<List<InternshipApplication>> getInternshipApplications(String internshipId) {
    return _firestore
        .collection('internship_applications')
        .where('internshipId', isEqualTo: internshipId)
        .orderBy('appliedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return InternshipApplication.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Actualizar estado de una aplicación
  Future<void> updateApplicationStatus(String applicationId, String status) async {
    await _firestore.collection('internship_applications').doc(applicationId).update({
      'status': status,
    });
  }
}