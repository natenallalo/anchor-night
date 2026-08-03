import 'package:flutter/material.dart';

/// פלטה רגועה ללילה — בלי סגול־AI, בלי זוהר אגרסיבי.
class AnchorTheme {
  static const background = Color(0xFF0B1014);
  static const surface = Color(0xFF141B22);
  static const surfaceElevated = Color(0xFF1B2430);
  static const accent = Color(0xFF6FA8C9);
  static const accentSoft = Color(0xFF3D6B82);
  static const calm = Color(0xFF7BA89A);
  static const warn = Color(0xFFC4A574);
  static const danger = Color(0xFFB86B6B);
  static const textPrimary = Color(0xFFE8EEF2);
  static const textMuted = Color(0xFF9AA8B3);

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Segoe UI',
      colorScheme: const ColorScheme.dark(
        surface: surface,
        primary: accent,
        secondary: calm,
        error: danger,
        onPrimary: Color(0xFF061018),
        onSurface: textPrimary,
      ),
      scaffoldBackgroundColor: background,
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: accent,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentSoft,
          foregroundColor: textPrimary,
          // Avoid Size.fromHeight (infinite width) — breaks buttons inside Rows on web.
          minimumSize: const Size(120, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: surfaceElevated,
        contentTextStyle: TextStyle(color: textPrimary),
      ),
    );
  }
}
