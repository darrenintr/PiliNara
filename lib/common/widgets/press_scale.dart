import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// Adds a lightweight Material-style press compression without owning the tap.
///
/// Pointer events are observed instead of recognized, so an [InkWell], button,
/// or custom gesture detector below this widget keeps full control of its
/// callbacks and gesture arena. Moving far enough to become a scroll gesture
/// releases the compression immediately.
class PressScale extends StatefulWidget {
  const PressScale({
    super.key,
    required this.child,
    this.pressedScale = 0.97,
    this.alignment = Alignment.center,
  }) : assert(pressedScale > 0 && pressedScale <= 1);

  final Widget child;
  final double pressedScale;
  final Alignment alignment;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  int? _pointer;
  Offset? _pointerOrigin;
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value || !mounted) return;
    setState(() => _pressed = value);
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (_pointer != null || event.buttons != kPrimaryButton) return;
    _pointer = event.pointer;
    _pointerOrigin = event.position;
    _setPressed(true);
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (event.pointer != _pointer || !_pressed) return;
    final origin = _pointerOrigin;
    if (origin != null && (event.position - origin).distance > kTouchSlop) {
      _setPressed(false);
    }
  }

  void _handlePointerEnd(PointerEvent event) {
    if (event.pointer != _pointer) return;
    _pointer = null;
    _pointerOrigin = null;
    _setPressed(false);
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.maybeOf(
      context,
    )?.disableAnimations ?? false;
    return Listener(
      behavior: HitTestBehavior.deferToChild,
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerEnd,
      onPointerCancel: _handlePointerEnd,
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1,
        alignment: widget.alignment,
        duration: disableAnimations
            ? Duration.zero
            : Duration(milliseconds: _pressed ? 90 : 360),
        curve: _pressed ? Curves.easeOutCubic : Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}
