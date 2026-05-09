import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color _gold = Color(0xFFCFB53B);
const Color _darkBg = Color(0xFF1A1A1A);
const Color _surface = Color(0xFF2A2A2A);

ThemeData buildAppTheme() {
  final base = ThemeData(brightness: Brightness.dark);
  return base.copyWith(
    scaffoldBackgroundColor: _darkBg,
    colorScheme: const ColorScheme.dark(
      primary: _gold,
      secondary: _gold,
      surface: _surface,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: _darkBg,
      foregroundColor: _gold,
      elevation: 0,
    ),
    textTheme: GoogleFonts.robotoSerifTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.cinzel(color: _gold, fontSize: 32),
      displayMedium: GoogleFonts.cinzel(color: _gold, fontSize: 28),
      displaySmall: GoogleFonts.cinzel(color: _gold, fontSize: 24),
      headlineLarge: GoogleFonts.cinzel(color: _gold, fontSize: 22),
      headlineMedium: GoogleFonts.cinzel(color: _gold, fontSize: 20),
      headlineSmall: GoogleFonts.cinzel(color: _gold, fontSize: 18),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _gold,
        foregroundColor: Colors.black,
      ),
    ),
  );
}
