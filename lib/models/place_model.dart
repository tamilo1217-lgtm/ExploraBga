class PlaceModel {
  final String id;
  final String name;
  final String category;
  final String categoryIcon;
  final String description;
  final double lat;
  final double lng;
  final double rating;
  final String priceRange; // '$', '$$', '$$$', 'Gratis'
  final String address;
  final String? phone;
  final List<String> tags;

  const PlaceModel({
    required this.id,
    required this.name,
    required this.category,
    required this.categoryIcon,
    required this.description,
    required this.lat,
    required this.lng,
    required this.rating,
    required this.priceRange,
    required this.address,
    this.phone,
    this.tags = const [],
  });

  // ── All real Bucaramanga places ─────────────────────────

  static const List<PlaceModel> allPlaces = [
    // ─── RESTAURANTES ───────────────────────────────────
    PlaceModel(
      id: 'r1',
      name: 'Mercado del Río',
      category: 'Restaurantes',
      categoryIcon: '🍽️',
      description:
          'Mercado gastronómico con los mejores sabores de Colombia. Food trucks, restaurantes de autor y coctelería artesanal en un ambiente industrial renovado.',
      lat: 7.1078,
      lng: -73.1071,
      rating: 4.6,
      priceRange: '\$\$',
      address: 'Cra. 33 #48-40, Bucaramanga',
      tags: ['comida', 'gastronomía', 'mercado', 'cócteles'],
    ),
    PlaceModel(
      id: 'r2',
      name: 'La Puerta del Sol',
      category: 'Restaurantes',
      categoryIcon: '🍖',
      description:
          'Restaurante tradicional santandereano, famoso por mute, pepitoria y cabro al pastor. Lugar icónico con más de 40 años de tradición bumanguesa.',
      lat: 7.1156,
      lng: -73.1120,
      rating: 4.4,
      priceRange: '\$\$',
      address: 'Cra. 27 #42-15, Bucaramanga',
      tags: ['comida típica', 'santandereana', 'tradicional'],
    ),
    PlaceModel(
      id: 'r3',
      name: 'Crepes & Waffles Cabecera',
      category: 'Restaurantes',
      categoryIcon: '🧇',
      description:
          'Cadena colombiana con crepes dulces y salados, helados artesanales y una amplia carta de postres. Ambiente familiar y acogedor.',
      lat: 7.0912,
      lng: -73.1097,
      rating: 4.3,
      priceRange: '\$\$',
      address: 'Cll. 48 #28-60, Cabecera, Bucaramanga',
      tags: ['postres', 'crepes', 'casual'],
    ),
    PlaceModel(
      id: 'r4',
      name: 'Restaurante Verdeo',
      category: 'Restaurantes',
      categoryIcon: '🥗',
      description:
          'Cocina contemporánea con ingredientes locales y menú de autor. El favorito de Zona Rosa, con terraza y maridaje de vinos colombianos.',
      lat: 7.0878,
      lng: -73.1085,
      rating: 4.7,
      priceRange: '\$\$\$',
      address: 'Zona Rosa, Bucaramanga',
      tags: ['gourmet', 'moderno', 'zona rosa'],
    ),
    PlaceModel(
      id: 'r5',
      name: 'El Viejo Chiflas',
      category: 'Restaurantes',
      categoryIcon: '🌮',
      description:
          'Referente de la cocina bumanguesa cerca de la Cascada de Chiflas. Especialidad en trucha criolla, arepas y hormigas culonas.',
      lat: 7.1341,
      lng: -73.1045,
      rating: 4.2,
      priceRange: '\$',
      address: 'Sector Chiflas, Bucaramanga',
      tags: ['trucha', 'típico', 'familiar'],
    ),

    // ─── PARQUES ─────────────────────────────────────────
    PlaceModel(
      id: 'p1',
      name: 'Parque García Rovira',
      category: 'Parques',
      categoryIcon: '🌳',
      description:
          'El parque más histórico de Bucaramanga, corazón del centro colonial. Rodeado de arquitectura republicana, árboles centenarios y buganvilias.',
      lat: 7.1253,
      lng: -73.1198,
      rating: 4.2,
      priceRange: 'Gratis',
      address: 'Centro Histórico, Bucaramanga',
      tags: ['historia', 'colonial', 'centro'],
    ),
    PlaceModel(
      id: 'p2',
      name: 'Parque Santander',
      category: 'Parques',
      categoryIcon: '🌿',
      description:
          'Parque central de la ciudad. Punto de encuentro con fuentes ornamentales, vendedores de hormigas culonas y vida nocturna animada.',
      lat: 7.1198,
      lng: -73.1188,
      rating: 4.1,
      priceRange: 'Gratis',
      address: 'Cll. 35 con Cra. 19, Bucaramanga',
      tags: ['descanso', 'central', 'familia'],
    ),
    PlaceModel(
      id: 'p3',
      name: 'Jardín Botánico de Bucaramanga',
      category: 'Parques',
      categoryIcon: '🌺',
      description:
          'Reserva natural urbana con más de 800 especies de plantas, mariposario, senderos ecológicos y talleres de educación ambiental.',
      lat: 7.1339,
      lng: -73.1167,
      rating: 4.5,
      priceRange: '\$',
      address: 'Cll. 56 #24-53, Bucaramanga',
      phone: '+57 7 6345678',
      tags: ['naturaleza', 'ecología', 'mariposas', 'senderos'],
    ),
    PlaceModel(
      id: 'p4',
      name: 'Parque Bicentenario',
      category: 'Parques',
      categoryIcon: '🎡',
      description:
          'Moderno parque lineal con ciclovía, zona infantil, canchas deportivas, skatepark y espacios para picnic. El pulmón verde del sur.',
      lat: 7.0981,
      lng: -73.1054,
      rating: 4.3,
      priceRange: 'Gratis',
      address: 'Av. Quebrada Seca, Bucaramanga',
      tags: ['deporte', 'familia', 'ciclovía', 'skate'],
    ),
    PlaceModel(
      id: 'p5',
      name: 'Parque de la Flora',
      category: 'Parques',
      categoryIcon: '🌸',
      description:
          'Espacio verde con variedad de flora local, ideal para caminatas matutinas y fotografía de naturaleza en medio de la ciudad.',
      lat: 7.1120,
      lng: -73.1070,
      rating: 4.0,
      priceRange: 'Gratis',
      address: 'Cll. 45 con Cra. 26, Bucaramanga',
      tags: ['flora', 'caminata', 'fotografía'],
    ),

    // ─── CINES ───────────────────────────────────────────
    PlaceModel(
      id: 'c1',
      name: 'Cine Colombia Cacique',
      category: 'Cines',
      categoryIcon: '🎬',
      description:
          'Complejo de cines dentro del CC Cacique con tecnología Dolby Atmos, sala VIP con servicio a la silla y la mejor cartelera nacional e internacional.',
      lat: 7.1012,
      lng: -73.1052,
      rating: 4.4,
      priceRange: '\$\$',
      address: 'CC Cacique, Av. González Valencia, Bucaramanga',
      phone: '+57 601 4444444',
      tags: ['películas', 'Dolby', 'VIP', 'entretenimiento'],
    ),
    PlaceModel(
      id: 'c2',
      name: 'Cinemark Cabecera',
      category: 'Cines',
      categoryIcon: '🎥',
      description:
          'Salas con experiencia XD y pantalla gigante. Zona de snacks premium y programación especial de películas de arte y madrugadores.',
      lat: 7.0905,
      lng: -73.1100,
      rating: 4.3,
      priceRange: '\$\$',
      address: 'CC La Florida, Cabecera, Bucaramanga',
      tags: ['películas', 'XD', 'entretenimiento'],
    ),
    PlaceModel(
      id: 'c3',
      name: 'Royal Films Alarife',
      category: 'Cines',
      categoryIcon: '🎦',
      description:
          'Cine con precios accesibles y amplia programación. Ideal para ir en familia sin gastar mucho, con buena calidad de imagen y sonido.',
      lat: 7.1099,
      lng: -73.1135,
      rating: 4.0,
      priceRange: '\$',
      address: 'CC Alarife, Bucaramanga',
      tags: ['películas', 'económico', 'familia'],
    ),

    // ─── AIRE LIBRE ──────────────────────────────────────
    PlaceModel(
      id: 'al1',
      name: 'Parque Nacional Chicamocha',
      category: 'Aire Libre',
      categoryIcon: '🏔️',
      description:
          'El parque de aventura más espectacular de Colombia. Teleférico sobre el cañón, zip-line de 2 km, parapente, cabras en libertad y gastronomía típica santandereana.',
      lat: 6.8545,
      lng: -73.0325,
      rating: 4.8,
      priceRange: '\$\$',
      address: 'Km 57 Vía Bucaramanga–San Gil',
      phone: '+57 7 6577777',
      tags: ['aventura', 'teleférico', 'naturaleza', 'zip-line'],
    ),
    PlaceModel(
      id: 'al2',
      name: 'Balcón del Chicamocha',
      category: 'Aire Libre',
      categoryIcon: '🌄',
      description:
          'Mirador natural de acceso libre con vista panorámica al Cañón del Chicamocha. El mejor punto para fotografía al atardecer desde las afueras de Bucaramanga.',
      lat: 6.9012,
      lng: -73.0589,
      rating: 4.6,
      priceRange: 'Gratis',
      address: 'Km 42 Vía Bucaramanga–San Gil',
      tags: ['mirador', 'fotografía', 'naturaleza', 'atardecer'],
    ),
    PlaceModel(
      id: 'al3',
      name: 'Quebrada La Iglesia',
      category: 'Aire Libre',
      categoryIcon: '💧',
      description:
          'Cascada y piscinas naturales en medio del bosque. Muy popular para senderismo de fin de semana, baños naturales y camping básico.',
      lat: 7.1420,
      lng: -73.0920,
      rating: 4.3,
      priceRange: 'Gratis',
      address: 'Floridablanca, área metropolitana',
      tags: ['cascada', 'senderismo', 'camping', 'naturaleza'],
    ),
    PlaceModel(
      id: 'al4',
      name: 'Mesa de los Santos',
      category: 'Aire Libre',
      categoryIcon: '☀️',
      description:
          'Municipio vecino famoso por el café de alta montaña, senderos con vista al cañón y parapente. A solo 40 min de Bucaramanga.',
      lat: 6.9834,
      lng: -73.1120,
      rating: 4.7,
      priceRange: '\$',
      address: 'Mesa de los Santos, Santander',
      tags: ['café', 'parapente', 'montaña', 'senderismo'],
    ),

    // ─── DIVERSIÓN ───────────────────────────────────────
    PlaceModel(
      id: 'd1',
      name: 'Happyland Cacique',
      category: 'Diversión',
      categoryIcon: '🎮',
      description:
          'Centro de entretenimiento familiar con más de 100 juegos electrónicos, simuladores de realidad virtual, zona infantil y torneos semanales.',
      lat: 7.1015,
      lng: -73.1048,
      rating: 4.1,
      priceRange: '\$\$',
      address: 'CC Cacique, Bucaramanga',
      tags: ['juegos', 'familia', 'niños', 'VR'],
    ),
    PlaceModel(
      id: 'd2',
      name: 'Bowling Bucaramanga',
      category: 'Diversión',
      categoryIcon: '🎳',
      description:
          'Centro de bowling con 10 pistas profesionales, billar americano, futbolín y zona de comidas. Perfecto para grupos y empresas.',
      lat: 7.0934,
      lng: -73.1078,
      rating: 4.0,
      priceRange: '\$\$',
      address: 'Cabecera del Llano, Bucaramanga',
      tags: ['bowling', 'grupos', 'billar'],
    ),
    PlaceModel(
      id: 'd3',
      name: 'Karting Bucaramanga',
      category: 'Diversión',
      categoryIcon: '🏎️',
      description:
          'Pista de karts con circuito técnico de 600m, categorías para adultos y niños, cronometría electrónica y servicio de catering para eventos.',
      lat: 7.0789,
      lng: -73.1210,
      rating: 4.4,
      priceRange: '\$\$',
      address: 'Anillo Vial, Bucaramanga',
      tags: ['karts', 'velocidad', 'adrenalina'],
    ),

    // ─── CULTURA ─────────────────────────────────────────
    PlaceModel(
      id: 'cu1',
      name: 'Casa de Bolívar',
      category: 'Cultura',
      categoryIcon: '🏛️',
      description:
          'Museo histórico donde se hospedó Simón Bolívar en 1828. Colecciones de arte colonial, documentos históricos y objetos del período republicano.',
      lat: 7.1230,
      lng: -73.1205,
      rating: 4.5,
      priceRange: '\$',
      address: 'Cll. 37 #12-15, Centro, Bucaramanga',
      phone: '+57 7 6301685',
      tags: ['historia', 'museo', 'Bolívar', 'colonial'],
    ),
    PlaceModel(
      id: 'cu2',
      name: 'Museo de Arte Moderno (MAMB)',
      category: 'Cultura',
      categoryIcon: '🎨',
      description:
          'El MAMB alberga colecciones permanentes y exposiciones temporales de arte contemporáneo colombiano. Talleres de creación artística los fines de semana.',
      lat: 7.1178,
      lng: -73.1143,
      rating: 4.4,
      priceRange: '\$',
      address: 'Cll. 37 #26-16, Bucaramanga',
      phone: '+57 7 6424382',
      tags: ['arte', 'museo', 'contemporáneo', 'exposiciones'],
    ),
    PlaceModel(
      id: 'cu3',
      name: 'Teatro Santander',
      category: 'Cultura',
      categoryIcon: '🎭',
      description:
          'Principal sala de espectáculos de la ciudad. Temporadas de ópera, ballet, teatro y conciertos sinfónicos con artistas nacionales e internacionales.',
      lat: 7.1189,
      lng: -73.1170,
      rating: 4.6,
      priceRange: '\$\$',
      address: 'Cll. 35 #19-20, Bucaramanga',
      phone: '+57 7 6337799',
      tags: ['teatro', 'ópera', 'conciertos', 'ballet'],
    ),
  ];

  // ── Categories ──────────────────────────────────────────
  static const List<String> categories = [
    'Todos',
    'Restaurantes',
    'Parques',
    'Cines',
    'Aire Libre',
    'Diversión',
    'Cultura',
  ];

  static const Map<String, String> categoryIcons = {
    'Todos': '🗺️',
    'Restaurantes': '🍽️',
    'Parques': '🌳',
    'Cines': '🎬',
    'Aire Libre': '🏔️',
    'Diversión': '🎮',
    'Cultura': '🏛️',
  };
}