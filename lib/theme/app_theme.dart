import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tema único de Explora BGA (estilo "Parque": verde oscuro + ámbar).
/// Todas las pantallas leen sus colores de aquí; para cambiar el estilo
/// de toda la app basta con editar esta clase.
class AppTheme {
  // ── Colores ─────────────────────────────────────────────
  static const Color background    = Color(0xFF0F2A22);
  static const Color surface       = Color(0xFF16382E);
  static const Color surfaceLight  = Color(0xFF1F4A3C);
  static const Color accent        = Color(0xFFF5A623); // ámbar
  static const Color accentGold    = Color(0xFFFFD166);
  static const Color green         = Color(0xFF2ECC8F);
  static const Color onAccent      = Color(0xFF1B1B1B); // texto sobre ámbar
  static const Color textPrimary   = Color(0xFFF2F7F4);
  static const Color textSecondary = Color(0xFF9DB8AD);
  static const Color success       = Color(0xFF2ECC8F);
  static const Color error         = Color(0xFFE5645A);

  /// Color de la ruta en el mapa (distinto al de las calles).
  static const Color route         = Color(0xFF7B2FF7);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        onPrimary: onAccent,
        secondary: green,
        surface: surface,
        error: error,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: accent, width: 1.6),
        ),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 14),
        hintStyle: const TextStyle(color: textSecondary, fontSize: 14),
        prefixIconColor: textSecondary,
        floatingLabelStyle: const TextStyle(color: accent, fontSize: 13),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: onAccent,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }
}
