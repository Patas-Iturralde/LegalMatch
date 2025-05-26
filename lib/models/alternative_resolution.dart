import 'package:cloud_firestore/cloud_firestore.dart';

enum ResolutionType { mediation, arbitration }

class AlternativeResolutionCase {
  final String id;
  final String clientId;
  final String clientName;
  final String lawyerId;
  final String lawyerName;
  final ResolutionType type;
  final String title;
  final String description;
  final String status; // 'pending', 'active', 'resolved', 'cancelled'
  final DateTime createdAt;
  final DateTime? scheduledAt;
  final DateTime? resolvedAt;
  final String? resolution;
  final double? amount; // Para arbitrajes con montos económicos
  final List<String> documents;
  final Map<String, dynamic> additionalData;

  AlternativeResolutionCase({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.lawyerId,
    required this.lawyerName,
    required this.type,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
    this.scheduledAt,
    this.resolvedAt,
    this.resolution,
    this.amount,
    this.documents = const [],
    this.additionalData = const {},
  });

  factory AlternativeResolutionCase.fromMap(Map<String, dynamic> data, String id) {
    return AlternativeResolutionCase(
      id: id,
      clientId: data['clientId'] ?? '',
      clientName: data['clientName'] ?? '',
      lawyerId: data['lawyerId'] ?? '',
      lawyerName: data['lawyerName'] ?? '',
      type: data['type'] == 'arbitration' ? ResolutionType.arbitration : ResolutionType.mediation,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      scheduledAt: data['scheduledAt'] != null 
          ? (data['scheduledAt'] as Timestamp).toDate() 
          : null,
      resolvedAt: data['resolvedAt'] != null 
          ? (data['resolvedAt'] as Timestamp).toDate() 
          : null,
      resolution: data['resolution'],
      amount: data['amount']?.toDouble(),
      documents: List<String>.from(data['documents'] ?? []),
      additionalData: Map<String, dynamic>.from(data['additionalData'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'clientName': clientName,
      'lawyerId': lawyerId,
      'lawyerName': lawyerName,
      'type': type == ResolutionType.arbitration ? 'arbitration' : 'mediation',
      'title': title,
      'description': description,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'scheduledAt': scheduledAt != null ? Timestamp.fromDate(scheduledAt!) : null,
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'resolution': resolution,
      'amount': amount,
      'documents': documents,
      'additionalData': additionalData,
    };
  }

  String get typeDisplayName {
    return type == ResolutionType.mediation ? 'Mediación' : 'Arbitraje';
  }

  String get typeDescription {
    return type == ResolutionType.mediation
        ? 'Proceso colaborativo donde un mediador neutral ayuda a las partes a encontrar una solución mutuamente aceptable.'
        : 'Proceso donde un árbitro imparcial toma una decisión vinculante después de escuchar a ambas partes.';
  }
}

class ResolutionMessage {
  final String id;
  final String caseId;
  final String senderId;
  final String senderName;
  final String senderType; // 'client', 'lawyer', 'system'
  final String message;
  final DateTime timestamp;
  final bool isSystemMessage;
  final String? attachmentUrl;
  final String? attachmentName;
  final MessageType messageType;

  ResolutionMessage({
    required this.id,
    required this.caseId,
    required this.senderId,
    required this.senderName,
    required this.senderType,
    required this.message,
    required this.timestamp,
    this.isSystemMessage = false,
    this.attachmentUrl,
    this.attachmentName,
    this.messageType = MessageType.text,
  });

  factory ResolutionMessage.fromMap(Map<String, dynamic> data, String id) {
    return ResolutionMessage(
      id: id,
      caseId: data['caseId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderType: data['senderType'] ?? '',
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isSystemMessage: data['isSystemMessage'] ?? false,
      attachmentUrl: data['attachmentUrl'],
      attachmentName: data['attachmentName'],
      messageType: MessageType.values.firstWhere(
        (e) => e.toString().split('.').last == (data['messageType'] ?? 'text'),
        orElse: () => MessageType.text,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'caseId': caseId,
      'senderId': senderId,
      'senderName': senderName,
      'senderType': senderType,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'isSystemMessage': isSystemMessage,
      'attachmentUrl': attachmentUrl,
      'attachmentName': attachmentName,
      'messageType': messageType.toString().split('.').last,
    };
  }
}

enum MessageType {
  text,
  document,
  proposal, // Para propuestas de acuerdo
  decision,  // Para decisiones de arbitraje
}

class Resolution {
  final String id;
  final String caseId;
  final String type; // 'agreement', 'award'
  final String content;
  final DateTime dateIssued;
  final bool isBinding;
  final double? amount;
  final Map<String, dynamic> terms;

  Resolution({
    required this.id,
    required this.caseId,
    required this.type,
    required this.content,
    required this.dateIssued,
    required this.isBinding,
    this.amount,
    this.terms = const {},
  });

  factory Resolution.fromMap(Map<String, dynamic> data, String id) {
    return Resolution(
      id: id,
      caseId: data['caseId'] ?? '',
      type: data['type'] ?? '',
      content: data['content'] ?? '',
      dateIssued: (data['dateIssued'] as Timestamp).toDate(),
      isBinding: data['isBinding'] ?? false,
      amount: data['amount']?.toDouble(),
      terms: Map<String, dynamic>.from(data['terms'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'caseId': caseId,
      'type': type,
      'content': content,
      'dateIssued': Timestamp.fromDate(dateIssued),
      'isBinding': isBinding,
      'amount': amount,
      'terms': terms,
    };
  }
}