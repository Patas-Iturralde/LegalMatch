import 'package:cloud_firestore/cloud_firestore.dart';

class LiveChat {
  final String id;
  final String userId;
  final String userName;
  final DateTime createdAt;
  final String status;
  final bool hasLawyer;
  final String? lawyerId;
  final String? lawyerName;
  final String? recommendedSpecialty;
  final DateTime? closedAt;

  LiveChat({
    required this.id,
    required this.userId,
    required this.userName,
    required this.createdAt,
    required this.status,
    required this.hasLawyer,
    this.lawyerId,
    this.lawyerName,
    this.recommendedSpecialty,
    this.closedAt,
  });

  // Convertir de Firebase a objeto LiveChat
  factory LiveChat.fromMap(Map<String, dynamic> data, String id) {
    return LiveChat(
      id: id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Usuario',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      status: data['status'] ?? 'active',
      hasLawyer: data['hasLawyer'] ?? false,
      lawyerId: data['lawyerId'],
      lawyerName: data['lawyerName'],
      recommendedSpecialty: data['recommendedSpecialty'],
      closedAt: data['closedAt'] != null ? (data['closedAt'] as Timestamp).toDate() : null,
    );
  }

  // Convertir objeto LiveChat a mapa para Firebase
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      'hasLawyer': hasLawyer,
      'lawyerId': lawyerId,
      'lawyerName': lawyerName,
      'recommendedSpecialty': recommendedSpecialty,
      'closedAt': closedAt != null ? Timestamp.fromDate(closedAt!) : null,
    };
  }

  // Verificar si el chat está activo
  bool get isActive => status == 'active';

  // Verificar si el chat está cerrado
  bool get isClosed => status == 'closed';

  // Verificar si hay un abogado asignado
  bool get hasAssignedLawyer => hasLawyer && lawyerId != null;

  // Verificar si tiene una especialidad recomendada
  bool get hasRecommendation => recommendedSpecialty != null && recommendedSpecialty!.isNotEmpty;

  // Crear una copia del objeto con algunos campos actualizados
  LiveChat copyWith({
    String? status,
    bool? hasLawyer,
    String? lawyerId,
    String? lawyerName,
    String? recommendedSpecialty,
    DateTime? closedAt,
  }) {
    return LiveChat(
      id: this.id,
      userId: this.userId,
      userName: this.userName,
      createdAt: this.createdAt,
      status: status ?? this.status,
      hasLawyer: hasLawyer ?? this.hasLawyer,
      lawyerId: lawyerId ?? this.lawyerId,
      lawyerName: lawyerName ?? this.lawyerName,
      recommendedSpecialty: recommendedSpecialty ?? this.recommendedSpecialty,
      closedAt: closedAt ?? this.closedAt,
    );
  }
}

class ChatMessage {
  final String id;
  final String text;
  final String senderId;
  final String senderName;
  final bool isLawyer;
  final bool isRecommendation;
  final String? specialty;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.text,
    required this.senderId,
    required this.senderName,
    required this.isLawyer,
    this.isRecommendation = false,
    this.specialty,
    required this.timestamp,
  });

  // Convertir de Firebase a objeto ChatMessage
  factory ChatMessage.fromMap(Map<String, dynamic> data, String id) {
    return ChatMessage(
      id: id,
      text: data['text'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'Usuario',
      isLawyer: data['isLawyer'] ?? false,
      isRecommendation: data['isRecommendation'] ?? false,
      specialty: data['specialty'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  // Convertir objeto ChatMessage a mapa para Firebase
  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'senderId': senderId,
      'senderName': senderName,
      'isLawyer': isLawyer,
      'isRecommendation': isRecommendation,
      'specialty': specialty,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  // Crear un mensaje regular
  factory ChatMessage.createRegular({
    required String text,
    required String senderId,
    required String senderName,
    required bool isLawyer,
  }) {
    return ChatMessage(
      id: '', // ID temporal que se asignará por Firestore
      text: text,
      senderId: senderId,
      senderName: senderName,
      isLawyer: isLawyer,
      timestamp: DateTime.now(),
    );
  }

  // Crear un mensaje de recomendación
  factory ChatMessage.createRecommendation({
    required String senderId,
    required String senderName,
    required String specialty,
  }) {
    return ChatMessage(
      id: '', // ID temporal que se asignará por Firestore
      text: 'Basado en tu consulta, te recomiendo buscar un abogado especializado en $specialty',
      senderId: senderId,
      senderName: senderName,
      isLawyer: true,
      isRecommendation: true,
      specialty: specialty,
      timestamp: DateTime.now(),
    );
  }

  // Crear un mensaje de sistema
  factory ChatMessage.createSystem({
    required String text,
  }) {
    return ChatMessage(
      id: '', // ID temporal que se asignará por Firestore
      text: text,
      senderId: 'system',
      senderName: 'Sistema',
      isLawyer: false,
      timestamp: DateTime.now(),
    );
  }
}