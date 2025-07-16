import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'gemini_service.dart'; // Importa el servicio de Gemini

class EnhancedChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GeminiService _geminiService = GeminiService();

  // Enviar mensaje con análisis de IA
  Future<bool> sendMessageWithAI(String chatId, String message, String senderName, bool isLawyer) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Enviar el mensaje del usuario
      await _firestore
          .collection('live_chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'text': message,
        'senderId': user.uid,
        'senderName': senderName,
        'isLawyer': isLawyer,
        'timestamp': Timestamp.now(),
      });

      // Si es un mensaje de cliente, procesar con IA
      if (!isLawyer) {
        await _processClientMessage(chatId, message, senderName);
      }

      return true;
    } catch (e) {
      print('Error al enviar mensaje con IA: $e');
      return false;
    }
  }

  // Procesar mensaje del cliente con IA
  Future<void> _processClientMessage(String chatId, String message, String senderName) async {
    try {
      // Verificar si es urgente
      final isUrgent = await _geminiService.isUrgentConsultation(message);
      
      if (isUrgent) {
        await _sendAIResponse(
          chatId,
          'Tu consulta ha sido marcada como urgente. Un abogado te atenderá con prioridad.',
          isUrgent: true,
        );
      }

      // Clasificar especialidad
      final specialty = await _geminiService.classifyLegalSpecialty(message);
      
      // Actualizar el chat con la especialidad detectada
      await _firestore.collection('live_chats').doc(chatId).update({
        'detectedSpecialty': specialty,
        'isUrgent': isUrgent,
        'aiProcessed': true,
      });

      // Generar respuesta de IA
      final aiResponse = await _geminiService.getLegalAdvice(message);
      await _sendAIResponse(chatId, aiResponse);

      // Generar preguntas de seguimiento
      final followUpQuestions = await _geminiService.generateFollowUpQuestions(message);
      if (followUpQuestions.isNotEmpty) {
        await _sendFollowUpQuestions(chatId, followUpQuestions);
      }

    } catch (e) {
      print('Error al procesar mensaje con IA: $e');
    }
  }

  // Enviar respuesta de IA
  Future<void> _sendAIResponse(String chatId, String response, {bool isUrgent = false}) async {
    await _firestore
        .collection('live_chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'text': response,
      'senderId': 'ai_assistant',
      'senderName': 'Asistente Legal IA',
      'isLawyer': false,
      'isAI': true,
      'isUrgent': isUrgent,
      'timestamp': Timestamp.now(),
    });
  }

  // Enviar preguntas de seguimiento
  Future<void> _sendFollowUpQuestions(String chatId, List<String> questions) async {
    final questionsText = 'Para ayudarte mejor, ¿podrías responder estas preguntas?\n\n' +
        questions.asMap().entries.map((entry) => '${entry.key + 1}. ${entry.value}').join('\n');

    await _firestore
        .collection('live_chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'text': questionsText,
      'senderId': 'ai_assistant',
      'senderName': 'Asistente Legal IA',
      'isLawyer': false,
      'isAI': true,
      'isFollowUp': true,
      'timestamp': Timestamp.now(),
    });
  }

  // Generar resumen del caso para el abogado
  Future<String> generateCaseSummaryForLawyer(String chatId) async {
    try {
      final messagesSnapshot = await _firestore
          .collection('live_chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp')
          .get();

      final messages = messagesSnapshot.docs
          .map((doc) => doc.data()['text'] as String)
          .toList();

      return await _geminiService.generateCaseSummary(messages);
    } catch (e) {
      print('Error al generar resumen: $e');
      return 'Error al generar resumen del caso.';
    }
  }

  // Obtener chats urgentes para abogados
  Stream<QuerySnapshot> getUrgentChats() {
    return _firestore
        .collection('live_chats')
        .where('status', isEqualTo: 'active')
        .where('isUrgent', isEqualTo: true)
        .where('hasLawyer', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Obtener chats por especialidad
  Stream<QuerySnapshot> getChatsBySpecialty(String specialty) {
    return _firestore
        .collection('live_chats')
        .where('status', isEqualTo: 'active')
        .where('detectedSpecialty', isEqualTo: specialty)
        .where('hasLawyer', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Crear un nuevo chat con procesamiento de IA
  Future<String?> createNewChatWithAI(String userName, String initialMessage) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      // Crear el chat
      final chatRef = await _firestore.collection('live_chats').add({
        'userId': user.uid,
        'userName': userName,
        'createdAt': Timestamp.now(),
        'status': 'active',
        'hasLawyer': false,
        'lawyerId': null,
        'lawyerName': null,
        'aiProcessed': false,
        'isUrgent': false,
        'detectedSpecialty': null,
      });

      // Enviar mensaje inicial con procesamiento de IA
      await sendMessageWithAI(chatRef.id, initialMessage, userName, false);

      return chatRef.id;
    } catch (e) {
      print('Error al crear chat con IA: $e');
      return null;
    }
  }

  // Resto de métodos del ChatService original...
  Future<String?> joinChatAsLawyer(String lawyerName) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final querySnapshot = await _firestore
          .collection('live_chats')
          .where('status', isEqualTo: 'active')
          .where('hasLawyer', isEqualTo: false)
          .orderBy('isUrgent', descending: true) // Priorizar urgentes
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final chatDoc = querySnapshot.docs.first;
      
      await _firestore.collection('live_chats').doc(chatDoc.id).update({
        'lawyerId': user.uid,
        'lawyerName': lawyerName,
        'hasLawyer': true,
      });

      return chatDoc.id;
    } catch (e) {
      print('Error al unirse al chat: $e');
      return null;
    }
  }

  Future<bool> endChat(String chatId) async {
    try {
      await _firestore.collection('live_chats').doc(chatId).update({
        'status': 'closed',
        'closedAt': Timestamp.now(),
      });

      return true;
    } catch (e) {
      print('Error al finalizar chat: $e');
      return false;
    }
  }

  Stream<QuerySnapshot> getActiveChatsForUser() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.empty();
    }

    return _firestore
        .collection('live_chats')
        .where('userId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'active')
        .snapshots();
  }

  Stream<QuerySnapshot> getChatMessages(String chatId) {
    return _firestore
        .collection('live_chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots();
  }
}