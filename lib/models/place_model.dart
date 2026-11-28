/// Lugares reales del área metropolitana de Bucaramanga.
/// Datos tomados del archivo lugares_explora_bga (coordenadas aportadas por el
/// autor desde Google Maps y fuentes oficiales).
///
/// Sprint 2: la lista [allPlaces] es la "semilla". Al abrir la app se sube a la
/// colección `places` de Firestore y desde ahí se leen los lugares
/// (ver FirestoreService.syncPlaces y AppState.loadPlaces).
/// Si se cambia un dato en esta lista, hay que subir [dataVersion] en 1 para que
/// la app actualice Firestore.
class PlaceModel {
  /// Versión de los datos de [allPlaces]. Subirla en 1 cada vez que se edite la lista.
  static const int dataVersion = 1;

  final String id;
  final String name;
  final String category;
  final String categoryIcon;
  final String description;
  final double lat;
  final double lng;
  final int? priceCop;     // precio por persona en COP; null = sin dato
  final String address;
  final String? hours;     // horario tal como se verificó; null = sin dato
  final String? phone;
  final List<String> tags;
  /// Calificación promedio calculada con las reseñas reales de los usuarios
  /// (0.0 = sin calificar). Viene de los campos ratingSum / ratingCount de Firestore.
  final double rating;
  /// Cantidad de reseñas del lugar.
  final int ratingCount;

  const PlaceModel({
    required this.id,
    required this.name,
    required this.category,
    required this.categoryIcon,
    required this.description,
    required this.lat,
    required this.lng,
    this.priceCop,
    required this.address,
    this.hours,
    this.phone,
    this.tags = const [],
    this.rating = 0.0,
    this.ratingCount = 0,
  });

  /// Copia del lugar con otra calificación (se usa al guardar una reseña).
  PlaceModel copyWithRating(double newRating, int newCount) => PlaceModel(
        id: id, name: name, category: category, categoryIcon: categoryIcon,
        description: description, lat: lat, lng: lng, priceCop: priceCop,
        address: address, hours: hours, phone: phone, tags: tags,
        rating: newRating, ratingCount: newCount,
      );

  /// Datos que se guardan en Firestore (colección `places`).
  /// La calificación NO va aquí: la manejan las reseñas (ratingSum / ratingCount).
  Map<String, dynamic> toMap() => {
        'name': name,
        'category': category,
        'categoryIcon': categoryIcon,
        'description': description,
        'lat': lat,
        'lng': lng,
        'priceCop': priceCop,
        'address': address,
        'hours': hours,
        'phone': phone,
        'tags': tags,
      };

