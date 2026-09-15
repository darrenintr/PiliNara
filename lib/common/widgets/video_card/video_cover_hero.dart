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
    this.flightChild,
  });

  static final Expando<String> _sourceTags = Expando<String>();
  static int _nextSourceId = 0;

  /// A stable, unique token for the mounted source model. A string keeps the
  /// route argument opaque to GetX while avoiding identity-only comparisons
  /// when the destination reads the tag from its arguments map.
  static String tagFor(Object source) =>
      _sourceTags[source] ??= 'video-cover-${++_nextSourceId}';

  final Object? tag;
  final String? cover;
  final Widget child;
  final BorderRadius sourceBorderRadius;
  final Widget? flightChild;

  @override
  Widget build(BuildContext context) {
    if (tag == null || cover?.isNotEmpty != true) return child;

    return Hero(
      tag: tag!,
      transitionOnUserGestures: true,
      flightShuttleBuilder:
          (_, animation, direction, fromHeroContext, toHeroContext) {
            // The cover visible in the source card is already decoded and
            // painted. Reusing that subtree avoids starting a second network
            // image load in the overlay (which made the Hero look absent on
            // a cold cache). On pop, `toHero` is the source card.
            final hero = (direction == HeroFlightDirection.push
                ? fromHeroContext
                : toHeroContext).widget as Hero;
            final heroChild = hero.child;
            final flightChild = heroChild is _VideoCoverHeroChild
                ? heroChild.flightChild
                : heroChild;
            return _VideoCoverFlight(
              animation: animation,
              child: flightChild,
              cover: cover!,
              sourceBorderRadius: sourceBorderRadius,
            );
          },
      child: _VideoCoverHeroChild(
        child: child,
        flightChild: flightChild ?? child,
      ),
    );
  }
}

/// Keeps the presentation widget separate from the live destination child.
/// The wrapper itself is intentionally transparent; it only carries the
/// already-painted cover that the flight shuttle should lift into the overlay.
class _VideoCoverHeroChild extends StatelessWidget {
  const _VideoCoverHeroChild({
    required this.child,
    required this.flightChild,
  });

  final Widget child;
  final Widget flightChild;

  @override
  Widget build(BuildContext context) => child;
}

class _VideoCoverFlight extends StatelessWidget {
  const _VideoCoverFlight({
    required this.animation,
    required this.child,
    required this.cover,
    required this.sourceBorderRadius,
  });

  final Animation<double> animation;
  final Widget child;
  final String cover;
  final BorderRadius sourceBorderRadius;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) => ClipRRect(
        borderRadius: BorderRadius.lerp(
          sourceBorderRadius,
          BorderRadius.zero,
          animation.value,
        )!,
        child: SizedBox.expand(
          child: child == null
              ? LayoutBuilder(
                  builder: (context, constraints) => NetworkImgLayer(
                    src: cover,
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    borderRadius: BorderRadius.zero,
                  ),
                )
              : FittedBox(
                  fit: BoxFit.cover,
                  child: child,
                ),
        ),
      ),
    );
  }
}
