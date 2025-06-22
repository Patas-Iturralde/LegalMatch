class EcuadorCities {
  // Lista completa de ciudades principales del Ecuador organizadas por provincia
  static final Map<String, List<String>> _citiesByProvince = {
    'Azuay': [
      'Cuenca',
      'Gualaceo',
      'Paute',
      'Sígsig',
      'Girón',
      'Santa Isabel',
      'Nabón',
      'Oña',
      'Pucará',
      'San Fernando',
      'Sevilla de Oro',
      'Guachapala',
      'El Pan',
      'Chordeleg',
      'Camilo Ponce Enríquez'
    ],
    'Bolívar': [
      'Guaranda',
      'San Miguel',
      'Chillanes',
      'Chimbo',
      'Echeandía',
      'Las Naves',
      'Caluma'
    ],
    'Cañar': [
      'Azogues',
      'Cañar',
      'La Troncal',
      'Biblián',
      'Déleg',
      'Suscal',
      'El Tambo'
    ],
    'Carchi': [
      'Tulcán',
      'San Gabriel',
      'Huaca',
      'Montúfar',
      'Bolívar',
      'Espejo',
      'Mira'
    ],
    'Chimborazo': [
      'Riobamba',
      'Alausí',
      'Colta',
      'Chambo',
      'Chunchi',
      'Guamote',
      'Guano',
      'Pallatanga',
      'Penipe',
      'Cumandá'
    ],
    'Cotopaxi': [
      'Latacunga',
      'La Maná',
      'Pangua',
      'Pujilí',
      'Salcedo',
      'Saquisilí',
      'Sigchos'
    ],
    'El Oro': [
      'Machala',
      'Pasaje',
      'Santa Rosa',
      'Huaquillas',
      'Arenillas',
      'Atahualpa',
      'Balsas',
      'Chilla',
      'El Guabo',
      'Las Lajas',
      'Marcabelí',
      'Piñas',
      'Portovelo',
      'Zaruma'
    ],
    'Esmeraldas': [
      'Esmeraldas',
      'Atacames',
      'Eloy Alfaro',
      'Muisne',
      'Quinindé',
      'Rioverde',
      'San Lorenzo',
      'La Tola'
    ],
    'Galápagos': [
      'Puerto Baquerizo Moreno',
      'Puerto Ayora',
      'Puerto Villamil'
    ],
    'Guayas': [
      'Guayaquil',
      'Milagro',
      'Daule',
      'Durán',
      'Samborondón',
      'Playas',
      'Salinas',
      'La Libertad',
      'Santa Elena',
      'Babahoyo',
      'Quevedo',
      'Vinces',
      'Baba',
      'Balao',
      'Balzar',
      'Colimes',
      'El Empalme',
      'El Triunfo',
      'General Antonio Elizalde',
      'Isidro Ayora',
      'Lomas de Sargentillo',
      'Marcelino Maridueña',
      'Naranjal',
      'Naranjito',
      'Nobol',
      'Palestina',
      'Pedro Carbo',
      'Simón Bolívar',
      'Yaguachi'
    ],
    'Imbabura': [
      'Ibarra',
      'Otavalo',
      'Cotacachi',
      'Antonio Ante',
      'Atuntaqui',
      'Pimampiro',
      'San Miguel de Urcuquí'
    ],
    'Loja': [
      'Loja',
      'Catamayo',
      'Cariamanga',
      'Alamor',
      'Catacocha',
      'Celica',
      'Chaguarpamba',
      'Espíndola',
      'Gonzanamá',
      'Macará',
      'Paltas',
      'Pindal',
      'Puyango',
      'Quilanga',
      'Saraguro',
      'Sozoranga',
      'Zapotillo'
    ],
    'Los Ríos': [
      'Babahoyo',
      'Quevedo',
      'Vinces',
      'Ventanas',
      'Puebloviejo',
      'Urdaneta',
      'Baba',
      'Buena Fe',
      'Mocache',
      'Montalvo',
      'Palenque',
      'Valencia'
    ],
    'Manabí': [
      'Portoviejo',
      'Manta',
      'Chone',
      'El Carmen',
      'Pedernales',
      'Bahía de Caráquez',
      'Calceta',
      'Tosagua',
      'Rocafuerte',
      'Sucre',
      'Bolivar',
      'Flavio Alfaro',
      'Jama',
      'Jaramijó',
      'Junín',
      'Montecristi',
      'Olmedo',
      'Paján',
      'Pichincha',
      'Puerto López',
      'San Vicente',
      'Santa Ana',
      'Veinticuatro de Mayo'
    ],
    'Morona Santiago': [
      'Macas',
      'Gualaquiza',
      'Limón Indanza',
      'Palora',
      'Santiago',
      'Sucúa',
      'Huamboya',
      'San Juan Bosco',
      'Taisha',
      'Logroño',
      'Pablo Sexto',
      'Tiwintza'
    ],
    'Napo': [
      'Tena',
      'Archidona',
      'El Chaco',
      'Quijos',
      'Carlos Julio Arosemena Tola'
    ],
    'Orellana': [
      'Puerto Francisco de Orellana (El Coca)',
      'Joya de los Sachas',
      'Loreto',
      'Aguarico'
    ],
    'Pastaza': [
      'Puyo',
      'Mera',
      'Santa Clara',
      'Arajuno'
    ],
    'Pichincha': [
      'Quito',
      'Cayambe',
      'Mejía',
      'Pedro Moncayo',
      'Rumiñahui',
      'San Miguel de los Bancos',
      'Pedro Vicente Maldonado',
      'Puerto Quito'
    ],
    'Santa Elena': [
      'Santa Elena',
      'La Libertad',
      'Salinas'
    ],
    'Santo Domingo de los Tsáchilas': [
      'Santo Domingo'
    ],
    'Sucumbíos': [
      'Nueva Loja (Lago Agrio)',
      'Gonzalo Pizarro',
      'Putumayo',
      'Shushufindi',
      'Sucumbíos',
      'Cascales',
      'Cuyabeno'
    ],
    'Tungurahua': [
      'Ambato',
      'Baños de Agua Santa',
      'Cevallos',
      'Mocha',
      'Patate',
      'Quero',
      'San Pedro de Pelileo',
      'Santiago de Píllaro',
      'Tisaleo'
    ],
    'Zamora Chinchipe': [
      'Zamora',
      'Gualaquiza',
      'El Pangui',
      'Yantzaza',
      'Yacuambi',
      'Palanda',
      'Paquisha',
      'Centinela del Cóndor',
      'Nangaritza'
    ]
  };

  // Obtener todas las ciudades en una lista plana
  static List<String> getAllCities() {
    List<String> allCities = [];
    _citiesByProvince.values.forEach((cities) {
      allCities.addAll(cities);
    });
    // Ordenar alfabéticamente
    allCities.sort();
    return allCities;
  }

  // Obtener ciudades por provincia
  static List<String> getCitiesByProvince(String province) {
    return _citiesByProvince[province] ?? [];
  }

  // Obtener todas las provincias
  static List<String> getAllProvinces() {
    List<String> provinces = _citiesByProvince.keys.toList();
    provinces.sort();
    return provinces;
  }

  // Buscar ciudades que contengan un texto específico
  static List<String> searchCities(String query) {
    if (query.isEmpty) return getAllCities();
    
    String lowerQuery = query.toLowerCase();
    return getAllCities()
        .where((city) => city.toLowerCase().contains(lowerQuery))
        .toList();
  }

  // Verificar si una ciudad existe
  static bool cityExists(String cityName) {
    return getAllCities().contains(cityName);
  }

  // Obtener provincia de una ciudad
  static String? getProvinceOfCity(String cityName) {
    for (String province in _citiesByProvince.keys) {
      if (_citiesByProvince[province]!.contains(cityName)) {
        return province;
      }
    }
    return null;
  }

  // Ciudades más importantes (capitales provinciales y ciudades grandes)
  static List<String> getMajorCities() {
    return [
      'Quito',
      'Guayaquil',
      'Cuenca',
      'Santo Domingo',
      'Ambato',
      'Portoviejo',
      'Durán',
      'Manta',
      'Riobamba',
      'Loja',
      'Ibarra',
      'Esmeraldas',
      'Milagro',
      'Machala',
      'Latacunga',
      'Tena',
      'Puyo',
      'Macas',
      'Nueva Loja (Lago Agrio)',
      'Tulcán',
      'Babahoyo',
      'Azogues',
      'Guaranda',
      'Zamora'
    ];
  }
}