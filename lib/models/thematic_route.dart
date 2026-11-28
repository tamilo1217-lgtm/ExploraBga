/// Ruta temática: recorrido sugerido por varias paradas en orden (Sprint 1).
/// Se guarda en la colección `thematicRoutes` de Firestore.
/// Las paradas son ids de lugares reales de PlaceModel (no se inventan lugares).
class ThematicRoute {
  final String id;
  final String name;
  final String description;
  final String icon;
  final List<String> placeIds; // paradas en el orden del recorrido
  final String mode;           // modo sugerido: 'walking' | 'driving'
  final int order;             // posición en la lista

  const ThematicRoute({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.placeIds,
    required this.mode,
    required this.order,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'icon': icon,
        'placeIds': placeIds,
        'mode': mode,
        'order': order,
      };

  factory ThematicRoute.fromMap(String id, Map<String, dynamic> m) => ThematicRoute(
        id: id,
        name: m['name'] as String? ?? '',
        description: m['description'] as String? ?? '',
        icon: m['icon'] as String? ?? '🧭',
        placeIds: (m['placeIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
        mode: m['mode'] as String? ?? 'walking',
        order: (m['order'] as num?)?.toInt() ?? 0,
      );

  String get modeLabel => mode == 'walking' ? 'A pie' : 'En vehículo';
  String get modeIcon  => mode == 'walking' ? '🚶' : '🚗';

  /// Versión de [defaults]. Subirla en 1 si se cambian las rutas en el código
  /// para que la app las vuelva a subir a Firestore.
  static const int dataVersion = 1;

  /// Rutas iniciales. Se arman solo con lugares que ya existen en PlaceModel.allPlaces,
  /// ordenados para que el recorrido entre paradas sea el más corto.
  static const List<ThematicRoute> defaults = [
    ThematicRoute(
      id: 'R1',
      name: 'Centro histórico',
      description: 'Recorrido a pie por el Parque García Rovira, los templos que lo rodean, '
          'el Museo Casa de Bolívar y el Parque Santander con la Catedral.',
      icon: '🏛️',
      placeIds: ['L25', 'L27', 'L02', 'L28', 'L24', 'L01'],
      mode: 'walking',
      order: 1,
    ),
    ThematicRoute(
      id: 'R2',
      name: 'Parques de la ciudad',
      description: 'Recorrido por los parques del centro y del sector de Cabecera.',
      icon: '🌳',
      placeIds: ['L06', 'L01', 'L07', 'L04', 'L08', 'L03'],
      mode: 'walking',
      order: 2,
    ),
    ThematicRoute(
      id: 'R3',
      name: 'Naturaleza',
      description: 'Parques ecológicos y zonas verdes amplias del área metropolitana.',
      icon: '🌿',
      placeIds: ['L11', 'L09', 'L10'],
      mode: 'driving',
      order: 3,
    ),
    ThematicRoute(
      id: 'R4',
      name: 'Ruta gastronómica',
      description: 'Restaurantes y pastelerías de Bucaramanga.',
      icon: '🍽️',
      placeIds: ['L21', 'L20', 'L22', 'L19', 'L23'],
      mode: 'driving',
      order: 4,
    ),
    ThematicRoute(
      id: 'R5',
      name: 'Ruta de compras',
      description: 'Centros comerciales de Bucaramanga y Floridablanca.',
      icon: '🛍️',
      placeIds: ['L16', 'L17', 'L13', 'L14', 'L15'],
      mode: 'driving',
      order: 5,
    ),
  ];
}
