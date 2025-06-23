class Lawyer {
  final String id;
  final String name;
  final List<String> specialties;
  final String photoBase64;
  final double consultationPrice;
  final String email;
  final String description;
  final double rating;
  final int reviewCount;
  final String? phone;
  final String city; // Nuevo campo para la ciudad

  Lawyer({
    required this.id,
    required this.name,
    required this.specialties,
    required this.photoBase64,
    required this.consultationPrice,
    required this.email,
    required this.city, // Campo obligatorio
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
      try {
        specialtiesList = List<String>.from(data['specialties']);
      } catch (e) {
        print('Error procesando especialidades para $id: $e');
        specialtiesList = [];
      }
    } else if (data['specialty'] != null) {
      // Retrocompatibilidad: convertir el campo anterior 'specialty' en una lista
      specialtiesList = [data['specialty'].toString()];
    }

    // Validar y limpiar la ciudad
    String city = 'Quito'; // Valor por defecto
    if (data['city'] != null && data['city'] is String && data['city'].toString().trim().isNotEmpty) {
      city = data['city'].toString().trim();
    }

    // Validar y convertir valores numéricos
    double consultationPrice = 0.0;
    if (data['consultationPrice'] != null) {
      try {
        consultationPrice = (data['consultationPrice'] as num).toDouble();
      } catch (e) {
        print('Error procesando precio para $id: $e');
        consultationPrice = 0.0;
      }
    }

    double rating = 0.0;
    if (data['rating'] != null) {
      try {
        rating = (data['rating'] as num).toDouble();
      } catch (e) {
        print('Error procesando rating para $id: $e');
        rating = 0.0;
      }
    }

    int reviewCount = 0;
    if (data['reviewCount'] != null) {
      try {
        reviewCount = (data['reviewCount'] as num).toInt();
      } catch (e) {
        print('Error procesando reviewCount para $id: $e');
        reviewCount = 0;
      }
    }

    return Lawyer(
      id: id,
      name: data['name']?.toString() ?? '',
      specialties: specialtiesList,
      photoBase64: data['photoBase64']?.toString() ?? '',
      consultationPrice: consultationPrice,
      email: data['email']?.toString() ?? '',
      city: city,
      description: data['description']?.toString() ?? '',
      rating: rating,
      reviewCount: reviewCount,
      phone: data['phone']?.toString(),
    );
  }

  // Convertir objeto Lawyer a mapa para Firebase
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'specialties': specialties,
      'photoBase64': photoBase64,
      'consultationPrice': consultationPrice,
      'email': email,
      'city': city, // Incluir la ciudad en el mapa
      'description': description,
      'rating': rating,
      'reviewCount': reviewCount,
      'phone': phone,
    };
  }
}