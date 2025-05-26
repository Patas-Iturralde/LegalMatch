import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/alternative_resolution.dart';

class AlternativeResolutionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // MÉTODO AUXILIAR PARA OBTENER NOMBRE DE USUARIO
  Future<String> _getUserName(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        return userData['name'] ?? 'Usuario';
      }
      return 'Usuario';
    } catch (e) {
      print('Error al obtener nombre de usuario: $e');
      return 'Usuario';
    }
  }

  // Crear un nuevo caso de resolución alternativa - CORREGIDO
  Future<String> createResolutionCase({
    required String clientId,
    required String clientName,
    required String lawyerEmail,
    required ResolutionType type,
    required String title,
    required String description,
    double? amount,
    Map<String, dynamic>? additionalData,
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

    // OBTENER EL NOMBRE REAL DEL CLIENTE DESDE LA BASE DE DATOS
    String realClientName = clientName;
    try {
      final userDoc = await _firestore.collection('users').doc(clientId).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        realClientName = userData['name'] ?? clientName;
      }
    } catch (e) {
      print('Error al obtener nombre del cliente: $e');
      // Usar el nombre proporcionado como fallback
    }

    // Crear el caso con el nombre real del cliente
    final resolutionCase = AlternativeResolutionCase(
      id: '',
      clientId: clientId,
      clientName: realClientName, // USAR EL NOMBRE REAL
      lawyerId: lawyerDoc.id,
      lawyerName: lawyerData['name'] ?? '',
      type: type,
      title: title,
      description: description,
      status: 'active',
      createdAt: DateTime.now(),
      amount: amount,
      additionalData: additionalData ?? {},
    );

    final docRef = await _firestore
        .collection('alternative_resolution_cases')
        .add(resolutionCase.toMap());

    // Enviar mensaje inicial del sistema con nombres reales
    await _sendSystemMessage(
      caseId: docRef.id,
      message: '${resolutionCase.typeDisplayName} iniciada entre $realClientName y ${lawyerData['name']}. ${resolutionCase.typeDescription}',
    );

    // Mensaje específico según el tipo
    if (type == ResolutionType.mediation) {
      await _sendSystemMessage(
        caseId: docRef.id,
        message: 'Proceso de mediación: Ambas partes pueden dialogar libremente para encontrar una solución mutuamente beneficiosa. El mediador facilitará la comunicación.',
      );
    } else {
      await _sendSystemMessage(
        caseId: docRef.id,
        message: 'Proceso de arbitraje: Cada parte debe presentar sus argumentos y evidencias. El árbitro tomará una decisión vinculante basada en los hechos presentados.',
      );
    }

    return docRef.id;
  }

  // Obtener casos para un cliente
  Stream<List<AlternativeResolutionCase>> getClientCases(String clientId, String status) {
    return _firestore
        .collection('alternative_resolution_cases')
        .where('clientId', isEqualTo: clientId)
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return AlternativeResolutionCase.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Obtener casos para un abogado
  Stream<List<AlternativeResolutionCase>> getLawyerCases(String lawyerId, String status) {
    return _firestore
        .collection('alternative_resolution_cases')
        .where('lawyerId', isEqualTo: lawyerId)
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return AlternativeResolutionCase.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Obtener mensajes de un caso
  Stream<List<ResolutionMessage>> getCaseMessages(String caseId) {
    return _firestore
        .collection('alternative_resolution_cases')
        .doc(caseId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ResolutionMessage.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Enviar un mensaje - MEJORADO PARA OBTENER NOMBRES REALES
  Future<void> sendMessage({
    required String caseId,
    required String senderId,
    required String senderName,
    required String senderType,
    required String message,
    MessageType messageType = MessageType.text,
    String? attachmentUrl,
    String? attachmentName,
  }) async {
    // VERIFICAR Y OBTENER EL NOMBRE REAL SI ES NECESARIO
    String realSenderName = senderName;
    if (senderName == 'Usuario' || senderName.isEmpty) {
      realSenderName = await _getUserName(senderId);
    }

    final messageData = ResolutionMessage(
      id: '',
      caseId: caseId,
      senderId: senderId,
      senderName: realSenderName, // USAR NOMBRE REAL
      senderType: senderType,
      message: message,
      timestamp: DateTime.now(),
      messageType: messageType,
      attachmentUrl: attachmentUrl,
      attachmentName: attachmentName,
    );

    await _firestore
        .collection('alternative_resolution_cases')
        .doc(caseId)
        .collection('messages')
        .add(messageData.toMap());
  }

  // Enviar mensaje del sistema
  Future<void> _sendSystemMessage({
    required String caseId,
    required String message,
  }) async {
    await _firestore
        .collection('alternative_resolution_cases')
        .doc(caseId)
        .collection('messages')
        .add({
      'caseId': caseId,
      'senderId': 'system',
      'senderName': 'Sistema MARC',
      'senderType': 'system',
      'message': message,
      'timestamp': Timestamp.now(),
      'isSystemMessage': true,
      'messageType': 'text',
    });
  }

  // Hacer una propuesta (para mediación) - MEJORADO
  Future<void> makeProposal({
  required String caseId,
  required String senderId,
  required String senderName,
  required String senderType,
  required String proposal,
  double? amount,
}) async {
  // Obtener nombre real si es necesario
  String realSenderName = senderName;
  if (senderName == 'Usuario' || senderName.isEmpty) {
    realSenderName = await _getUserName(senderId);
  }

  // Crear mensaje de propuesta con estado 'pending'
  final messageData = ResolutionMessage(
    id: '',
    caseId: caseId,
    senderId: senderId,
    senderName: realSenderName,
    senderType: senderType,
    message: proposal,
    timestamp: DateTime.now(),
    messageType: MessageType.proposal,
    proposalStatus: 'pending', // NUEVO - Estado inicial
  );

  await _firestore
      .collection('alternative_resolution_cases')
      .doc(caseId)
      .collection('messages')
      .add(messageData.toMap());

  await _sendSystemMessage(
    caseId: caseId,
    message: '$realSenderName ha hecho una propuesta de acuerdo. ${amount != null ? "Monto propuesto: \$${amount.toStringAsFixed(2)}" : ""}',
  );
}

// NUEVO MÉTODO para marcar propuesta como respondida
Future<void> _markProposalAsResponded({
  required String caseId,
  required String messageId,
  required String status, // 'accepted' o 'rejected'
  required String respondedBy,
}) async {
  await _firestore
      .collection('alternative_resolution_cases')
      .doc(caseId)
      .collection('messages')
      .doc(messageId)
      .update({
    'proposalStatus': status,
    'respondedBy': respondedBy,
    'respondedAt': Timestamp.now(),
  });
}

  // Tomar decisión de arbitraje - MEJORADO
  Future<void> makeArbitrationDecision({
    required String caseId,
    required String arbitratorId,
    required String arbitratorName,
    required String decision,
    double? awardAmount,
    Map<String, dynamic>? terms,
  }) async {
    // OBTENER NOMBRE REAL DEL ÁRBITRO
    String realArbitratorName = arbitratorName;
    if (arbitratorName == 'Usuario' || arbitratorName.isEmpty) {
      realArbitratorName = await _getUserName(arbitratorId);
    }

    // Enviar mensaje de decisión
    await sendMessage(
      caseId: caseId,
      senderId: arbitratorId,
      senderName: realArbitratorName,
      senderType: 'lawyer',
      message: decision,
      messageType: MessageType.decision,
    );

    // Crear resolución
    await _firestore.collection('resolutions').add({
      'caseId': caseId,
      'type': 'award',
      'content': decision,
      'dateIssued': Timestamp.now(),
      'isBinding': true,
      'amount': awardAmount,
      'terms': terms ?? {},
    });

    // Actualizar estado del caso
    await _firestore
        .collection('alternative_resolution_cases')
        .doc(caseId)
        .update({
      'status': 'resolved',
      'resolvedAt': Timestamp.now(),
      'resolution': decision,
    });

    await _sendSystemMessage(
      caseId: caseId,
      message: 'Decisión de arbitraje emitida por $realArbitratorName. Esta decisión es vinculante para ambas partes.',
    );
  }

  // Aceptar propuesta (para mediación) - MEJORADO
  Future<void> acceptProposal({
  required String caseId,
  required String acceptorId,
  required String acceptorName,
  required String proposalContent,
  String? originalMessageId, // NUEVO parámetro
}) async {
  // Obtener nombre real si es necesario
  String realAcceptorName = acceptorName;
  if (acceptorName == 'Usuario' || acceptorName.isEmpty) {
    realAcceptorName = await _getUserName(acceptorId);
  }

  await sendMessage(
    caseId: caseId,
    senderId: acceptorId,
    senderName: realAcceptorName,
    senderType: acceptorId.contains('lawyer') ? 'lawyer' : 'client',
    message: 'He aceptado la propuesta: $proposalContent',
  );

  // MARCAR LA PROPUESTA ORIGINAL COMO ACEPTADA
  if (originalMessageId != null) {
    await _markProposalAsResponded(
      caseId: caseId,
      messageId: originalMessageId,
      status: 'accepted',
      respondedBy: acceptorId,
    );
  }

  // Crear acuerdo
  await _firestore.collection('resolutions').add({
    'caseId': caseId,
    'type': 'agreement',
    'content': proposalContent,
    'dateIssued': Timestamp.now(),
    'isBinding': false,
    'terms': {'acceptedBy': acceptorId, 'acceptedAt': Timestamp.now()},
  });

  // Actualizar estado del caso
  await _firestore
      .collection('alternative_resolution_cases')
      .doc(caseId)
      .update({
    'status': 'resolved',
    'resolvedAt': Timestamp.now(),
    'resolution': proposalContent,
  });

  await _sendSystemMessage(
    caseId: caseId,
    message: '🎉 ¡Acuerdo alcanzado! La propuesta ha sido aceptada por $realAcceptorName.',
  );
}

  // Rechazar propuesta - MEJORADO
  Future<void> rejectProposal({
  required String caseId,
  required String rejectorId,
  required String rejectorName,
  required String reason,
  String? originalMessageId, // NUEVO parámetro
}) async {
  // Obtener nombre real si es necesario
  String realRejectorName = rejectorName;
  if (rejectorName == 'Usuario' || rejectorName.isEmpty) {
    realRejectorName = await _getUserName(rejectorId);
  }

  await sendMessage(
    caseId: caseId,
    senderId: rejectorId,
    senderName: realRejectorName,
    senderType: rejectorId.contains('lawyer') ? 'lawyer' : 'client',
    message: 'He rechazado la propuesta. Razón: $reason',
  );

  // MARCAR LA PROPUESTA ORIGINAL COMO RECHAZADA
  if (originalMessageId != null) {
    await _markProposalAsResponded(
      caseId: caseId,
      messageId: originalMessageId,
      status: 'rejected',
      respondedBy: rejectorId,
    );
  }

  await _sendSystemMessage(
    caseId: caseId,
    message: 'La propuesta ha sido rechazada por $realRejectorName. Las partes pueden continuar negociando.',
  );
}

  // Programar sesión
  Future<void> scheduleSession({
    required String caseId,
    required DateTime scheduledDate,
    required String scheduledBy,
    String? notes,
  }) async {
    await _firestore
        .collection('alternative_resolution_cases')
        .doc(caseId)
        .update({
      'scheduledAt': Timestamp.fromDate(scheduledDate),
    });

    await _sendSystemMessage(
      caseId: caseId,
      message: 'Sesión programada para ${scheduledDate.day}/${scheduledDate.month}/${scheduledDate.year} a las ${scheduledDate.hour}:${scheduledDate.minute.toString().padLeft(2, '0')}. ${notes ?? ""}',
    );
  }

  // Cerrar caso
  Future<void> closeCase({
    required String caseId,
    required String reason,
    String? resolution,
  }) async {
    await _firestore
        .collection('alternative_resolution_cases')
        .doc(caseId)
        .update({
      'status': 'cancelled',
      'resolution': resolution ?? reason,
    });

    await _sendSystemMessage(
      caseId: caseId,
      message: 'Caso cerrado. Razón: $reason',
    );
  }

  // Obtener un caso específico
  Future<AlternativeResolutionCase?> getCaseById(String caseId) async {
    try {
      final doc = await _firestore
          .collection('alternative_resolution_cases')
          .doc(caseId)
          .get();
      
      if (doc.exists) {
        return AlternativeResolutionCase.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error al obtener caso: $e');
      return null;
    }
  }

  // Obtener estadísticas
  Future<Map<String, int>> getStatistics(String userId, bool isLawyer) async {
    final field = isLawyer ? 'lawyerId' : 'clientId';
    
    final activeQuery = await _firestore
        .collection('alternative_resolution_cases')
        .where(field, isEqualTo: userId)
        .where('status', isEqualTo: 'active')
        .get();

    final resolvedQuery = await _firestore
        .collection('alternative_resolution_cases')
        .where(field, isEqualTo: userId)
        .where('status', isEqualTo: 'resolved')
        .get();

    final mediationQuery = await _firestore
        .collection('alternative_resolution_cases')
        .where(field, isEqualTo: userId)
        .where('type', isEqualTo: 'mediation')
        .get();

    final arbitrationQuery = await _firestore
        .collection('alternative_resolution_cases')
        .where(field, isEqualTo: userId)
        .where('type', isEqualTo: 'arbitration')
        .get();

    return {
      'active': activeQuery.docs.length,
      'resolved': resolvedQuery.docs.length,
      'mediation': mediationQuery.docs.length,
      'arbitration': arbitrationQuery.docs.length,
    };
  }
}