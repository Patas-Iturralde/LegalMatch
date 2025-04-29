import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Crear un nuevo chat
  Future<String?> createNewChat(String userName) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final chatRef = await _firestore.collection('live_chats').add({
        'userId': user.uid,
        'userName': userName,
        'createdAt': Timestamp.now(),
        'status': 'active',
        'hasLawyer': false,
        'lawyerId': null,
        'lawyerName': null,
        'recommendedSpecialty': null,
      });

      return chatRef.id;
    } catch (e) {
      print('Error al crear chat: $e');
      return null;
    }
  }

  // Unirse a un chat como abogado
  Future<String?> joinChatAsLawyer(String lawyerName) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      // Buscar chats activos sin abogado
      final querySnapshot = await _firestore
          .collection('live_chats')
          .where('status', isEqualTo: 'active')
          .where('hasLawyer', isEqualTo: false)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null; // No hay chats disponibles
      }

      final chatDoc = querySnapshot.docs.first;
      
      // Actualizar el chat con la información del abogado
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

  // Enviar un mensaje
  Future<bool> sendMessage(String chatId, String message, String senderName, bool isLawyer) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

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

      return true;
    } catch (e) {
      print('Error al enviar mensaje: $e');
      return false;
    }
  }

  // Recomendar una especialidad
  Future<bool> recommendSpecialty(String chatId, String specialty, String lawyerName) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Actualizar el chat con la especialidad recomendada
      await _firestore.collection('live_chats').doc(chatId).update({
        'recommendedSpecialty': specialty,
      });

      // Enviar mensaje de recomendación
      await _firestore
          .collection('live_chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'text': 'Basado en tu consulta, te recomiendo buscar un abogado especializado en $specialty',
        'senderId': user.uid,
        'senderName': lawyerName,
        'isLawyer': true,
        'isRecommendation': true,
        'specialty': specialty,
        'timestamp': Timestamp.now(),
      });

      return true;
    } catch (e) {
      print('Error al recomendar especialidad: $e');
      return false;
    }
  }

  // Finalizar chat
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

  // Obtener chats activos para un usuario
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

  // Obtener mensajes de un chat
  Stream<QuerySnapshot> getChatMessages(String chatId) {
    return _firestore
        .collection('live_chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots();
  }
}