  /// Construye un lugar a partir de un documento de Firestore.
  factory PlaceModel.fromMap(String id, Map<String, dynamic> m) {
    final count = (m['ratingCount'] as num?)?.toInt() ?? 0;
    final sum   = (m['ratingSum'] as num?)?.toDouble() ?? 0;
    return PlaceModel(
      id: id,
      name: m['name'] as String? ?? '',
      category: m['category'] as String? ?? '',
      categoryIcon: m['categoryIcon'] as String? ?? '📍',
      description: m['description'] as String? ?? '',
      lat: (m['lat'] as num).toDouble(),
      lng: (m['lng'] as num).toDouble(),
      priceCop: (m['priceCop'] as num?)?.toInt(),
      address: m['address'] as String? ?? '',
      hours: m['hours'] as String?,
      phone: m['phone'] as String?,
      tags: (m['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      rating: count > 0 ? sum / count : 0.0,
      ratingCount: count,
    );
  }

  /// Texto de la calificación, por ejemplo "4.5 (3 reseñas)"; vacío si no tiene.
  String get ratingLabel {
    if (ratingCount == 0) return '';
    return '${rating.toStringAsFixed(1)} ($ratingCount ${ratingCount == 1 ? 'reseña' : 'reseñas'})';
  }

  /// Rango de precio derivado del valor en COP.
  String get priceRange {
    final p = priceCop;
    if (p == null) return 'Sin dato';
    if (p == 0) return 'Gratis';
    if (p <= 20000) return 'Hasta \$20.000';
    if (p <= 50000) return '\$20.001 a \$50.000';
    return 'Más de \$50.000';
  }

  static const List<String> priceFilters = [
    'Todos',
    'Gratis',
    'Hasta \$20.000',
    '\$20.001 a \$50.000',
    'Más de \$50.000',
  ];

  static const List<String> categories = [
    'Todos',
    'Parques',
    'Centros comerciales',
    'Restaurantes',
    'Cultura',
  ];

  static const Map<String, String> categoryIcons = {
    'Todos': '🗺️',
    'Parques': '🌳',
    'Centros comerciales': '🛍️',
    'Restaurantes': '🍽️',
    'Cultura': '🏛️',
  };

  static const List<PlaceModel> allPlaces = [
    PlaceModel(
      id: 'L01',
      name: 'Parque Santander',
      category: 'Parques',
      categoryIcon: '🌳',
      description: 'Parque en Bucaramanga. Calle 35 con Carrera 19, centro.',
      lat: 7.1193,
      lng: -73.1228,
      priceCop: 0,
      address: 'Calle 35 con Carrera 19, centro',
      hours: 'Espacio público abierto, sin horario fijo (confirmar)',
    ),
    PlaceModel(
      id: 'L02',
      name: 'Parque García Rovira',
      category: 'Parques',
      categoryIcon: '🌳',
      description: 'Parque en Bucaramanga. Centro histórico (Capilla de los Dolores, Iglesia San Laureano).',
      lat: 7.1226,
      lng: -73.1248,
      priceCop: 0,
      address: 'Centro histórico (Capilla de los Dolores, Iglesia San Laureano)',
      hours: 'Espacio público abierto, sin horario fijo (confirmar)',
    ),
    PlaceModel(
      id: 'L03',
      name: 'Parque San Pío',
      category: 'Parques',
      categoryIcon: '🌳',
      description: 'Parque en Bucaramanga. Cra. 33 #45, Cabecera del Llano.',
      lat: 7.118581,
      lng: -73.11071,
      priceCop: 0,
      address: 'Cra. 33 #45, Cabecera del Llano',
      hours: 'Espacio público abierto, sin horario fijo (confirmar)',
    ),
    PlaceModel(
      id: 'L04',
      name: 'Parque de los Niños',
      category: 'Parques',
      categoryIcon: '🌳',
      description: 'Parque en Bucaramanga. Calle 31 #26, barrio Antonia Santos Centro.',
      lat: 7.1251872,
      lng: -73.11902999,
      priceCop: 0,
      address: 'Calle 31 #26, barrio Antonia Santos Centro',
      hours: 'Espacio público abierto, sin horario fijo (confirmar)',
    ),
    PlaceModel(
      id: 'L06',
      name: 'Parque Centenario',
      category: 'Parques',
      categoryIcon: '🌳',
      description: 'Parque en Bucaramanga. Entre calle 33 y carrera 18.',
      lat: 7.118,
      lng: -73.124,
      priceCop: 0,
      address: 'Entre calle 33 y carrera 18',
      hours: 'Espacio público abierto, sin horario fijo (confirmar)',
    ),
    PlaceModel(
      id: 'L07',
      name: 'Parque Antonia Santos',
      category: 'Parques',
      categoryIcon: '🌳',
      description: 'Parque en Bucaramanga. Carrera 22 #31, barrio Antonia Santos Centro.',
      lat: 7.12271,
      lng: -73.12223,
      priceCop: 0,
      address: 'Carrera 22 #31, barrio Antonia Santos Centro',
      hours: 'Espacio público abierto, sin horario fijo (confirmar)',
    ),
    PlaceModel(
      id: 'L08',
      name: 'Parque de las Palmas',
      category: 'Parques',
      categoryIcon: '🌳',
      description: 'Parque en Bucaramanga. Carrera 29 #44-14, barrio Sotomayor.',
      lat: 7.11952,
      lng: -73.11252,
      priceCop: 0,
      address: 'Carrera 29 #44-14, barrio Sotomayor',
      hours: 'Espacio público abierto, sin horario fijo (confirmar)',
    ),
    PlaceModel(
      id: 'L09',
      name: 'Parque Ecológico La Flora',
      category: 'Parques',
      categoryIcon: '🌳',
      description: 'Parque en Bucaramanga. Entrada por sector de la Cra. 36; otra referencia cerca de Cra. 44 #57.',
      lat: 7.1054333,
      lng: -73.10808793,
      priceCop: 0,
      address: 'Entrada por sector de la Cra. 36; otra referencia cerca de Cra. 44 #57',
      hours: '05:00–17:00 (provisional, ficha cartográfica)',
    ),
    PlaceModel(
      id: 'L10',
      name: 'Parque Morrorico',
      category: 'Parques',
      categoryIcon: '🌳',
      description: 'Parque en Bucaramanga. Autopista Morrorico y sector de la carrera 50.',
      lat: 7.13456259,
      lng: -73.10684686,
      priceCop: 0,
      address: 'Autopista Morrorico y sector de la carrera 50',
      hours: '05:00–21:00 (provisional, ficha cartográfica)',
    ),
    PlaceModel(
      id: 'L11',
      name: 'Parque Bosques de Lagos del Cacique',
      category: 'Parques',
      categoryIcon: '🌳',
      description: 'Parque en Bucaramanga. Sector Cacique (confirmar dirección).',
      lat: 7.103988,
      lng: -73.103097,
      priceCop: 0,
      address: 'Sector Cacique (confirmar dirección)',
      hours: null,
    ),
    PlaceModel(
      id: 'L13',
      name: 'Centro Comercial Cacique',
      category: 'Centros comerciales',
      categoryIcon: '🛍️',
      description: 'Centro comercial en Bucaramanga. Transversal 93 #34-99, sector El Tejar.',
      lat: 7.099302,
      lng: -73.107431,
      priceCop: 0,
      address: 'Transversal 93 #34-99, sector El Tejar',
      hours: '08:00–21:00 (provisional; algunos locales cierran antes lun–jue y dom/festivos pueden variar)',
    ),
    PlaceModel(
      id: 'L14',
      name: 'Centro Comercial Parque Caracolí',
      category: 'Centros comerciales',
      categoryIcon: '🛍️',
      description: 'Centro comercial en Floridablanca. Carrera 27 #29-145, Cañaveral.',
      lat: 7.071674,
      lng: -73.105291,
      priceCop: 0,
      address: 'Carrera 27 #29-145, Cañaveral',
      hours: 'Dom–jue 10:00–20:00; vie y sáb 10:00–21:00',
    ),
    PlaceModel(
      id: 'L15',
      name: 'Centro Comercial Cañaveral',
      category: 'Centros comerciales',
      categoryIcon: '🛍️',
      description: 'Centro comercial en Floridablanca. Calle 30 #25-71.',
      lat: 7.0715,
      lng: -73.106833,
      priceCop: 0,
      address: 'Calle 30 #25-71',
      hours: 'Lun–dom 06:00–00:00',
    ),
    PlaceModel(
      id: 'L16',
      name: 'Centro Comercial Megamall',
      category: 'Centros comerciales',
      categoryIcon: '🛍️',
      description: 'Centro comercial en Bucaramanga. Carrera 33 #29-15.',
      lat: 7.130556,
      lng: -73.112528,
      priceCop: 0,
      address: 'Carrera 33 #29-15',
      hours: '08:00–22:00 (publicado para el Centro de Soluciones; confirmar para todo el centro comercial)',
    ),
    PlaceModel(
      id: 'L17',
      name: 'Centro Comercial Acrópolis',
      category: 'Centros comerciales',
      categoryIcon: '🛍️',
      description: 'Centro comercial en Bucaramanga. Avenida Samanes #9-140.',
      lat: 7.104438,
      lng: -73.122782,
      priceCop: 0,
      address: 'Avenida Samanes #9-140',
      hours: 'Lun–dom 09:00–21:00',
    ),
    PlaceModel(
      id: 'L19',
      name: 'Castillo Burger',
      category: 'Restaurantes',
      categoryIcon: '🍽️',
      description: 'Restaurante en Bucaramanga.',
      lat: 7.108704,
      lng: -73.116834,
      priceCop: null,
      address: 'Bucaramanga',
      hours: null,
    ),
    PlaceModel(
      id: 'L20',
      name: 'Toro McCoy',
      category: 'Restaurantes',
      categoryIcon: '🍽️',
      description: 'Restaurante en Bucaramanga.',
      lat: 7.115645,
      lng: -73.111855,
      priceCop: null,
      address: 'Bucaramanga',
      hours: null,
    ),
    PlaceModel(
      id: 'L21',
      name: 'Snob Premium Donuts (Cabecera)',
      category: 'Restaurantes',
      categoryIcon: '🍽️',
      description: 'Restaurante en Bucaramanga. Calle 54A #35A-33, Cabecera.',
      lat: 7.111384,
      lng: -73.108076,
      priceCop: null,
      address: 'Calle 54A #35A-33, Cabecera',
      hours: '07:30–20:30 (provisional)',
    ),
    PlaceModel(
      id: 'L22',
      name: 'Moufflet Pastelería (Sotomayor)',
      category: 'Restaurantes',
      categoryIcon: '🍽️',
      description: 'Restaurante en Bucaramanga. Carrera 23 #51-77, Nuevo Sotomayor.',
      lat: 7.112584,
      lng: -73.11627,
      priceCop: null,
      address: 'Carrera 23 #51-77, Nuevo Sotomayor',
      hours: 'Aprox. 10:00–19:00 (provisional)',
    ),
    PlaceModel(
      id: 'L23',
      name: 'Luigi Jr',
      category: 'Restaurantes',
      categoryIcon: '🍽️',
      description: 'Restaurante en Bucaramanga. Avenida Búcaros Oeste #3-113, local 21, Real de Minas.',
      lat: 7.104023,
      lng: -73.127583,
      priceCop: 30000,
      address: 'Avenida Búcaros Oeste #3-113, local 21, Real de Minas',
      hours: 'Lun–jue 16:00–23:59; vie–dom 12:00–23:59 (provisional)',
    ),
    PlaceModel(
      id: 'L24',
      name: 'Catedral de la Sagrada Familia',
      category: 'Cultura',
      categoryIcon: '🏛️',
      description: 'Sitio cultural en Bucaramanga. Frente al Parque Santander.',
      lat: 7.1192,
      lng: -73.1231,
      priceCop: 0,
      address: 'Frente al Parque Santander',
      hours: 'Lun–sáb 06:00–18:00; dom 07:00–18:00 (provisional, Wanderlog)',
    ),
    PlaceModel(
      id: 'L25',
      name: 'Museo Casa de Bolívar',
      category: 'Cultura',
      categoryIcon: '🏛️',
      description: 'Sitio cultural en Bucaramanga. Calle 37 #12-15, barrio García Rovira.',
      lat: 7.1235,
      lng: -73.1245,
      priceCop: null,
      address: 'Calle 37 #12-15, barrio García Rovira',
      hours: 'IMCT: lun–vie 08:00–12:00 y 15:00–18:00; sáb 08:00–12:00 (otras fuentes difieren)',
    ),
    PlaceModel(
      id: 'L27',
      name: 'Capilla de los Dolores',
      category: 'Cultura',
      categoryIcon: '🏛️',
      description: 'Sitio cultural en Bucaramanga. Dentro del Parque García Rovira.',
      lat: 7.1228,
      lng: -73.125,
      priceCop: 0,
      address: 'Dentro del Parque García Rovira',
      hours: 'Por confirmar (horario de misas / visita)',
    ),
    PlaceModel(
      id: 'L28',
      name: 'Iglesia de San Laureano',
      category: 'Cultura',
      categoryIcon: '🏛️',
      description: 'Sitio cultural en Bucaramanga. Costado oriental del Parque García Rovira.',
      lat: 7.1226,
      lng: -73.1244,
      priceCop: 0,
      address: 'Costado oriental del Parque García Rovira',
      hours: 'Por confirmar (horario de misas / visita)',
    ),
  ];
}
