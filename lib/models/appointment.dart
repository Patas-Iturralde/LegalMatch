import 'package:cloud_firestore/cloud_firestore.dart';

class Appointment {
  final String id;
  final String lawyerId;
  final String lawyerName;
  final String clientId;
  final String clientName;
  final DateTime startTime;
  final DateTime endTime;
  final String status; // 'pending', 'confirmed', 'completed', 'cancelled'
  final String notes;
  final String title;

  Appointment({
    required this.id,
    required this.lawyerId,
    required this.lawyerName,
    required this.clientId,
    required this.clientName,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.notes,
    required this.title,
  });

  // Convertir desde Firestore
  factory Appointment.fromMap(Map<String, dynamic> data, String id) {
    return Appointment(
      id: id,
      lawyerId: data['lawyerId'] ?? '',
      lawyerName: data['lawyerName'] ?? '',
      clientId: data['clientId'] ?? '',
      clientName: data['clientName'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      status: data['status'] ?? 'pending',
      notes: data['notes'] ?? '',
      title: data['title'] ?? 'Consulta',
    );
  }

  // Convertir a mapa para Firestore
  Map<String, dynamic> toMap() {
    return {
      'lawyerId': lawyerId,
      'lawyerName': lawyerName,
      'clientId': clientId,
      'clientName': clientName,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'status': status,
      'notes': notes,
      'title': title,
    };
  }

  // Crear una copia de la cita con algunos campos actualizados
  Appointment copyWith({
    String? id,
    String? lawyerId,
    String? lawyerName,
    String? clientId,
    String? clientName,
    DateTime? startTime,
    DateTime? endTime,
    String? status,
    String? notes,
    String? title,
  }) {
    return Appointment(
      id: id ?? this.id,
      lawyerId: lawyerId ?? this.lawyerId,
      lawyerName: lawyerName ?? this.lawyerName,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      title: title ?? this.title,
    );
  }
}