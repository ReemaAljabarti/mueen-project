import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF15B4BE);
  static const Color secondary = Color(0xFF8FCFAF);
  static const Color background = Color(0xFFF5FBFC);
  static const Color textDark = Color(0xFF102A33);
  static const Color textLight = Color(0xFF8A9AA0);
  static const Color white = Colors.white;
  static const Color error = Color(0xFF7A1F1F);
  static const Color errorBg = Color(0xFFF2D6D3);
  static const Color warning = Color(0xFFF6E6C8);
  static const Color warningText = Color(0xFF663C00);
  static const Color info = Color(0xFFD4F5F9);
  static const Color infoText = Color(0xFF003948);
  static const Color success = Color(0xFF15B4BE);
  static const Color successBg = Color(0xFFEAF7F7);

  // Severity Colors
  static const Color severityHigh = Color(0xFF7A1C1C);
  static const Color severityHighBg = Color(0xFFF8D7D4);
  static const Color severityMedium = Color(0xFF663C00);
  static const Color severityMediumBg = Color(0xFFF6E6C8);
  static const Color severityLow = Color(0xFF003948);
  static const Color severityLowBg = Color(0xFFD4F5F9);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Tajawal',
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: AppColors.textDark, fontSize: 32, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: AppColors.textDark, fontSize: 24, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(color: AppColors.textDark, fontSize: 18),
        bodyMedium: TextStyle(color: AppColors.textDark, fontSize: 16),
        labelLarge: TextStyle(color: AppColors.textLight, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Tajawal'),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        hintStyle: const TextStyle(color: Color(0x80102A33), fontSize: 16),
      ),
    );
  }
}
