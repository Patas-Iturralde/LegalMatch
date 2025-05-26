import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/mediation.dart';

class MediationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Crear un nuevo caso de mediación
  Future<void> createMediationCase({
    required String clientId,
    required String clientName,
    required String lawyerEmail,
    required String title,
    required String description,
  }) async {
    // Buscar al abogado por email
    final lawyerQuery = await _firestore
        .collection('lawyers')
        .where('email', isEqualTo: lawyerEmail)
        .get();

    if (lawyerQuery.docs.isEmpty) {
      throw Exception('No se encontró un abogado con ese email');
    }

    final lawyerDoc = lawyerQuery.docs.first;
    final lawyerData = lawyerDoc.data();

    // Crear el caso de mediación (sin mediador, solo cliente y abogado)
    final mediationCase = MediationCase(
      id: '',
      clientId: clientId,
      clientName: clientName,
      lawyerId: lawyerDoc.id,
      lawyerName: lawyerData['name'] ?? '',
      title: title,
      description: description,
      status: 'active', // Directamente activo para que puedan chatear
      createdAt: DateTime.now(),
    );

    final docRef = await _firestore.collection('mediation_cases').add(mediationCase.toMap());

    // Enviar mensaje inicial del sistema
    await _firestore
        .collection('mediation_cases')
        .doc(docRef.id)
        .collection('messages')
        .add({
      'caseId': docRef.id,
      'senderId': 'system',
      'senderName': 'Sistema',
      'senderType': 'system',
      'message': 'Caso de mediación iniciado entre ${clientName} y ${lawyerData['name']}. Pueden comenzar a comunicarse para resolver el conflicto.',
      'timestamp': Timestamp.now(),
      'isSystemMessage': true,
    });

    // Notificar al abogado con un mensaje automático
    await _firestore
        .collection('mediation_cases')
        .doc(docRef.id)
        .collection('messages')
        .add({
      'caseId': docRef.id,
      'senderId': 'system',
      'senderName': 'Sistema',
      'senderType': 'system',
      'message': '${lawyerData['name']}, tienes una nueva solicitud de mediación de ${clientName}. Por favor revisa la descripción del caso y comienza la conversación.',
      'timestamp': Timestamp.now(),
      'isSystemMessage': true,
    });
  }

  // Obtener casos de mediación para un cliente
  Stream<List<MediationCase>> getClientMediationCases(String clientId, String status) {
    return _firestore
        .collection('mediation_cases')
        .where('clientId', isEqualTo: clientId)
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return MediationCase.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Obtener casos de mediación para un abogado
  Stream<List<MediationCase>> getLawyerMediationCases(String lawyerId, String status) {
    return _firestore
        .collection('mediation_cases')
        .where('lawyerId', isEqualTo: lawyerId)
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return MediationCase.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Obtener mensajes de un caso
  Stream<List<MediationMessage>> getCaseMessages(String caseId) {
    return _firestore
        .collection('mediation_cases')
        .doc(caseId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return MediationMessage.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Enviar un mensaje
  Future<void> sendMessage({
    required String caseId,
    required String senderId,
    required String senderName,
    required String senderType,
    required String message,
  }) async {
    final messageData = MediationMessage(
      id: '',
      caseId: caseId,
      senderId: senderId,
      senderName: senderName,
      senderType: senderType,
      message: message,
      timestamp: DateTime.now(),
    );

    await _firestore
        .collection('mediation_cases')
        .doc(caseId)
        .collection('messages')
        .add(messageData.toMap());
  }

  // Programar una sesión de mediación
  Future<void> scheduleSession(String caseId, DateTime scheduledAt) async {
    await _firestore.collection('mediation_cases').doc(caseId).update({
      'scheduledAt': Timestamp.fromDate(scheduledAt),
    });

    // Enviar mensaje del sistema
    await _firestore
        .collection('mediation_cases')
        .doc(caseId)
        .collection('messages')
        .add({
      'caseId': caseId,
      'senderId': 'system',
      'senderName': 'Sistema',
      'senderType': 'system',
      'message': 'Sesión de mediación programada para ${scheduledAt.day}/${scheduledAt.month}/${scheduledAt.year} a las ${scheduledAt.hour}:${scheduledAt.minute.toString().padLeft(2, '0')}',
      'timestamp': Timestamp.now(),
      'isSystemMessage': true,
    });
  }

  // Resolver un caso
  Future<void> resolveCase(String caseId, String resolution) async {
    await _firestore.collection('mediation_cases').doc(caseId).update({
      'status': 'resolved',
      'resolvedAt': Timestamp.now(),
      'resolution': resolution,
    });

    // Enviar mensaje del sistema
    await _firestore
        .collection('mediation_cases')
        .doc(caseId)
        .collection('messages')
        .add({
      'caseId': caseId,
      'senderId': 'system',
      'senderName': 'Sistema',
      'senderType': 'system',
      'message': 'Caso de mediación resuelto. ${resolution.isNotEmpty ? "Resolución: $resolution" : ""}',
      'timestamp': Timestamp.now(),
      'isSystemMessage': true,
    });
  }

  // Cancelar un caso
  Future<void> cancelCase(String caseId, String reason) async {
    await _firestore.collection('mediation_cases').doc(caseId).update({
      'status': 'cancelled',
    });

    // Enviar mensaje del sistema
    await _firestore
        .collection('mediation_cases')
        .doc(caseId)
        .collection('messages')
        .add({
      'caseId': caseId,
      'senderId': 'system',
      'senderName': 'Sistema',
      'senderType': 'system',
      'message': 'Caso de mediación cancelado. ${reason.isNotEmpty ? "Razón: $reason" : ""}',
      'timestamp': Timestamp.now(),
      'isSystemMessage': true,
    });
  }

  // Obtener un caso específico por ID
  Future<MediationCase?> getCaseById(String caseId) async {
    try {
      final doc = await _firestore.collection('mediation_cases').doc(caseId).get();
      if (doc.exists) {
        return MediationCase.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error al obtener caso de mediación: $e');
      return null;
    }
  }
}