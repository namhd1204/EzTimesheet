import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Design Tokens - Easy access to design system values
/// Provides convenient access to all design system constants
class DesignTokens {
  DesignTokens._();

  // ============================================
  // COLOR TOKENS
  // ============================================

  // Primary colors
  static Color get primary => AppTheme.primary;
  static Color get primaryLight => AppTheme.primaryLight;
  static Color get primaryDark => AppTheme.primaryDark;

  // Secondary colors
  static Color get secondary => AppTheme.secondary;
  static Color get secondaryLight => AppTheme.secondaryLight;
  static Color get secondaryDark => AppTheme.secondaryDark;

  // Surface colors
  static Color get surface => AppTheme.surface;
  static Color get surfaceElevated => AppTheme.surfaceElevated;
  static Color get surfaceHighlight => AppTheme.surfaceHighlight;
  static Color get surfaceSubtle => AppTheme.surfaceSubtle;

  // Error colors
  static Color get error => AppTheme.error;
  static Color get errorLight => AppTheme.errorLight;
  static Color get errorDark => AppTheme.errorDark;

  // Text colors
  static Color get textPrimary => AppTheme.textPrimary;
  static Color get textSecondary => AppTheme.textSecondary;
  static Color get textTertiary => AppTheme.textTertiary;
  static Color get textInverse => AppTheme.textInverse;

  // Border and divider colors
  static Color get border => AppTheme.border;
  static Color get borderSubtle => AppTheme.borderSubtle;
  static Color get divider => AppTheme.divider;

  // Overlay colors
  static Color get overlay => AppTheme.overlay;
  static Color get overlayLight => AppTheme.overlayLight;

  // ============================================
  // TYPOGRAPHY TOKENS
  // ============================================

  // Display typography
  static TextStyle get displayLarge => AppTheme.displayLarge;
  static TextStyle get displayMedium => AppTheme.displayMedium;
  static TextStyle get displaySmall => AppTheme.displaySmall;

  // Headline typography
  static TextStyle get headlineLarge => AppTheme.headlineLarge;
  static TextStyle get headlineMedium => AppTheme.headlineMedium;
  static TextStyle get headlineSmall => AppTheme.headlineSmall;

  // Body typography
  static TextStyle get bodyLarge => AppTheme.bodyLarge;
  static TextStyle get bodyMedium => AppTheme.bodyMedium;
  static TextStyle get bodySmall => AppTheme.bodySmall;

  // Label typography
  static TextStyle get labelLarge => AppTheme.labelLarge;
  static TextStyle get labelMedium => AppTheme.labelMedium;
  static TextStyle get labelSmall => AppTheme.labelSmall;

  // ============================================
  // SPACING TOKENS
  // ============================================

  static double get space0 => AppTheme.space0;
  static double get space1 => AppTheme.space1;
  static double get space2 => AppTheme.space2;
  static double get space3 => AppTheme.space3;
  static double get space4 => AppTheme.space4;
  static double get space5 => AppTheme.space5;
  static double get space6 => AppTheme.space6;
  static double get space8 => AppTheme.space8;
  static double get space10 => AppTheme.space10;
  static double get space12 => AppTheme.space12;
  static double get space16 => AppTheme.space16;
  static double get space20 => AppTheme.space20;
  static double get space24 => AppTheme.space24;

  // Padding helpers
  static EdgeInsets get paddingAll => AppTheme.paddingAll;
  static EdgeInsets get paddingSmall => AppTheme.paddingSmall;
  static EdgeInsets get paddingMedium => AppTheme.paddingMedium;
  static EdgeInsets get paddingLarge => AppTheme.paddingLarge;
  static EdgeInsets get paddingHorizontal => AppTheme.paddingHorizontal;
  static EdgeInsets get paddingVertical => AppTheme.paddingVertical;

  // ============================================
  // BORDER RADIUS TOKENS
  // ============================================

  static double get radiusNone => AppTheme.radiusNone;
  static double get radiusSmall => AppTheme.radiusSmall;
  static double get radiusMedium => AppTheme.radiusMedium;
  static double get radiusLarge => AppTheme.radiusLarge;
  static double get radiusXLarge => AppTheme.radiusXLarge;
  static double get radiusFull => AppTheme.radiusFull;

  // Border radius helpers
  static BorderRadius get borderRadiusSmall => AppTheme.borderRadiusSmall;
  static BorderRadius get borderRadiusMedium => AppTheme.borderRadiusMedium;
  static BorderRadius get borderRadiusLarge => AppTheme.borderRadiusLarge;
  static BorderRadius get borderRadiusXLarge => AppTheme.borderRadiusXLarge;

  // ============================================
  // ELEVATION TOKENS
  // ============================================

  static double get elevationNone => AppTheme.elevationNone;
  static double get elevationSmall => AppTheme.elevationSmall;
  static double get elevationMedium => AppTheme.elevationMedium;
  static double get elevationLarge => AppTheme.elevationLarge;
  static double get elevationXLarge => AppTheme.elevationXLarge;

  // ============================================
  // THEME ACCESS
  // ============================================

  static ThemeData get darkTheme => AppTheme.darkTheme;
  static ThemeData get lightTheme => AppTheme.lightTheme;

  // ============================================
  // UTILITY METHODS
  // ============================================

  /// Get text color based on background luminance
  static Color getContrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  /// Create custom spacing
  static EdgeInsets spacing({
    double? all,
    double? horizontal,
    double? vertical,
    double? top,
    double? bottom,
    double? left,
    double? right,
  }) {
    return EdgeInsets.only(
      top: top ?? vertical ?? all ?? 0,
      bottom: bottom ?? vertical ?? all ?? 0,
      left: left ?? horizontal ?? all ?? 0,
      right: right ?? horizontal ?? all ?? 0,
    );
  }

  /// Create custom border radius
  static BorderRadius radius({
    double? all,
    double? topLeft,
    double? topRight,
    double? bottomLeft,
    double? bottomRight,
  }) {
    return BorderRadius.only(
      topLeft: Radius.circular(topLeft ?? all ?? 0),
      topRight: Radius.circular(topRight ?? all ?? 0),
      bottomLeft: Radius.circular(bottomLeft ?? all ?? 0),
      bottomRight: Radius.circular(bottomRight ?? all ?? 0),
    );
  }
}

/// Extension methods for easy access to design tokens
extension DesignTokensExtension on BuildContext {
  /// Get current theme
  ThemeData get theme => Theme.of(this);

  /// Get current color scheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Get current text theme
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Check if dark mode
  bool get isDarkMode => theme.brightness == Brightness.dark;
}