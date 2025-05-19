class Lawyer {
  final String id;
  final String name;
  final List<String> specialties; // Cambiado de String a List<String>
  final String photoBase64;
  final double consultationPrice;
  final String email;
  final String description;
  final double rating;
  final int reviewCount;
  final String? phone;

  Lawyer({
    required this.id,
    required this.name,
    required this.specialties, // Cambiado de specialty a specialties
    required this.photoBase64,
    required this.consultationPrice,
    required this.email,
    this.description = '',
    this.rating = 0.0,
    this.reviewCount = 0,
    this.phone,
  });

  // Convertir de Firebase a objeto Lawyer
  factory Lawyer.fromMap(Map<String, dynamic> data, String id) {
    // Manejo de la conversión de specialty a specialties
    List<String> specialtiesList = [];
    if (data['specialties'] != null) {
      // Si ya es una lista, usarla directamente
      specialtiesList = List<String>.from(data['specialties']);
    } else if (data['specialty'] != null) {
      // Retrocompatibilidad: convertir el campo anterior 'specialty' en una lista
      specialtiesList = [data['specialty']];
    }

    return Lawyer(
      id: id,
      name: data['name'] ?? '',
      specialties: specialtiesList,
      photoBase64: data['photoBase64'] ?? '',
      consultationPrice: (data['consultationPrice'] ?? 0.0).toDouble(),
      email: data['email'] ?? '',
      description: data['description'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      phone: data['phone'],
    );
  }

  // Convertir objeto Lawyer a mapa para Firebase
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'specialties': specialties, // Ahora guarda una lista
      'photoBase64': photoBase64,
      'consultationPrice': consultationPrice,
      'email': email,
      'description': description,
      'rating': rating,
      'reviewCount': reviewCount,
      'phone': phone,
    };
  }
}