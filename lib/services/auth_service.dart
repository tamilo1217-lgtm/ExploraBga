import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─ Usuario actual ─────────────────────────────────────
  static User? get currentUser => _auth.currentUser;
  static String? get currentUserId => _auth.currentUser?.uid;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ─ Registro ───────────────────────────────────────────
  static Future<String?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // Actualizar nombre en Firebase Auth
      await credential.user?.updateDisplayName(name.trim());

      // Crear documento en Firestore
      await _db.collection('users').doc(credential.user!.uid).set({
        'uid':       credential.user!.uid,
        'name':      name.trim(),
        'email':     email.trim(),
        'city':      'Bucaramanga',
        'createdAt': FieldValue.serverTimestamp(),
        'stats': {
          'routesTraced':   0,
          'totalDistanceKm': 0.0,
          'favoritesCount': 0,
        },
      });

      return null; // null = éxito
    } on FirebaseAuthException catch (e) {
      return _authError(e.code);
    } catch (e) {
      return 'Error inesperado: $e';
    }
  }

  // ─ Login ──────────────────────────────────────────────
  static Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return null; // null = éxito
    } on FirebaseAuthException catch (e) {
      return _authError(e.code);
    } catch (e) {
      return 'Error inesperado: $e';
    }
  }

  // ─ Logout ─────────────────────────────────────────────
  static Future<void> logout() async {
    await _auth.signOut();
  }

  // ─ Cambiar contraseña ─────────────────────────────────
  static Future<String?> changePassword(String newPassword) async {
    try {
      await _auth.currentUser?.updatePassword(newPassword);
      return null;
    } on FirebaseAuthException catch (e) {
      return _authError(e.code);
    }
  }

  // ─ Recuperar contraseña ───────────────────────────────
  static Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return _authError(e.code);
    }
  }

  // ─ Mensajes de error en español ───────────────────────
  static String _authError(String code) {
    switch (code) {
      case 'user-not-found':       return 'No existe una cuenta con ese correo';
      case 'wrong-password':       return 'Contraseña incorrecta';
      case 'invalid-credential':   return 'Correo o contraseña incorrectos';
      case 'email-already-in-use': return 'Ese correo ya está registrado';
      case 'weak-password':        return 'La contraseña debe tener al menos 6 caracteres';
      case 'invalid-email':        return 'El correo no es válido';
      case 'too-many-requests':    return 'Demasiados intentos, intenta más tarde';
      case 'network-request-failed': return 'Sin conexión a internet';
      default:                     return 'Error: $code';
    }
  }
}          