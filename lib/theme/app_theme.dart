import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Colors ─────────────────────────────────────────────────────────────────
  static const Color bgDark      = Color(0xFF080B17);
  static const Color bgCard      = Color(0xFF111827);
  static const Color bgPanel     = Color(0xFF0F111A);
  static const Color accent      = Color(0xFFA855F7);   // neon purple
  static const Color accentGold  = Color(0xFFF59E0B);   // gold
  static const Color accentCyan  = Color(0xFF06B6D4);   // cyan
  static const Color accentGreen = Color(0xFF10B981);   // emerald
  static const Color accentRed   = Color(0xFFEF4444);   // red
  static const Color textPrimary = Color(0xFFF9FAFB);
  static const Color textSub     = Color(0xFF9CA3AF);
  static const Color bgDarkHub   = Color(0xFF1E1E1E);
  static const Color border      = Color(0xFF1F2937);

  // ── Wheel segment colors ───────────────────────────────────────────────────
  static const List<Color> wheelColors = [
    Color(0xFF3B82F6), // Blue
    Color(0xFF10B981), // Green
    Color(0xFF06B6D4), // Cyan
    Color(0xFFA855F7), // Lavender/Purple
    Color(0xFFD946EF), // Magenta
  ];

  // ── Gradient ───────────────────────────────────────────────────────────────
  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFA855F7), Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const RadialGradient warmGlowGradient = RadialGradient(
    colors: [Color(0xFFF87171), Colors.transparent],
    center: Alignment(0.5, 0.0),
    radius: 0.8,
  );

  // ── Theme ──────────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: accentGold,
        surface: bgCard,
        error: accentRed,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        const TextTheme(
          displayLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
          displayMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
          titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(color: textPrimary),
          bodyMedium: TextStyle(color: textSub),
          labelLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgPanel,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        hintStyle: const TextStyle(color: textSub),
        labelStyle: const TextStyle(color: textSub),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      dividerColor: border,
      useMaterial3: true,
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  static BoxDecoration glassCard({double radius = 16, Color? color}) {
    return BoxDecoration(
      color: color ?? bgCard.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: border.withValues(alpha: 0.5)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.4),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  static BoxDecoration accentBorder({double radius = 12}) {
    return BoxDecoration(
      gradient: accentGradient,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: accent.withValues(alpha: 0.35),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
