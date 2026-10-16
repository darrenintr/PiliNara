import 'package:material_ui/material_ui.dart';

/// Colour tokens of the "PiliNara · Material 3 Expressive" design.
abstract final class ExpressiveColors {
  static const seed = Color(0xFFA3365F);

  static const light = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFFA3365F),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFFFD9E2),
    onPrimaryContainer: Color(0xFF3F001B),
    secondary: Color(0xFF75565E),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFFFD9E1),
    onSecondaryContainer: Color(0xFF2B151B),
    tertiary: Color(0xFF8A5100),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFFFDCBE),
    onTertiaryContainer: Color(0xFF2C1600),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF93000A),
    surface: Color(0xFFFFF8F8),
    onSurface: Color(0xFF22191B),
    surfaceDim: Color(0xFFE7D6D8),
    surfaceBright: Color(0xFFFFF8F8),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFFFF0F2),
    surfaceContainer: Color(0xFFFBEAEC),
    surfaceContainerHigh: Color(0xFFF5E4E6),
    surfaceContainerHighest: Color(0xFFEFDEE1),
    onSurfaceVariant: Color(0xFF524345),
    outline: Color(0xFF847375),
    outlineVariant: Color(0xFFD6C1C4),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF382E30),
    onInverseSurface: Color(0xFFFDEDEF),
    inversePrimary: Color(0xFFFFB1C6),
    surfaceTint: Color(0xFFA3365F),
  );

  static const dark = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFFFB1C6),
    onPrimary: Color(0xFF650030),
    primaryContainer: Color(0xFF84204A),
    onPrimaryContainer: Color(0xFFFFD9E2),
    secondary: Color(0xFFE2BDC6),
    onSecondary: Color(0xFF422930),
    secondaryContainer: Color(0xFF5B3F46),
    onSecondaryContainer: Color(0xFFFFD9E1),
    tertiary: Color(0xFFFFB870),
    onTertiary: Color(0xFF4A2800),
    tertiaryContainer: Color(0xFF693C00),
    onTertiaryContainer: Color(0xFFFFDCBE),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF191113),
    onSurface: Color(0xFFEFDFE1),
    surfaceDim: Color(0xFF191113),
    surfaceBright: Color(0xFF413738),
    surfaceContainerLowest: Color(0xFF140C0E),
    surfaceContainerLow: Color(0xFF22191B),
    surfaceContainer: Color(0xFF261D1F),
    surfaceContainerHigh: Color(0xFF31282A),
    surfaceContainerHighest: Color(0xFF3C3234),
    onSurfaceVariant: Color(0xFFD6C1C4),
    outline: Color(0xFF9F8C8F),
    outlineVariant: Color(0xFF524345),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFEFDFE1),
    onInverseSurface: Color(0xFF382E30),
    inversePrimary: Color(0xFFA3365F),
    surfaceTint: Color(0xFFFFB1C6),
  );

  /// Scrim behind text on thumbnails (stat pills, duration).
  static const thumbScrim = Color(0xB822191B);

  /// Player background.
  static const playerSurface = Color(0xFF140E10);
}

/// A tonal accent used to tint thumbnails, shortcut tiles and avatars.
class ExpressiveAccent {
  const ExpressiveAccent({
    required this.container,
    required this.decoration,
    required this.onContainer,
  });

  final Color container;
  final Color decoration;
  final Color onContainer;

  static const _light = [
    ExpressiveAccent(
      container: Color(0xFFFFD9E2),
      decoration: Color(0xFFFFB1C6),
      onContainer: Color(0xFF3F001B),
    ),
    ExpressiveAccent(
      container: Color(0xFFFFDCBE),
      decoration: Color(0xFFFFB870),
      onContainer: Color(0xFF2C1600),
    ),
    ExpressiveAccent(
      container: Color(0xFFE9DDFF),
      decoration: Color(0xFFD0BCFF),
      onContainer: Color(0xFF22005D),
    ),
    ExpressiveAccent(
      container: Color(0xFFC2EFD6),
      decoration: Color(0xFF8CD5B0),
      onContainer: Color(0xFF002113),
    ),
    ExpressiveAccent(
      container: Color(0xFFD3E3FD),
      decoration: Color(0xFFA8C7FA),
      onContainer: Color(0xFF041E49),
    ),
  ];

  static const _dark = [
    ExpressiveAccent(
      container: Color(0xFF84204A),
      decoration: Color(0xFF9E3A62),
      onContainer: Color(0xFFFFD9E2),
    ),
    ExpressiveAccent(
      container: Color(0xFF693C00),
      decoration: Color(0xFF8A5100),
      onContainer: Color(0xFFFFDCBE),
    ),
    ExpressiveAccent(
      container: Color(0xFF4F378B),
      decoration: Color(0xFF6750A4),
      onContainer: Color(0xFFE9DDFF),
    ),
    ExpressiveAccent(
      container: Color(0xFF005234),
      decoration: Color(0xFF006C47),
      onContainer: Color(0xFFC2EFD6),
    ),
    ExpressiveAccent(
      container: Color(0xFF0842A0),
      decoration: Color(0xFF1B5FC1),
      onContainer: Color(0xFFD3E3FD),
    ),
  ];

  static int get length => _light.length;

  /// Picks an accent deterministically, e.g. by list index or id hash.
  static ExpressiveAccent of(int index, Brightness brightness) {
    final list = brightness == Brightness.dark ? _dark : _light;
    return list[index.abs() % list.length];
  }
}
