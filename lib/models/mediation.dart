import 'package:cloud_firestore/cloud_firestore.dart';

class MediationCase {
  final String id;
  final String clientId;
  final String clientName;
  final String lawyerId;
  final String lawyerName;
  final String title;
  final String description;
  final String status; // 'pending', 'active', 'resolved', 'cancelled'
  final DateTime createdAt;
  final DateTime? scheduledAt;
  final DateTime? resolvedAt;
  final String? resolution;
  final List<String> documents;

  MediationCase({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.lawyerId,
    required this.lawyerName,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
    this.scheduledAt,
    this.resolvedAt,
    this.resolution,
    this.documents = const [],
  });

  factory MediationCase.fromMap(Map<String, dynamic> data, String id) {
    return MediationCase(
      id: id,
      clientId: data['clientId'] ?? '',
      clientName: data['clientName'] ?? '',
      lawyerId: data['lawyerId'] ?? '',
      lawyerName: data['lawyerName'] ?? '',
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
      documents: List<String>.from(data['documents'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'clientName': clientName,
      'lawyerId': lawyerId,
      'lawyerName': lawyerName,
      'title': title,
      'description': description,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'scheduledAt': scheduledAt != null ? Timestamp.fromDate(scheduledAt!) : null,
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'resolution': resolution,
      'documents': documents,
    };
  }
}

class MediationMessage {
  final String id;
  final String caseId;
  final String senderId;
  final String senderName;
  final String senderType; // 'client', 'lawyer', 'system'
  final String message;
  final DateTime timestamp;
  final bool isSystemMessage;

  MediationMessage({
    required this.id,
    required this.caseId,
    required this.senderId,
    required this.senderName,
    required this.senderType,
    required this.message,
    required this.timestamp,
    this.isSystemMessage = false,
  });

  factory MediationMessage.fromMap(Map<String, dynamic> data, String id) {
    return MediationMessage(
      id: id,
      caseId: data['caseId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderType: data['senderType'] ?? '',
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isSystemMessage: data['isSystemMessage'] ?? false,
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
    };
  }
}