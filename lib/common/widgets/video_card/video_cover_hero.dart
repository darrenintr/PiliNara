import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:flutter/material.dart';

/// A cover-only shared element used by video cards and the player viewport.
///
/// The live player remains in the destination route. Only a poster is painted
/// in the Hero overlay, so player lifecycle and page transitions are unchanged.
class VideoCoverHero extends StatelessWidget {
  const VideoCoverHero({
    super.key,
    required this.tag,
    required this.cover,
    required this.child,
    this.sourceBorderRadius = BorderRadius.zero,
  });

  static final Expando<Object> _sourceTags = Expando<Object>();

  static Object tagFor(Object source) => _sourceTags[source] ??= Object();

  final Object? tag;
  final String? cover;
  final Widget child;
  final BorderRadius sourceBorderRadius;

  @override
  Widget build(BuildContext context) {
    if (tag == null || cover?.isNotEmpty != true) return child;

    return Hero(
      tag: tag!,
      transitionOnUserGestures: true,
      flightShuttleBuilder: (_, animation, _, _, _) => _VideoCoverFlight(
        animation: animation,
        cover: cover!,
        sourceBorderRadius: sourceBorderRadius,
      ),
      child: child,
    );
  }
}

class _VideoCoverFlight extends StatelessWidget {
  const _VideoCoverFlight({
    required this.animation,
    required this.cover,
    required this.sourceBorderRadius,
  });

  final Animation<double> animation;
  final String cover;
  final BorderRadius sourceBorderRadius;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) => ClipRRect(
        borderRadius: BorderRadius.lerp(
          sourceBorderRadius,
          BorderRadius.zero,
          animation.value,
        )!,
        child: LayoutBuilder(
          builder: (context, constraints) => NetworkImgLayer(
            src: cover,
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            borderRadius: BorderRadius.zero,
          ),
        ),
      ),
    );
  }
}
