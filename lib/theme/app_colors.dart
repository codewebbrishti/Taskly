import 'package:flutter/material.dart';

/// Brand colors — the same in light and dark mode.
class AppColors {
  static const blue = Color(0xFF5B67F5);
  static const red = Color(0xFFE5486E);
  static const amber = Color(0xFFF2B33D);
  static const green = Color(0xFF2FBF8F);
}

/// Colors that change between light and dark mode.
class Palette {
  const Palette({
    required this.bg,
    required this.surface,
    required this.ink,
    required this.muted,
    required this.field,
    required this.border,
    required this.pastels,
  });

  final Color bg;
  final Color surface;
  final Color ink;
  final Color muted;
  final Color field;
  final Color border;
  final List<Color> pastels;

  static const light = Palette(
    bg: Color(0xFFF7F8FC),
    surface: Colors.white,
    ink: Color(0xFF1F1F4D),
    muted: Color(0xFF9A9BB0),
    field: Color(0xFFF1F2F6),
    border: Color(0xFFF0F0F6),
    pastels: [
      Color(0xFFE9EBFF), // lavender
      Color(0xFFFFF5D6), // butter
      Color(0xFFE5F9F0), // mint
      Color(0xFFFDE7EC), // blush
    ],
  );

  static const dark = Palette(
    bg: Color(0xFF12131A),
    surface: Color(0xFF1C1D27),
    ink: Color(0xFFF1F2FA),
    muted: Color(0xFF8E90A6),
    field: Color(0xFF242633),
    border: Color(0xFF2C2E3D),
    pastels: [
      Color(0xFF262A4D),
      Color(0xFF3A3322),
      Color(0xFF1F3A33),
      Color(0xFF3D2430),
    ],
  );
}

extension PaletteContext on BuildContext {
  /// Use `context.pal.ink`, `context.pal.surface`, etc.
  Palette get pal => Theme.of(this).brightness == Brightness.dark
      ? Palette.dark
      : Palette.light;
}
