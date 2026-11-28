import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' show LatLng;

class RouteResult {
  final List<List<LatLng>> routes;   // [0]=mejor, [1]=alternativa
  final double durationSeconds;
  final double distanceMeters;

  const RouteResult({
    required this.routes,
    required this.durationSeconds,
    required this.distanceMeters,
  });

  String get durationLabel => RouteService.formatDuration(durationSeconds);
  String get distanceLabel => RouteService.formatDistance(distanceMeters);
}

class RouteService {
  // Servidor OSRM de FOSSGIS (OpenStreetMap Alemania): tiene un perfil real
  // para caminar (routed-foot) y otro para vehículo (routed-car).
  // El servidor de demostración router.project-osrm.org solo calcula rutas en
  // carro aunque se le pida "foot"; por eso se deja únicamente como respaldo.
  static const String _fossgisUrl = 'https://routing.openstreetmap.de';
  static const String _demoUrl    = 'https://router.project-osrm.org/route/v1/driving';

  // Velocidades promedio usadas para estimar el tiempo (ver getRoutes).
  static const double _walkSpeed  = 1.389; // ~5 km/h caminando
  static const double _driveSpeed = 6.944; // ~25 km/h en vehículo (ciudad)

  /// Tiempo estimado en segundos para recorrer [meters] según el modo.
  static double estimateSeconds(double meters, String mode) =>
      meters / (mode == 'walking' ? _walkSpeed : _driveSpeed);

  static String formatDuration(double seconds) {
    final min = (seconds / 60).round();
    if (min < 1) return '< 1 min';
    if (min < 60) return '~$min min';
    final h = min ~/ 60, m = min % 60;
    return m == 0 ? '~$h h' : '~$h h $m min';
  }

  static String formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  /// [mode] = 'driving' | 'walking'
  /// Retorna RouteResult con hasta 2 rutas (mejor + alternativa)
  static Future<RouteResult> getRoutes(
    double startLat,
    double startLng,
    double endLat,
    double endLng, {
    String mode = 'driving',
  }) {
    return getRouteThrough([LatLng(startLat, startLng), LatLng(endLat, endLng)], mode: mode);
  }

  /// Ruta que pasa por varios puntos en orden (rutas temáticas).
  /// [points][0] es el origen y el último es el destino final.
  static Future<RouteResult> getRouteThrough(List<LatLng> points, {String mode = 'driving'}) async {
    if (points.length < 2) throw Exception('Se necesitan al menos 2 puntos');
    final coords = points.map((p) => '${p.longitude},${p.latitude}').join(';');
    const query  = '?overview=full&geometries=polyline&alternatives=false';
    final profile = mode == 'walking' ? 'foot' : 'car';

    Map<String, dynamic> data;
    try {
      data = await _pedir(Uri.parse('$_fossgisUrl/routed-$profile/route/v1/driving/$coords$query'), mode);
    } catch (e) {
      // Si FOSSGIS no responde se usa el servidor de demostración (solo vehículo).
      print('=== ROUTE [$mode] FOSSGIS falló ($e), se usa el servidor de respaldo');
      data = await _pedir(Uri.parse('$_demoUrl/$coords$query'), mode);
    }

    final rawRoutes = data['routes'] as List;
    if (rawRoutes.isEmpty) throw Exception('Sin rutas disponibles');

    final best   = rawRoutes[0];
    final routes = rawRoutes.take(2).map<List<LatLng>>((r) {
      return _decodePolyline(r['geometry'] as String);
    }).toList();

    final distanceMeters = (best['distance'] as num).toDouble();
    print('=== ROUTE RESULT [$mode] paradas=${points.length - 1} distancia=${distanceMeters.round()} m, OSRM=${(best['duration'] as num).round()} s');

    // Calculamos el tiempo desde la distancia con velocidades promedio reales:
    // OSRM usa límites de velocidad de vía (50-60 km/h) lo cual no es realista
    // en ciudad por semáforos, tráfico y lomas (especialmente en Bucaramanga).
    //   🚗 Vehículo: ~25 km/h promedio en ciudad = 6.944 m/s
    //   🚶 A pie:    ~5 km/h promedio caminando  = 1.389 m/s
    final durationSeconds = estimateSeconds(distanceMeters, mode);

    return RouteResult(
      routes:          routes,
      durationSeconds: durationSeconds,
      distanceMeters:  distanceMeters,
    );
  }

  /// Hace la petición HTTP a OSRM y devuelve el JSON si la respuesta es válida.
  static Future<Map<String, dynamic>> _pedir(Uri url, String mode) async {
    print('=== ROUTE [$mode] → $url');
    final response = await http
        .get(url, headers: {'User-Agent': 'ExploraBGA/1.0 (com.yesidmanrique.explorabga)'})
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) throw Exception('HTTP ${response.statusCode}');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final code = data['code'] as String?;
    if (code != 'Ok') throw Exception('OSRM: $code');
    return data;
  }

  /// Retrocompatibilidad con código anterior
  static Future<List<LatLng>> getRoute(
    double startLat, double startLng,
    double endLat,   double endLng,
  ) async {
    final result = await getRoutes(startLat, startLng, endLat, endLng);
    return result.routes.isNotEmpty ? result.routes.first : [];
  }

  static List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> points = [];
    int index = 0;
    final int len = encoded.length;
    int lat = 0, lng = 0;
    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      shift = 0; result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }
}