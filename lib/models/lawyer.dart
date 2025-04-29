class Lawyer {
  final String id;
  final String name;
  final String specialty;
  final String photoBase64;
  final double consultationPrice;
  final String email;
  final String description;
  final double rating;
  final int reviewCount;
  final String? phone; // Nuevo campo para almacenar el número de teléfono

  Lawyer({
    required this.id,
    required this.name,
    required this.specialty,
    required this.photoBase64,
    required this.consultationPrice,
    required this.email,
    this.description = '',
    this.rating = 0.0,
    this.reviewCount = 0,
    this.phone, // Parámetro opcional para el teléfono
  });

  // Convertir de Firebase a objeto Lawyer
  factory Lawyer.fromMap(Map<String, dynamic> data, String id) {
    return Lawyer(
      id: id,
      name: data['name'] ?? '',
      specialty: data['specialty'] ?? '',
      photoBase64: data['photoBase64'] ?? '',
      consultationPrice: (data['consultationPrice'] ?? 0.0).toDouble(),
      email: data['email'] ?? '',
      description: data['description'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      phone: data['phone'], // Obtener el teléfono del mapa de datos
    );
  }

  // Convertir objeto Lawyer a mapa para Firebase
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'specialty': specialty,
      'photoBase64': photoBase64,
      'consultationPrice': consultationPrice,
      'email': email,
      'description': description,
      'rating': rating,
      'reviewCount': reviewCount,
      'phone': phone, // Incluir el teléfono en el mapa
    };
  }
}