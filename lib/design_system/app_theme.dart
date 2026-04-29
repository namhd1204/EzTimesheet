import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Minimal Design System - Dark Mode First
/// A refined, sophisticated design system with careful attention to
/// typography, spacing, and subtle visual details.
class AppTheme {
  AppTheme._();

  // ============================================
  // COLOR TOKENS - Dark Mode First
  // ============================================

  /// Primary color - sophisticated indigo with subtle warmth
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);

  /// Secondary color - muted teal for accents
  static const Color secondary = Color(0xFF14B8A6);
  static const Color secondaryLight = Color(0xFF2DD4BF);
  static const Color secondaryDark = Color(0xFF0D9488);

  /// Surface colors - carefully graded dark backgrounds
  static const Color surface = Color(0xFF0F0F0F);
  static const Color surfaceElevated = Color(0xFF1A1A1A);
  static const Color surfaceHighlight = Color(0xFF252525);
  static const Color surfaceSubtle = Color(0xFF0A0A0A);

  /// Error color - refined red, not aggressive
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFF87171);
  static const Color errorDark = Color(0xFFDC2626);

  /// Text colors - carefully tuned for dark mode readability
  static const Color textPrimary = Color(0xFFFAFAFA);
  static const Color textSecondary = Color(0xFFA1A1AA);
  static const Color textTertiary = Color(0xFF71717A);
  static const Color textInverse = Color(0xFF09090B);

  /// Border and divider colors - subtle, not distracting
  static const Color border = Color(0xFF27272A);
  static const Color borderSubtle = Color(0xFF1E1E20);
  static const Color divider = Color(0xFF18181B);

  /// Overlay colors
  static const Color overlay = Color(0x80000000);
  static const Color overlayLight = Color(0x40000000);

  // ============================================
  // TYPOGRAPHY SCALE - Google Fonts
  // ============================================

  /// Display typography - dramatic, commanding presence
  static TextStyle get displayLarge => GoogleFonts.spaceGrotesk(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
        height: 1.1,
      );

  static TextStyle get displayMedium => GoogleFonts.spaceGrotesk(
        fontSize: 45,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.15,
      );

  static TextStyle get displaySmall => GoogleFonts.spaceGrotesk(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.2,
      );

  /// Headline typography - clear hierarchy
  static TextStyle get headlineLarge => GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.25,
      );

  static TextStyle get headlineMedium => GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.3,
      );

  static TextStyle get headlineSmall => GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.35,
      );

  /// Body typography - refined readability
  static TextStyle get bodyLarge => GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        height: 1.5,
      );

  static TextStyle get bodyMedium => GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        height: 1.5,
      );

  static TextStyle get bodySmall => GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        height: 1.4,
      );

  /// Label typography - functional and clear
  static TextStyle get labelLarge => GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.4,
      );

  static TextStyle get labelMedium => GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.3,
      );

  static TextStyle get labelSmall => GoogleFonts.outfit(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.3,
      );

  // ============================================
  // SPACING SYSTEM - 8pt grid
  // ============================================

  static const double space0 = 0;
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space8 = 32;
  static const double space10 = 40;
  static const double space12 = 48;
  static const double space16 = 64;
  static const double space20 = 80;
  static const double space24 = 96;

  /// Spacing helpers
  static const EdgeInsets paddingAll = EdgeInsets.all(space4);
  static const EdgeInsets paddingSmall = EdgeInsets.all(space2);
  static const EdgeInsets paddingMedium = EdgeInsets.all(space4);
  static const EdgeInsets paddingLarge = EdgeInsets.all(space6);

  static const EdgeInsets paddingHorizontal =
      EdgeInsets.symmetric(horizontal: space4);
  static const EdgeInsets paddingVertical =
      EdgeInsets.symmetric(vertical: space4);

  // ============================================
  // BORDER RADIUS - Subtle refinement
  // ============================================

  static const double radiusNone = 0;
  static const double radiusSmall = 4;
  static const double radiusMedium = 8;
  static const double radiusLarge = 12;
  static const double radiusXLarge = 16;
  static const double radiusFull = 9999;

  /// Border radius helpers
  static BorderRadius borderRadiusSmall = BorderRadius.circular(radiusSmall);
  static BorderRadius borderRadiusMedium = BorderRadius.circular(radiusMedium);
  static BorderRadius borderRadiusLarge = BorderRadius.circular(radiusLarge);
  static BorderRadius borderRadiusXLarge = BorderRadius.circular(radiusXLarge);

  // ============================================
  // ELEVATION - Subtle depth
  // ============================================

  static const double elevationNone = 0;
  static const double elevationSmall = 1;
  static const double elevationMedium = 2;
  static const double elevationLarge = 4;
  static const double elevationXLarge = 8;

  // ============================================
  // THEME DATA
  // ============================================

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,

        // Color scheme
        colorScheme: const ColorScheme.dark(
          primary: primary,
          secondary: secondary,
          surface: surface,
          error: error,
          onPrimary: textInverse,
          onSecondary: textInverse,
          onSurface: textPrimary,
          onError: textInverse,
        ),

        // Scaffold background
        scaffoldBackgroundColor: surface,

        // App bar theme
        appBarTheme: const AppBarTheme(
          backgroundColor: surface,
          foregroundColor: textPrimary,
          elevation: elevationNone,
          centerTitle: true,
          titleSpacing: space4,
        ),

        // Card theme
        cardTheme: CardThemeData(
          color: surfaceElevated,
          elevation: elevationSmall,
          shape: RoundedRectangleBorder(
            borderRadius: borderRadiusMedium,
          ),
          margin: const EdgeInsets.all(space2),
        ),

        // Elevated button theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: textInverse,
            elevation: elevationSmall,
            padding: const EdgeInsets.symmetric(
              horizontal: space6,
              vertical: space3,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: borderRadiusMedium,
            ),
            textStyle: labelLarge,
          ),
        ),

        // Text button theme
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primary,
            padding: const EdgeInsets.symmetric(
              horizontal: space4,
              vertical: space2,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: borderRadiusSmall,
            ),
            textStyle: labelMedium,
          ),
        ),

        // Outlined button theme
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primary,
            side: const BorderSide(color: border, width: 1),
            padding: const EdgeInsets.symmetric(
              horizontal: space6,
              vertical: space3,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: borderRadiusMedium,
            ),
            textStyle: labelLarge,
          ),
        ),

        // Input decoration theme
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceHighlight,
          border: OutlineInputBorder(
            borderRadius: borderRadiusMedium,
            borderSide: const BorderSide(color: border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: borderRadiusMedium,
            borderSide: const BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: borderRadiusMedium,
            borderSide: const BorderSide(color: primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: borderRadiusMedium,
            borderSide: const BorderSide(color: error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: borderRadiusMedium,
            borderSide: const BorderSide(color: error, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: space4,
            vertical: space3,
          ),
          hintStyle: bodyMedium.copyWith(color: textTertiary),
          labelStyle: bodyMedium.copyWith(color: textSecondary),
        ),

        // Divider theme
        dividerTheme: const DividerThemeData(
          color: divider,
          thickness: 1,
          space: space1,
        ),

        // Icon theme
        iconTheme: const IconThemeData(
          color: textSecondary,
          size: 24,
        ),

        // Text theme
        textTheme: TextTheme(
          displayLarge: displayLarge.copyWith(color: textPrimary),
          displayMedium: displayMedium.copyWith(color: textPrimary),
          displaySmall: displaySmall.copyWith(color: textPrimary),
          headlineLarge: headlineLarge.copyWith(color: textPrimary),
          headlineMedium: headlineMedium.copyWith(color: textPrimary),
          headlineSmall: headlineSmall.copyWith(color: textPrimary),
          bodyLarge: bodyLarge.copyWith(color: textPrimary),
          bodyMedium: bodyMedium.copyWith(color: textSecondary),
          bodySmall: bodySmall.copyWith(color: textTertiary),
          labelLarge: labelLarge.copyWith(color: textPrimary),
          labelMedium: labelMedium.copyWith(color: textSecondary),
          labelSmall: labelSmall.copyWith(color: textTertiary),
        ),
      );

  /// Light theme (optional - for completeness)
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,

        colorScheme: const ColorScheme.light(
          primary: primaryDark,
          secondary: secondaryDark,
          surface: Color(0xFFFAFAFA),
          error: error,
          onPrimary: textInverse,
          onSecondary: textInverse,
          onSurface: Color(0xFF09090B),
          onError: textInverse,
        ),

        scaffoldBackgroundColor: const Color(0xFFFAFAFA),

        // Override specific light mode colors
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFAFAFA),
          foregroundColor: Color(0xFF09090B),
          elevation: elevationNone,
          centerTitle: true,
          titleSpacing: space4,
        ),

        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: elevationSmall,
          shape: RoundedRectangleBorder(
            borderRadius: borderRadiusMedium,
          ),
          margin: const EdgeInsets.all(space2),
        ),

        textTheme: TextTheme(
          displayLarge: displayLarge.copyWith(color: const Color(0xFF09090B)),
          displayMedium: displayMedium.copyWith(color: const Color(0xFF09090B)),
          displaySmall: displaySmall.copyWith(color: const Color(0xFF09090B)),
          headlineLarge: headlineLarge.copyWith(color: const Color(0xFF09090B)),
          headlineMedium:
              headlineMedium.copyWith(color: const Color(0xFF09090B)),
          headlineSmall: headlineSmall.copyWith(color: const Color(0xFF09090B)),
          bodyLarge: bodyLarge.copyWith(color: const Color(0xFF09090B)),
          bodyMedium: bodyMedium.copyWith(color: const Color(0xFF52525B)),
          bodySmall: bodySmall.copyWith(color: const Color(0xFF71717A)),
          labelLarge: labelLarge.copyWith(color: const Color(0xFF09090B)),
          labelMedium: labelMedium.copyWith(color: const Color(0xFF52525B)),
          labelSmall: labelSmall.copyWith(color: const Color(0xFF71717A)),
        ),
      );
}
