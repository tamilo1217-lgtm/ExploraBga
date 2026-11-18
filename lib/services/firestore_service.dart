import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─ Referencia al usuario actual ───────────────────────
  static DocumentReference? get _userDoc {
    final uid = AuthService.currentUserId;
    if (uid == null) return null;
    return _db.collection('users').doc(uid);
  }

  // ══════════════════════════════════════════════════════
  // PERFIL
  // ══════════════════════════════════════════════════════

  /// Obtener datos del perfil
  static Future<Map<String, dynamic>?> getProfile() async {
    try {
      final doc = await _userDoc?.get();
      return doc?.data() as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  /// Actualizar nombre y ciudad
  static Future<void> updateProfile({
    required String name,
    required String city,
  }) async {
    await _userDoc?.update({'name': name, 'city': city});
  }

  // ══════════════════════════════════════════════════════
  // RUTAS TRAZADAS
  // ══════════════════════════════════════════════════════

  /// Guardar una ruta trazada
  static Future<void> saveRoute({
    required String placeName,
    required String placeCategory,
    required double destLat,
    required double destLng,
    required double distanceKm,
  }) async {
    final uid = AuthService.currentUserId;
    if (uid == null) return;

    // Guardar en subcolección routes
    await _db.collection('users').doc(uid).collection('routes').add({
      'placeName':     placeName,
      'placeCategory': placeCategory,
      'destLat':       destLat,
      'destLng':       destLng,
      'distanceKm':    distanceKm,
      'tracedAt':      FieldValue.serverTimestamp(),
    });

    // Solo incrementar el contador de rutas — no sumamos km
    // porque la distancia se calcula al trazar, no al recorrer
    await _userDoc?.update({
      'stats.routesTraced': FieldValue.increment(1),
    });
  }

  /// Obtener historial de rutas
  static Future<List<Map<String, dynamic>>> getRouteHistory() async {
    final uid = AuthService.currentUserId;
    if (uid == null) return [];
    try {
      final snap = await _db
          .collection('users')
          .doc(uid)
          .collection('routes')
          .orderBy('tracedAt', descending: true)
          .limit(20)
          .get();
      return snap.docs.map((d) => d.data()).toList();
    } catch (_) {
      return [];
    }
  }

  // ══════════════════════════════════════════════════════
  // FAVORITOS
  // ══════════════════════════════════════════════════════

  /// Guardar favoritos completos
  static Future<void> syncFavorites(Set<String> favoriteIds) async {
    // set con merge:true — no falla si el campo no existía antes
    await _userDoc?.set({
      'favorites': favoriteIds.toList(),
      'stats':     {'favoritesCount': favoriteIds.length},
    }, SetOptions(merge: true));
  }

  /// Obtener favoritos guardados
  static Future<Set<String>> getFavorites() async {
    try {
      final doc  = await _userDoc?.get();
      final data = doc?.data() as Map<String, dynamic>?;
      final favs = data?['favorites'] as List<dynamic>?;
      return favs?.map((e) => e.toString()).toSet() ?? {};
    } catch (_) {
      return {};
    }
  }

  // ══════════════════════════════════════════════════════
  // ESTADÍSTICAS
  // ══════════════════════════════════════════════════════

  /// Obtener stats del usuario
  static Future<Map<String, dynamic>> getStats() async {
    try {
      final doc  = await _userDoc?.get();
      final data = doc?.data() as Map<String, dynamic>?;
      return data?['stats'] as Map<String, dynamic>? ?? {
        'routesTraced':   0,
        'favoritesCount': 0,
      };
    } catch (_) {
      return {
        'routesTraced':   0,
        'favoritesCount': 0,
      };
    }
  }

  // ══════════════════════════════════════════════════════
  // LUGARES VISITADOS
  // ══════════════════════════════════════════════════════

  /// Marcar un lugar como visitado
  static Future<void> markVisited({
    required String placeId,
    required String placeName,
    required String category,
  }) async {
    final uid = AuthService.currentUserId;
    if (uid == null) return;
    await _db
        .collection('users')
        .doc(uid)
        .collection('visited')
        .doc(placeId)
        .set({
      'placeId':   placeId,
      'placeName': placeName,
      'category':  category,
      'visitedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Obtener lugares visitados
  static Future<List<Map<String, dynamic>>> getVisited() async {
    final uid = AuthService.currentUserId;
    if (uid == null) return [];
    try {
      final snap = await _db
          .collection('users')
          .doc(uid)
          .collection('visited')
          .orderBy('visitedAt', descending: true)
          .get();
      return snap.docs.map((d) => d.data()).toList();
    } catch (_) {
      return [];
    }
  }
}