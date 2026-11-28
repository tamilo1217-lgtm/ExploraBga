import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import '../models/place_model.dart';
import '../models/thematic_route.dart';

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

  /// Guardar la foto de perfil (imagen pequeña en base64; null = eliminar).
  /// Se usa Firestore porque Firebase Storage exige el plan Blaze.
  static Future<void> savePhoto(String? base64Photo) async {
    await _userDoc?.set({'photoBase64': base64Photo ?? ''}, SetOptions(merge: true));
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

  // ══════════════════════════════════════════════════════
  // LUGARES (Sprint 2): colección `places`
  // ══════════════════════════════════════════════════════

  /// Sube los lugares de PlaceModel.allPlaces a Firestore si la versión guardada
  /// en `meta/places` es menor que PlaceModel.dataVersion (o si no existe).
  /// Se usa merge para NO borrar ratingSum / ratingCount de las reseñas.
  static Future<void> syncPlaces() async {
    final meta = _db.collection('meta').doc('places');
    final snap = await meta.get();
    final remote = (snap.data()?['version'] as num?)?.toInt() ?? 0;
    if (remote >= PlaceModel.dataVersion) return;

    final batch = _db.batch();
    for (final p in PlaceModel.allPlaces) {
      batch.set(_db.collection('places').doc(p.id), p.toMap(), SetOptions(merge: true));
    }
    batch.set(meta, {
      'version': PlaceModel.dataVersion,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    print('=== FIRESTORE lugares subidos: ${PlaceModel.allPlaces.length} (versión ${PlaceModel.dataVersion})');
  }

  /// Lee todos los lugares de Firestore (con su calificación real).
  static Future<List<PlaceModel>> getPlaces() async {
    final snap = await _db.collection('places').get();
    final list = snap.docs.map((d) => PlaceModel.fromMap(d.id, d.data())).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    return list;
  }

  // ══════════════════════════════════════════════════════
  // RUTAS TEMÁTICAS (Sprint 1): colección `thematicRoutes`
  // ══════════════════════════════════════════════════════

  /// Sube ThematicRoute.defaults si la versión de `meta/thematicRoutes` es menor.
  static Future<void> syncThematicRoutes() async {
    final meta = _db.collection('meta').doc('thematicRoutes');
    final snap = await meta.get();
    final remote = (snap.data()?['version'] as num?)?.toInt() ?? 0;
    if (remote >= ThematicRoute.dataVersion) return;

    final batch = _db.batch();
    for (final r in ThematicRoute.defaults) {
      batch.set(_db.collection('thematicRoutes').doc(r.id), r.toMap());
    }
    batch.set(meta, {
      'version': ThematicRoute.dataVersion,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    print('=== FIRESTORE rutas temáticas subidas: ${ThematicRoute.defaults.length}');
  }

  /// Lee las rutas temáticas ordenadas. Si falla (sin internet), usa las del código.
  static Future<List<ThematicRoute>> getThematicRoutes() async {
    try {
      await syncThematicRoutes();
      final snap = await _db.collection('thematicRoutes').orderBy('order').get();
      final list = snap.docs.map((d) => ThematicRoute.fromMap(d.id, d.data())).toList();
      return list.isEmpty ? ThematicRoute.defaults : list;
    } catch (e) {
      print('=== FIRESTORE rutas temáticas no disponibles ($e), se usan las locales');
      return ThematicRoute.defaults;
    }
  }

  // ══════════════════════════════════════════════════════
  // RESEÑAS (Sprint 2): places/{placeId}/reviews/{uid}
  // Una reseña por usuario y lugar (el id del documento es el uid).
  // El lugar guarda ratingSum y ratingCount para calcular el promedio.
  // ══════════════════════════════════════════════════════

  static CollectionReference<Map<String, dynamic>> _reviews(String placeId) =>
      _db.collection('places').doc(placeId).collection('reviews');

  /// Reseñas de un lugar en tiempo real, de la más reciente a la más antigua.
  static Stream<List<Map<String, dynamic>>> reviewsStream(String placeId) {
    return _reviews(placeId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => {...d.data(), 'id': d.id}).toList());
  }

  /// Guarda (o reemplaza) la reseña del usuario y actualiza el promedio del lugar
  /// en una transacción, para que la suma y el conteo nunca queden desfasados.
  static Future<void> saveReview({
    required String placeId,
    required int rating,
    required String comment,
    required String userName,
  }) async {
    final uid = AuthService.currentUserId;
    if (uid == null) throw Exception('Sin sesión');
    final reviewRef = _reviews(placeId).doc(uid);
    final placeRef  = _db.collection('places').doc(placeId);

    await _db.runTransaction((tx) async {
      final old = await tx.get(reviewRef);
      final oldRating = (old.data()?['rating'] as num?)?.toInt();

      tx.set(reviewRef, {
        'userId':    uid,
        'userName':  userName,
        'rating':    rating,
        'comment':   comment,
        'createdAt': old.exists ? old.data()!['createdAt'] : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      tx.set(placeRef, {
        'ratingSum':   FieldValue.increment(rating - (oldRating ?? 0)),
        'ratingCount': FieldValue.increment(oldRating == null ? 1 : 0),
      }, SetOptions(merge: true));
    });
  }

  /// Elimina la reseña del usuario y la descuenta del promedio.
  static Future<void> deleteReview(String placeId) async {
    final uid = AuthService.currentUserId;
    if (uid == null) return;
    final reviewRef = _reviews(placeId).doc(uid);
    final placeRef  = _db.collection('places').doc(placeId);

    await _db.runTransaction((tx) async {
      final old = await tx.get(reviewRef);
      if (!old.exists) return;
      final oldRating = (old.data()?['rating'] as num?)?.toInt() ?? 0;
      tx.delete(reviewRef);
      tx.set(placeRef, {
        'ratingSum':   FieldValue.increment(-oldRating),
        'ratingCount': FieldValue.increment(-1),
      }, SetOptions(merge: true));
    });
  }

  /// Lee el promedio actual de un lugar: (promedio, cantidad).
  static Future<(double, int)> getPlaceRating(String placeId) async {
    final doc = await _db.collection('places').doc(placeId).get();
    final count = (doc.data()?['ratingCount'] as num?)?.toInt() ?? 0;
    final sum   = (doc.data()?['ratingSum'] as num?)?.toDouble() ?? 0;
    return (count > 0 ? sum / count : 0.0, count);
  }
}