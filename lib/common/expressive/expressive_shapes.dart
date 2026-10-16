import 'package:material_ui/material_ui.dart';

/// The Material 3 Expressive shape set used across the design
/// (avatars, rank badges, decorative blobs on hero cards and thumbnails).
enum ExpressiveShape {
  cookie9(_cookie9),
  clover4(_clover4),
  sunny8(_sunny8),
  flower6(_flower6)
  ;

  const ExpressiveShape(this._points);

  /// Outline in a 100×100 box as x,y pairs.
  final List<double> _points;

  static ExpressiveShape of(int index) => values[index.abs() % values.length];

  Path pathFor(Rect rect) {
    final sx = rect.width / 100;
    final sy = rect.height / 100;
    final path = Path()
      ..moveTo(rect.left + _points[0] * sx, rect.top + _points[1] * sy);
    for (var i = 2; i < _points.length; i += 2) {
      path.lineTo(rect.left + _points[i] * sx, rect.top + _points[i + 1] * sy);
    }
    return path..close();
  }

  OutlinedBorder get border => ExpressiveShapeBorder(this);

  static const _cookie9 = <double>[100, 50, 98, 54, 94, 58, 90, 61, 88, 64, 88, 68, 89, 72, 89, 78, 88, 82, 84, 84, 79, 84, 74, 84, 70, 85, 68, 88, 65, 92, 62, 97, 59, 99, 54, 98, 50, 95, 46, 92, 43, 90, 39, 90, 35, 92, 30, 94, 25, 93, 22, 89, 21, 84, 20, 80, 19, 76, 16, 74, 11, 72, 6, 70, 3, 67, 3, 62, 6, 58, 8, 54, 10, 50, 8, 46, 6, 42, 3, 38, 3, 33, 6, 30, 11, 27, 16, 26, 19, 24, 20, 20, 21, 16, 22, 11, 25, 7, 30, 6, 35, 8, 39, 10, 43, 10, 46, 8, 50, 5, 54, 2, 59, 1, 62, 3, 65, 8, 68, 12, 70, 15, 74, 16, 79, 16, 84, 16, 88, 18, 89, 22, 89, 28, 88, 32, 88, 36, 90, 39, 94, 42, 98, 46];
  static const _clover4 = <double>[77, 50, 78, 52, 79, 55, 81, 58, 84, 62, 86, 67, 88, 72, 88, 77, 87, 81, 85, 85, 81, 87, 77, 88, 72, 88, 67, 86, 62, 84, 58, 81, 55, 79, 52, 78, 50, 77, 48, 78, 45, 79, 42, 81, 38, 84, 33, 86, 28, 88, 23, 88, 19, 87, 15, 85, 13, 81, 12, 77, 12, 72, 14, 67, 16, 62, 19, 58, 21, 55, 22, 52, 23, 50, 22, 48, 21, 45, 19, 42, 16, 38, 14, 33, 12, 28, 12, 23, 13, 19, 15, 15, 19, 13, 23, 12, 28, 12, 33, 14, 38, 16, 42, 19, 45, 21, 48, 22, 50, 23, 52, 22, 55, 21, 58, 19, 62, 16, 67, 14, 72, 12, 77, 12, 81, 13, 85, 15, 87, 19, 88, 23, 88, 28, 86, 33, 84, 38, 81, 42, 79, 45, 78, 48];
  static const _sunny8 = <double>[100, 50, 98, 54, 96, 58, 93, 61, 90, 65, 89, 68, 88, 72, 88, 77, 87, 81, 85, 85, 81, 87, 77, 88, 72, 88, 68, 89, 65, 90, 61, 93, 58, 96, 54, 98, 50, 100, 46, 98, 42, 96, 39, 93, 35, 90, 32, 89, 28, 88, 23, 88, 19, 87, 15, 85, 13, 81, 12, 77, 12, 72, 11, 68, 10, 65, 7, 61, 4, 58, 2, 54, 0, 50, 2, 46, 4, 42, 7, 39, 10, 35, 11, 32, 12, 28, 12, 23, 13, 19, 15, 15, 19, 13, 23, 12, 28, 12, 32, 11, 35, 10, 39, 7, 42, 4, 46, 2, 50, 0, 54, 2, 58, 4, 61, 7, 65, 10, 68, 11, 72, 12, 77, 12, 81, 13, 85, 15, 87, 19, 88, 23, 88, 28, 89, 32, 90, 35, 93, 39, 96, 42, 98, 46];
  static const _flower6 = <double>[99, 50, 98, 54, 95, 58, 91, 61, 86, 63, 83, 65, 80, 68, 79, 71, 79, 75, 80, 80, 79, 85, 78, 89, 74, 92, 70, 94, 66, 93, 61, 91, 57, 88, 53, 86, 50, 85, 47, 86, 43, 88, 39, 91, 34, 93, 30, 94, 26, 92, 22, 89, 21, 85, 20, 80, 21, 75, 21, 71, 20, 68, 17, 65, 14, 63, 9, 61, 5, 58, 2, 54, 1, 50, 2, 46, 5, 42, 9, 39, 14, 37, 17, 35, 20, 32, 21, 29, 21, 25, 20, 20, 21, 15, 22, 11, 25, 8, 30, 6, 34, 7, 39, 9, 43, 12, 47, 14, 50, 15, 53, 14, 57, 12, 61, 9, 66, 7, 70, 6, 74, 8, 78, 11, 79, 15, 80, 20, 79, 25, 79, 29, 80, 33, 83, 35, 86, 37, 91, 39, 95, 42, 98, 46];
}

class ExpressiveShapeBorder extends OutlinedBorder {
  const ExpressiveShapeBorder(this.shape, {super.side});

  final ExpressiveShape shape;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      shape.pathFor(rect.deflate(side.strokeInset));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      shape.pathFor(rect);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none) return;
    canvas.drawPath(
      shape.pathFor(rect.inflate(side.strokeOffset / 2)),
      side.toPaint(),
    );
  }

  @override
  ShapeBorder scale(double t) =>
      ExpressiveShapeBorder(shape, side: side.scale(t));

  @override
  ExpressiveShapeBorder copyWith({BorderSide? side}) =>
      ExpressiveShapeBorder(shape, side: side ?? this.side);

  @override
  bool operator ==(Object other) =>
      other is ExpressiveShapeBorder &&
      other.shape == shape &&
      other.side == side;

  @override
  int get hashCode => Object.hash(shape, side);
}

/// A filled expressive shape, optionally with a centred child
/// (an icon, a rank number or an initial).
class ShapeBlob extends StatelessWidget {
  const ShapeBlob({
    super.key,
    required this.shape,
    required this.color,
    required this.size,
    this.child,
  });

  final ExpressiveShape shape;
  final Color color;
  final double size;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: ShapeDecoration(color: color, shape: shape.border),
        child: child == null ? null : Center(child: child),
      ),
    );
  }
}

/// Decorative oversized blob peeking from a corner of a card or thumbnail.
class CornerBlob extends StatelessWidget {
  const CornerBlob({
    super.key,
    required this.shape,
    required this.color,
    required this.size,
    this.left,
    this.top,
    this.right,
    this.bottom,
  });

  final ExpressiveShape shape;
  final Color color;
  final double size;
  final double? left;
  final double? top;
  final double? right;
  final double? bottom;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      child: IgnorePointer(
        child: ExcludeSemantics(
          child: ShapeBlob(shape: shape, color: color, size: size),
        ),
      ),
    );
  }
}
