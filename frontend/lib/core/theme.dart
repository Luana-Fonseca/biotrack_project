import 'package:flutter/material.dart';

/// Brand accent colors — identical in light and dark mode (only surfaces and
/// text swap between themes; buttons, links and highlights stay consistent).
class AppColors {
  static const azul = Color(0xFF1E3A8A);
  static const azulDark = Color(0xFF14286A);
  static const verde = Color(0xFF00D084);
  static const verdeDark = Color(0xFF059669);
  static const red = Color(0xFFEF4444);

  // Light-theme surface/text defaults — kept for the few call sites (PDF-style
  // brand assets, splash screen) that always render on a fixed light/blue
  // background regardless of the user's theme choice.
  static const bg = Color(0xFFF7F9FC);
  static const ink = Color(0xFF1E293B);
  static const gray = Color(0xFF64748B);
  static const gray2 = Color(0xFF94A3B8);
  static const gray3 = Color(0xFFCBD5E1);
  static const border = Color(0xFFE2E8F0);
  static const divider = Color(0xFFCBD5E1);
}

/// The set of surface/text colors every screen reads instead of [AppColors]'
/// light-only fields, so the whole app (not just one screen) flips with the
/// dark-mode toggle. Use `context.palette` to get the right instance.
class AppPalette {
  final Color bg;
  final Color card;
  final Color ink;
  final Color gray;
  final Color gray2;
  final Color gray3;
  final Color border;
  final Color divider;
  final Brightness brightness;

  const AppPalette({
    required this.bg,
    required this.card,
    required this.ink,
    required this.gray,
    required this.gray2,
    required this.gray3,
    required this.border,
    required this.divider,
    required this.brightness,
  });

  static const light = AppPalette(
    bg: Color(0xFFF7F9FC),
    card: Colors.white,
    ink: Color(0xFF1E293B),
    gray: Color(0xFF64748B),
    gray2: Color(0xFF94A3B8),
    gray3: Color(0xFFCBD5E1),
    border: Color(0xFFE2E8F0),
    divider: Color(0xFFCBD5E1),
    brightness: Brightness.light,
  );

  static const dark = AppPalette(
    bg: Color(0xFF0B1220),
    card: Color(0xFF1A2436),
    ink: Color(0xFFF1F5F9),
    gray: Color(0xFF94A3B8),
    gray2: Color(0xFF64748B),
    gray3: Color(0xFF334155),
    border: Color(0xFF2A3647),
    divider: Color(0xFF2A3647),
    brightness: Brightness.dark,
  );
}

extension PaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).brightness == Brightness.dark ? AppPalette.dark : AppPalette.light;
}

/// Inter and JetBrains Mono are bundled as local variable-font assets
/// (see pubspec.yaml `fonts:` and assets/fonts/) instead of fetched at
/// build time via the `google_fonts` package — that package's internal
/// `Map<FontWeight, String>` constant breaks compilation on some Dart SDK
/// versions ("does not have a primitive operator '=='"), and bundling
/// avoids the runtime dependency on Google Fonts' CDN entirely.
class AppText {
  static TextStyle inter({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.ink,
    double? letterSpacing,
    double? height,
  }) =>
      TextStyle(
        fontFamily: 'Inter',
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );

  static TextStyle mono({
    double size = 12,
    FontWeight weight = FontWeight.w600,
    Color color = AppColors.ink,
    double? letterSpacing,
  }) =>
      TextStyle(
        fontFamily: 'JetBrainsMono',
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
      );
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppPalette.light.bg,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.azul),
    fontFamily: 'Inter',
  );
}

ThemeData buildAppDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppPalette.dark.bg,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.azul, brightness: Brightness.dark),
    fontFamily: 'Inter',
  );
}
