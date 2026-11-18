import 'package:flutter/material.dart';
import '../models/place_model.dart';
import '../services/firestore_service.dart';

/// Estado global simple de la app
class AppState {
  AppState._();

  // ─ Usuario ───────────────────────────────────────────
  static String userName  = 'Explorador';
  static String userEmail = 'usuario@correo.com';
  static String userCity      = 'Bucaramanga';
  static String? userPhotoPath;  // ruta local de la foto de perfil

  // ─ Favoritos ─────────────────────────────────────────
  static final Set<String> favorites = {};
  static bool isFavorite(String id) => favorites.contains(id);

  /// Agrega o quita un favorito y lo sincroniza con Firestore
  static Future<void> toggleFavorite(String id) async {
    if (favorites.contains(id)) {
      favorites.remove(id);
    } else {
      favorites.add(id);
    }
    // Sincronizar en segundo plano — no bloquea la UI
    FirestoreService.syncFavorites(Set.from(favorites));
  }

  /// Cargar favoritos desde Firestore al iniciar sesión
  static Future<void> loadFavorites() async {
    final favs = await FirestoreService.getFavorites();
    favorites.clear();
    favorites.addAll(favs);
  }

  // ─ Estadísticas ──────────────────────────────────────
  static int routesTraced = 0;

  // ─ Preferencias ──────────────────────────────────────
  static bool notificationsEnabled = true;
  static bool showDistanceInKm     = true;
  static bool showRatings          = true;

  // ─ Limpiar estado al cerrar sesión ───────────────────
  static void clear() {
    userName  = 'Explorador';
    userEmail = 'usuario@correo.com';
    userCity      = 'Bucaramanga';
    userPhotoPath = null;
    favorites.clear();
    routesTraced = 0;
  }

  // ─ Sistema de rutas entre tabs ───────────────────────
  static final ValueNotifier<PlaceModel?> routeRequest = ValueNotifier(null);
  static void Function()? _switchToMap;

  static void registerSwitchToMap(void Function() cb) {
    _switchToMap = cb;
  }

  static void requestRoute(PlaceModel place) {
    routeRequest.value = place;
    _switchToMap?.call();
  }
}