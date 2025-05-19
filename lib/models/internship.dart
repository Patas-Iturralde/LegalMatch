import 'package:cloud_firestore/cloud_firestore.dart';

class Internship {
  final String id;
  final String lawyerId;
  final String lawyerName;
  final String title;
  final String description;
  final String requirements;
  final DateTime createdAt;
  final bool isActive;

  Internship({
    required this.id,
    required this.lawyerId,
    required this.lawyerName,
    required this.title,
    required this.description,
    required this.requirements,
    required this.createdAt,
    required this.isActive,
  });

  // Convertir desde Firestore
  factory Internship.fromMap(Map<String, dynamic> data, String id) {
    return Internship(
      id: id,
      lawyerId: data['lawyerId'] ?? '',
      lawyerName: data['lawyerName'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      requirements: data['requirements'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
    );
  }

  // Convertir a mapa para Firestore
  Map<String, dynamic> toMap() {
    return {
      'lawyerId': lawyerId,
      'lawyerName': lawyerName,
      'title': title,
      'description': description,
      'requirements': requirements,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }
}

class InternshipApplication {
  final String id;
  final String internshipId;
  final String clientId;
  final String clientName;
  final String clientEmail;
  final DateTime appliedAt;
  final String status; // 'pending', 'accepted', 'rejected'

  InternshipApplication({
    required this.id,
    required this.internshipId,
    required this.clientId,
    required this.clientName,
    required this.clientEmail,
    required this.appliedAt,
    required this.status,
  });

  // Convertir desde Firestore
  factory InternshipApplication.fromMap(Map<String, dynamic> data, String id) {
    return InternshipApplication(
      id: id,
      internshipId: data['internshipId'] ?? '',
      clientId: data['clientId'] ?? '',
      clientName: data['clientName'] ?? '',
      clientEmail: data['clientEmail'] ?? '',
      appliedAt: (data['appliedAt'] as Timestamp).toDate(),
      status: data['status'] ?? 'pending',
    );
  }

  // Convertir a mapa para Firestore
  Map<String, dynamic> toMap() {
    return {
      'internshipId': internshipId,
      'clientId': clientId,
      'clientName': clientName,
      'clientEmail': clientEmail,
      'appliedAt': Timestamp.fromDate(appliedAt),
      'status': status,
    };
  }
}