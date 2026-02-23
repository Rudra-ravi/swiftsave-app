import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Premium modern theme with glassmorphism and neomorphism effects
/// Design philosophy: Bold blue, refined typography, powerful yet effortless
class SimpleTheme {
  // ============================================================================
  // COLOR PALETTE — Blue-dominant, confident, premium
  // ============================================================================

  // Primary blues
  static const primaryBlue = Color(0xFF2563EB); // Blue 600 — hero color
  static const primaryDeep = Color(0xFF1D4ED8); // Blue 700 — gradient end
  static const primaryLight = Color(0xFF3B82F6); // Blue 500 — hover/accent
  static const accentSky = Color(0xFF0EA5E9); // Sky 500 — secondary accent

  // Status colors
  static const successGreen = Color(0xFF10B981); // Emerald
  static const errorRed = Color(0xFFEF4444); // Red
  static const warningAmber = Color(0xFFF59E0B); // Amber

  // Neutral palette
  static const neutralGray = Color(0xFF64748B); // Slate 500
  static const neutralLight = Color(0xFF94A3B8); // Slate 400
  static const neutralMuted = Color(0xFFCBD5E1); // Slate 300

  // Background colors
  static const lightBackground = Color(0xFFF8FAFC); // Slate 50
  static const darkBackground = Color(0xFF0F172A); // Slate 900
  static const lightSurface = Color(0xFFFFFFFF);
  static const darkSurface = Color(0xFF1E293B); // Slate 800

  // Glass colors
  static const glassLight = Color(0x80FFFFFF);
  static const glassDark = Color(0x40000000);
  static const glassLightBorder = Color(0x40FFFFFF);
  static const glassDarkBorder = Color(0x20FFFFFF);

