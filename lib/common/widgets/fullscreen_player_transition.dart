import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4;

/// Animates the same player surface between its inline and fullscreen bounds.
///
/// Unlike a route [Hero], this widget stays on the current route. The render
/// object remembers the player's last painted global bounds and applies a FLIP
/// transform when [isFullscreen] changes. This keeps the real player (texture,
/// controls and danmaku included) alive for the whole transition.
class FullscreenPlayerTransition extends StatefulWidget {
  const FullscreenPlayerTransition({
    super.key,
    required this.isFullscreen,
    required this.child,
    this.enabled = true,
    this.duration = const Duration(milliseconds: 350),
    this.curve = const Cubic(0.2, 0, 0, 1),
  });

  final bool isFullscreen;
  final Widget child;
  final bool enabled;
  final Duration duration;
  final Curve curve;

  @override
  State<FullscreenPlayerTransition> createState() =>
      _FullscreenPlayerTransitionState();
}

class _FullscreenPlayerTransitionState
    extends State<FullscreenPlayerTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
    value: 1,
  );

  @override
  void didUpdateWidget(FullscreenPlayerTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    if (oldWidget.isFullscreen != widget.isFullscreen && widget.enabled) {
      _controller.forward(from: 0);
    } else if (!widget.enabled) {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _FullscreenPlayerTransform(
    isFullscreen: widget.isFullscreen,
    progress: _controller,
    curve: widget.curve,
    child: widget.child,
  );
}

class _FullscreenPlayerTransform extends SingleChildRenderObjectWidget {
  const _FullscreenPlayerTransform({
    required this.isFullscreen,
    required this.progress,
    required this.curve,
    required super.child,
  });

  final bool isFullscreen;
  final Animation<double> progress;
  final Curve curve;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderFullscreenPlayerTransform(
        isFullscreen: isFullscreen,
        progress: progress,
        curve: curve,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderFullscreenPlayerTransform renderObject,
  ) {
    renderObject
      ..isFullscreen = isFullscreen
      ..progress = progress
      ..curve = curve;
  }
}

class _RenderFullscreenPlayerTransform extends RenderProxyBox {
  _RenderFullscreenPlayerTransform({
    required bool isFullscreen,
    required Animation<double> progress,
    required Curve curve,
  }) : _isFullscreen = isFullscreen,
       _progress = progress,
       _curve = curve;

  bool _isFullscreen;
  bool? _paintedFullscreen;
  Animation<double> _progress;
  Curve _curve;
  Rect? _lastLayoutRect;
  Rect? _fromRect;
  Rect? _visualRect;
  Matrix4? _paintTransform;

  set isFullscreen(bool value) {
    if (_isFullscreen == value) return;
    _isFullscreen = value;
    markNeedsPaint();
  }

  set progress(Animation<double> value) {
    if (identical(_progress, value)) return;
    if (attached) _progress.removeListener(markNeedsPaint);
    _progress = value;
    if (attached) _progress.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  set curve(Curve value) {
    if (_curve == value) return;
    _curve = value;
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _progress.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _progress.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null || size.isEmpty) return;

    final currentRect = MatrixUtils.transformRect(
      getTransformTo(null),
      Offset.zero & size,
    );
    final fullscreenChanged =
        _paintedFullscreen != null && _paintedFullscreen != _isFullscreen;
    if (fullscreenChanged) {
      // If a second toggle arrives mid-flight, continue from the currently
      // visible rectangle instead of jumping to the previous destination.
      _fromRect = _visualRect ?? _lastLayoutRect ?? currentRect;
    }
    _paintedFullscreen = _isFullscreen;

    final isAnimating = _progress.value < 1 && _fromRect != null;
    final visualRect = isAnimating
        ? Rect.lerp(
            _fromRect,
            currentRect,
            _curve.transform(
              _progress.value.clamp(0.0, 1.0).toDouble(),
            ),
          )!
        : currentRect;
    _visualRect = visualRect;
    _lastLayoutRect = currentRect;
    if (!isAnimating) _fromRect = null;

    final scaleX = visualRect.width / currentRect.width;
    final scaleY = visualRect.height / currentRect.height;
    final transform = Matrix4.identity()
      ..translateByDouble(
        visualRect.left - currentRect.left,
        visualRect.top - currentRect.top,
        0,
        1,
      )
      ..scaleByDouble(scaleX, scaleY, 1, 1);
    _paintTransform = transform;
    context.pushTransform(
      needsCompositing,
      offset,
      transform,
      (context, offset) => context.paintChild(child, offset),
    );
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return result.addWithPaintTransform(
      transform: _paintTransform,
      position: position,
      hitTest: (result, position) =>
          child?.hitTest(result, position: position) ?? false,
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final paintTransform = _paintTransform;
    if (paintTransform != null) transform.multiply(paintTransform);
  }
}
