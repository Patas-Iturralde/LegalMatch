import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String lawyerId;
  final String clientId;
  final String clientName;
  final String text;
  final double rating;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.lawyerId,
    required this.clientId,
    required this.clientName,
    required this.text,
    required this.rating,
    required this.createdAt,
  });

  // Convertir de Firebase a objeto Review
  factory Review.fromMap(Map<String, dynamic> data, String id) {
    return Review(
      id: id,
      lawyerId: data['lawyerId'] ?? '',
      clientId: data['clientId'] ?? '',
      clientName: data['clientName'] ?? '',
      text: data['text'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // Convertir objeto Review a mapa para Firebase
  Map<String, dynamic> toMap() {
    return {
      'lawyerId': lawyerId,
      'clientId': clientId,
      'clientName': clientName,
      'text': text,
      'rating': rating,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}