  // ============================================================================
  // GRADIENTS
  // ============================================================================

  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, primaryDeep],
  );

  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, accentSky],
  );

  static const successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF059669)],
  );

  static const errorGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
  );

  static const darkMeshGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F172A), Color(0xFF0C1A3D), Color(0xFF0F172A)],
    stops: [0.0, 0.5, 1.0],
  );

  static const lightMeshGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF8FAFC), Color(0xFFEFF6FF), Color(0xFFF8FAFC)],
    stops: [0.0, 0.5, 1.0],
  );

  // ============================================================================
  // TEXT STYLES — Distinctive typography pairing
  // Outfit for headings (geometric, bold), DM Sans for body (clean, readable)
  // ============================================================================

  /// Big headings — 28sp, bold with tight letter spacing
  static TextStyle heading(BuildContext context) => GoogleFonts.outfit(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: Theme.of(context).colorScheme.onSurface,
    height: 1.15,
    letterSpacing: -0.8,
  );

  /// Subheadings — 20sp, semibold
  static TextStyle subheading(BuildContext context, {Color? color}) =>
      GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: color ?? Theme.of(context).colorScheme.onSurface,
        height: 1.25,
        letterSpacing: -0.3,
      );

  /// Body text — 16sp, regular
  static TextStyle body(BuildContext context, {Color? color}) =>
      GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color:
            color ??
            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.87),
        height: 1.5,
      );

  /// Caption text — 14sp
  static TextStyle caption(BuildContext context, {Color? color}) =>
      GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color ?? neutralGray,
        height: 1.4,
      );

  /// Button text — 18sp, semibold
  static TextStyle button(BuildContext context, {Color? color}) =>
      GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: color ?? Colors.white,
        letterSpacing: 0.2,
      );

  /// Small label — 12sp, medium weight
  static TextStyle label(BuildContext context, {Color? color}) =>
      GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: color ?? neutralGray,
        letterSpacing: 0.3,
      );

  // ============================================================================
  // REUSABLE GRADIENT HEADING WIDGET
  // ============================================================================

  /// Gradient text heading — eliminates the ShaderMask boilerplate
  static Widget gradientHeading(
    BuildContext context, {
    required String text,
    double? fontSize,
    TextAlign? textAlign,
    Gradient? gradient,
  }) {
    return ShaderMask(
      shaderCallback: (bounds) =>
          (gradient ?? primaryGradient).createShader(bounds),
      child: Text(
        text,
        style: heading(context).copyWith(
          color: Colors.white,
          fontSize: fontSize ?? 28,
        ),
        textAlign: textAlign ?? TextAlign.center,
      ),
    );
  }

  // ============================================================================
  // GLASSMORPHISM EFFECTS
  // ============================================================================

  /// Glassmorphism card — frosted glass effect (use sparingly, not in lists)
  static Widget glassCard({
    required BuildContext context,
    required Widget child,
    EdgeInsetsGeometry? padding,
    double borderRadius = 20,
    double blur = 20,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: isDark ? glassDarkBorder : glassLightBorder,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  /// Solid glass-style decoration (no BackdropFilter — safe for lists)
  static BoxDecoration glassDecoration(
    BuildContext context, {
    double borderRadius = 20,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BoxDecoration(
      color: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.white.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: isDark ? glassDarkBorder : glassLightBorder,
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  // ============================================================================
  // NEOMORPHISM EFFECTS
  // ============================================================================

  /// Neomorphism raised card — soft 3D effect
  static BoxDecoration neoCard(
    BuildContext context, {
    double borderRadius = 20,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BoxDecoration(
      color: isDark ? darkSurface : lightSurface,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: isDark
          ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 15,
                offset: const Offset(5, 5),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.05),
                blurRadius: 15,
                offset: const Offset(-5, -5),
              ),
            ]
          : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 15,
                offset: const Offset(5, 5),
              ),
              const BoxShadow(
                color: Colors.white,
                blurRadius: 15,
                offset: Offset(-5, -5),
              ),
            ],
    );
  }

  /// Neomorphism pressed/inset effect
  static BoxDecoration neoInset(
    BuildContext context, {
    double borderRadius = 16,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BoxDecoration(
      color: isDark ? darkBackground : lightBackground,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: isDark
          ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(2, 2),
                spreadRadius: -2,
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(-2, -2),
                spreadRadius: -2,
              ),
            ]
          : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(2, 2),
                spreadRadius: -2,
              ),
              const BoxShadow(
                color: Colors.white,
                blurRadius: 10,
                offset: Offset(-2, -2),
                spreadRadius: -2,
              ),
            ],
    );
  }

  // ============================================================================
  // BUTTON DECORATIONS
  // ============================================================================

  /// Primary gradient button
  static BoxDecoration primaryButton({bool disabled = false}) => BoxDecoration(
    gradient: disabled ? null : primaryGradient,
    color: disabled ? neutralGray.withValues(alpha: 0.5) : null,
    borderRadius: BorderRadius.circular(16),
    boxShadow: disabled
        ? null
        : [
            BoxShadow(
              color: primaryBlue.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
  );

  /// Success gradient button
  static BoxDecoration successButton() => BoxDecoration(
    gradient: successGradient,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: successGreen.withValues(alpha: 0.4),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  );

  /// Error gradient button
  static BoxDecoration errorButton() => BoxDecoration(
    gradient: errorGradient,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: errorRed.withValues(alpha: 0.4),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  );

  // ============================================================================
  // LEGACY SUPPORT — simpleCard maps to neoCard
  // ============================================================================

  /// Simple card — now uses neomorphism
  static BoxDecoration simpleCard(BuildContext context) {
    return neoCard(context);
  }

  /// Simple input field with glass effect
  static InputDecoration simpleInput({
    required BuildContext context,
    required String hint,
    Widget? suffixIcon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      hintText: hint,
      hintStyle: body(context, color: neutralLight),
      filled: true,
      fillColor: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.white.withValues(alpha: 0.8),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: isDark ? glassDarkBorder : glassLightBorder,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: isDark ? glassDarkBorder : glassLightBorder,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryBlue, width: 2),
      ),
    );
  }

  // ============================================================================
  // THEME DATA — Premium blue-first themes
  // ============================================================================

  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        secondary: accentSky,
        tertiary: primaryLight,
        error: errorRed,
        surface: lightSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFF0F172A),
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: lightBackground,
      cardColor: lightSurface,

      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF0F172A),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF0F172A),
        ),
      ),

      textTheme: TextTheme(
        headlineLarge: GoogleFonts.outfit(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF0F172A),
          letterSpacing: -0.8,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF0F172A),
        ),
        bodyLarge: GoogleFonts.dmSans(
          fontSize: 16,
          color: const Color(0xFF334155),
        ),
        bodyMedium: GoogleFonts.dmSans(fontSize: 14, color: neutralGray),
        labelMedium: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: neutralGray,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return neutralGray;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryBlue;
          }
          return neutralLight.withValues(alpha: 0.3);
        }),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: primaryBlue,
        inactiveTrackColor: neutralLight.withValues(alpha: 0.3),
        thumbColor: primaryBlue,
        overlayColor: primaryBlue.withValues(alpha: 0.2),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkSurface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      chipTheme: ChipThemeData(
        selectedColor: primaryBlue.withValues(alpha: 0.15),
        backgroundColor: Colors.white.withValues(alpha: 0.55),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
        labelStyle: GoogleFonts.dmSans(fontSize: 14),
      ),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryBlue,
        secondary: accentSky,
        tertiary: primaryLight,
        error: errorRed,
        surface: darkSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFFF1F5F9),
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: darkBackground,
      cardColor: darkSurface,

      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFFF1F5F9),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFF1F5F9),
        ),
      ),

      textTheme: TextTheme(
        headlineLarge: GoogleFonts.outfit(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: const Color(0xFFF1F5F9),
          letterSpacing: -0.8,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFF1F5F9),
        ),
        bodyLarge: GoogleFonts.dmSans(
          fontSize: 16,
          color: const Color(0xFFE2E8F0),
        ),
        bodyMedium: GoogleFonts.dmSans(fontSize: 14, color: neutralLight),
        labelMedium: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: neutralLight,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return neutralLight;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryBlue;
          }
          return neutralGray.withValues(alpha: 0.3);
        }),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: primaryBlue,
        inactiveTrackColor: neutralGray.withValues(alpha: 0.3),
        thumbColor: primaryBlue,
        overlayColor: primaryBlue.withValues(alpha: 0.2),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF334155),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      chipTheme: ChipThemeData(
        selectedColor: primaryBlue.withValues(alpha: 0.2),
        backgroundColor: Colors.white.withValues(alpha: 0.08),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        labelStyle: GoogleFonts.dmSans(fontSize: 14),
      ),
    );
  }
}
