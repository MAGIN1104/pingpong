import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData light() {
    final baseColorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6750A4),
      brightness: Brightness.light,
    );

    final textTheme = GoogleFonts.urbanistTextTheme().copyWith(
      displayLarge: GoogleFonts.urbanist(
        fontWeight: FontWeight.w600,
        letterSpacing: -1.2,
      ),
      displayMedium: GoogleFonts.urbanist(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.8,
      ),
      displaySmall: GoogleFonts.urbanist(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      headlineLarge: GoogleFonts.urbanist(
        fontWeight: FontWeight.w500,
        letterSpacing: -0.4,
      ),
      headlineMedium: GoogleFonts.urbanist(
        fontWeight: FontWeight.w500,
        letterSpacing: -0.2,
      ),
      headlineSmall: GoogleFonts.urbanist(
        fontWeight: FontWeight.w500,
        letterSpacing: -0.1,
      ),
      titleLarge: GoogleFonts.urbanist(
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
      titleMedium: GoogleFonts.urbanist(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.05,
      ),
      titleSmall: GoogleFonts.urbanist(
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      bodyLarge: GoogleFonts.urbanist(
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: GoogleFonts.urbanist(
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: GoogleFonts.urbanist(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: GoogleFonts.urbanist(fontWeight: FontWeight.w600),
      labelMedium: GoogleFonts.urbanist(fontWeight: FontWeight.w500),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: baseColorScheme.copyWith(
        primary: const Color(0xFF5D5FEF),
        onPrimary: Colors.white,
        secondary: const Color(0xFF8B5CF6),
        onSecondary: Colors.white,
        tertiary: const Color(0xFF00D1FF),
        onTertiary: const Color(0xFF001833),
        surface: const Color(0xFFF7F7FB),
        surfaceContainerHighest: Colors.white,
        surfaceContainerHigh: const Color(0xFFF0F1FF),
        outline: const Color(0xFF9AA3BC),
        outlineVariant: const Color(0xFFE0E3F5),
        error: const Color(0xFFE95858),
        onSurface: const Color(0xFF1F2333),
      ),
      scaffoldBackgroundColor: const Color(0xFFF4F5FB),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF1F2333),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: const Color(0xFF9AA3BC).withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF5D5FEF), width: 1.6),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: const Color(0xFF9AA3BC).withValues(alpha: 0.2),
          ),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: const Color(0xFF5A6275),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: const Color(0xFF5A6275),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected)
                  ? const Color(0xFF5D5FEF)
                  : const Color(0xFFA0A7C0),
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected)
                  ? const Color(0xFF5D5FEF).withValues(alpha: 0.3)
                  : const Color(0xFFA0A7C0).withValues(alpha: 0.2),
        ),
      ),
      sliderTheme: const SliderThemeData(
        overlayShape: RoundSliderOverlayShape(overlayRadius: 20),
        trackShape: RoundedRectSliderTrackShape(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: const Color(0xFF5D5FEF),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF5D5FEF),
          side: const BorderSide(color: Color(0xFF5D5FEF), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          textStyle: textTheme.labelLarge,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: const Color(0xFF5D5FEF),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          textStyle: textTheme.labelLarge,
        ),
      ),
      listTileTheme: ListTileThemeData(
        dense: false,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        titleTextStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        subtitleTextStyle: textTheme.bodySmall?.copyWith(
          color: const Color(0xFF5A6275),
        ),
        iconColor: const Color(0xFF5D5FEF),
      ),
      dividerTheme: DividerThemeData(
        color: const Color(0xFFE1E4F5),
        space: 12,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1F2333),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.72),
        indicatorColor: const Color(0xFF5D5FEF).withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final baseStyle = textTheme.labelMedium!;
          return states.contains(WidgetState.selected)
              ? baseStyle.copyWith(
                color: const Color(0xFF5D5FEF),
                fontWeight: FontWeight.w600,
              )
              : baseStyle.copyWith(color: const Color(0xFF5A6275));
        }),
      ),
    );
  }
}
