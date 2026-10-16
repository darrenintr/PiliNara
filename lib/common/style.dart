import 'package:material_ui/material_ui.dart'
    show BorderRadius, Radius, BoxConstraints, ButtonStyle, VisualDensity;

abstract final class Style {
  static const cardSpace = 8.0;
  static const safeSpace = 12.0;
  static const mdRadius = BorderRadius.all(imgRadius);
  static const imgRadius = Radius.circular(18);

  // Material 3 Expressive corner scale.
  static const radiusXs = 8.0;
  static const radiusSm = 12.0;
  static const radiusMd = 16.0;
  static const radiusLg = 20.0;
  static const radiusXl = 24.0;
  static const radiusXxl = 28.0;
  static const radiusHero = 32.0;
  static const cardRadius = BorderRadius.all(Radius.circular(radiusXxl));

  /// Corners of a connected button group: outer ends round, inner joins tight.
  static BorderRadius connectedRadius({
    required bool first,
    required bool last,
    double outer = 22,
    double inner = 8,
  }) => BorderRadius.horizontal(
    left: Radius.circular(first ? outer : inner),
    right: Radius.circular(last ? outer : inner),
  );

  static const aspectRatio = 16 / 10;
  static const aspectRatio16x9 = 16 / 9;
  static const imgMaxRatio = 2.6;
  static const bottomSheetRadius = BorderRadius.vertical(top: .circular(28));
  static const dialogFixedConstraints = BoxConstraints.tightFor(width: 420);
  static const topBarHeight = 64.0;
  static const buttonStyle = ButtonStyle(
    visualDensity: VisualDensity(horizontal: -2, vertical: -1.25),
    tapTargetSize: .shrinkWrap,
  );
  static const placeHolder = '\uFFFC';
}
