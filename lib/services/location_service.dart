import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Pide permiso (si hace falta) y devuelve la posición actual una sola vez.
  static Future<Position?> getCurrentLocation() async {
    if (!await hasPermission()) return null;
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// true si el GPS está encendido y la app tiene permiso de ubicación.
  static Future<bool> hasPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    return permission != LocationPermission.deniedForever;
  }

  /// Flujo continuo de posiciones para seguir al usuario mientras camina.
  /// Emite una posición nueva cada vez que el usuario se mueve 3 metros o más.
  static Stream<Position> positionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3,
      ),
    );
  }
}
