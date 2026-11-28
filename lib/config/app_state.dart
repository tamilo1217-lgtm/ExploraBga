import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/place_model.dart';
import '../models/thematic_route.dart';
import '../services/firestore_service.dart';

/// Estado global simple de la app
class AppState {
  AppState._();

  // ─ Usuario ───────────────────────────────────────────
  static String userName  = 'Explorador';
  static String userEmail = 'usuario@correo.com';
  static String userCity      = 'Bucaramanga';
  static Uint8List? userPhotoBytes;  // foto de perfil (guardada en Firestore)

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

  /// Cargar nombre, ciudad y foto del perfil desde Firestore
  static Future<void> loadProfile() async {
    final data = await FirestoreService.getProfile();
    if (data == null) return;
    userName = (data['name'] as String?) ?? userName;
    userCity = (data['city'] as String?) ?? userCity;
    final b64 = data['photoBase64'] as String?;
    userPhotoBytes = (b64 != null && b64.isNotEmpty) ? base64Decode(b64) : null;
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
    userPhotoBytes = null;
    favorites.clear();
    routesTraced = 0;
  }

  // ─ Lugares (Sprint 2: vienen de Firestore) ───────────
  /// Lista de lugares que usan todas las pantallas. Arranca con la lista local
  /// para que el mapa no espere, y se reemplaza por la de Firestore al cargar.
  static List<PlaceModel> places = List.of(PlaceModel.allPlaces);

  /// Cambia cada vez que se actualizan los lugares (las pantallas lo escuchan).
  static final ValueNotifier<int> placesVersion = ValueNotifier(0);

  /// Sube la semilla si hace falta y luego lee los lugares de Firestore.
  /// Si no hay internet, se quedan los locales.
  static Future<void> loadPlaces() async {
    try {
      await FirestoreService.syncPlaces();
      final remote = await FirestoreService.getPlaces();
      if (remote.isNotEmpty) {
        places = remote;
        placesVersion.value++;
      }
    } catch (e) {
      print('=== FIRESTORE lugares no disponibles ($e), se usan los locales');
    }
  }

  static PlaceModel? placeById(String id) {
    for (final p in places) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Vuelve a leer el promedio de un lugar después de guardar o borrar una reseña.
  static Future<void> refreshPlaceRating(String placeId) async {
    final (avg, count) = await FirestoreService.getPlaceRating(placeId);
    final i = places.indexWhere((p) => p.id == placeId);
    if (i >= 0) {
      places[i] = places[i].copyWithRating(avg, count);
      placesVersion.value++;
    }
  }

  // ─ Rutas temáticas entre tabs (Sprint 1) ─────────────
  static final ValueNotifier<ThematicRoute?> thematicRouteRequest = ValueNotifier(null);

  static void requestThematicRoute(ThematicRoute route) {
    thematicRouteRequest.value = route;
    _switchToMap?.call();
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