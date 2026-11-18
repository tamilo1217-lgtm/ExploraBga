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

  String get durationLabel {
    final min = (durationSeconds / 60).round();
    return min < 60 ? '~$min min' : '~${(min/60).toStringAsFixed(1)} h';
  }

  String get distanceLabel {
    if (distanceMeters < 1000) return '${distanceMeters.toInt()} m';
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }
}

class RouteService {
  static const String _baseUrl = 'https://router.project-osrm.org/route/v1';

  /// [mode] = 'driving' | 'walking'
  /// Retorna RouteResult con hasta 2 rutas (mejor + alternativa)
  static Future<RouteResult> getRoutes(
    double startLat,
    double startLng,
    double endLat,
    double endLng, {
    String mode = 'driving',
  }) async {
    final profile = mode == 'walking' ? 'foot' : 'driving';
    final url = Uri.parse(
      '$_baseUrl/$profile/$startLng,$startLat;$endLng,$endLat'
      '?overview=full&geometries=polyline&alternatives=true',
    );

    print('=== ROUTE [$mode] → $url');

    final response = await http
        .get(url, headers: {'User-Agent': 'ExploraApp/1.0'})
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) throw Exception('HTTP ${response.statusCode}');

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final code = data['code'] as String?;
    if (code != 'Ok') throw Exception('OSRM: $code');

    final rawRoutes = data['routes'] as List;
    if (rawRoutes.isEmpty) throw Exception('Sin rutas disponibles');

    final best   = rawRoutes[0];
    final routes = rawRoutes.take(2).map<List<LatLng>>((r) {
      return _decodePolyline(r['geometry'] as String);
    }).toList();

    final distanceMeters = (best['distance'] as num).toDouble();

    // Calculamos el tiempo desde la distancia con velocidades promedio reales:
    // OSRM usa límites de velocidad de vía (50-60 km/h) lo cual no es realista
    // en ciudad por semáforos, tráfico y lomas (especialmente en Bucaramanga).
    //   🚗 Vehículo: ~25 km/h promedio en ciudad = 6.944 m/s
    //   🚶 A pie:    ~5 km/h promedio caminando  = 1.389 m/s
    final durationSeconds = mode == 'walking'
        ? distanceMeters / 1.389   // ~5 km/h caminando
        : distanceMeters / 6.944;  // ~25 km/h en vehículo (ciudad realista)

    return RouteResult(
      routes:          routes,
      durationSeconds: durationSeconds,
      distanceMeters:  distanceMeters,
    );
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