/*
 * This file is part of PiliPlus
 *
 * PiliPlus is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * PiliPlus is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with PiliPlus.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Material 3 Expressive wavy progress indicator.
///
/// A determinate ([value] != null) indicator fills a rounded track with an
/// animated wave; an indeterminate one sweeps a growing/shrinking wave. The
/// wave amplitude eases in on first paint so it reads as motion rather than a
/// hard switch.
///
/// https://m3.material.io/components/progress-indicators/guidelines
class WavyProgressIndicator extends StatefulWidget {
  const WavyProgressIndicator({
    super.key,
    this.value,
    this.height = 10,
    this.wavelength = 40,
    this.amplitude = 2.5,
    this.color,
    this.trackColor,
    this.stopColor,
    this.borderRadius,
    this.animationDuration = const Duration(milliseconds: 400),
    this.indeterminateDuration = const Duration(milliseconds: 1800),
    this.semanticLabel,
  }) : assert(height > 0),
       assert(wavelength > 0),
       assert(amplitude >= 0),
       assert(value == null || (value >= 0 && value <= 1));

  /// Progress in the range 0.0 - 1.0. `null` renders an indeterminate indicator.
  final double? value;

  /// Overall height of the indicator, including the wave amplitude.
  final double height;

  /// Distance between two wave crests.
  final double wavelength;

  /// Wave amplitude. Automatically clamped so the band stays inside [height].
  final double amplitude;

  final Color? color;
  final Color? trackColor;

  /// Optional "stop indicator" dot drawn at the end of the track.
  final Color? stopColor;

  /// Rounded cap radius. Defaults to a stadium ([height] / 2).
  final BorderRadius? borderRadius;

  /// Duration used when the determinate [value] eases to a new target.
  final Duration animationDuration;

  /// Loop duration of the indeterminate sweep.
  final Duration indeterminateDuration;

  final String? semanticLabel;

  @override
  State<WavyProgressIndicator> createState() => _WavyProgressIndicatorState();
}

class _WavyProgressIndicatorState extends State<WavyProgressIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Tween<double> _valueTween;

  @override
  void initState() {
    super.initState();
    _valueTween = Tween<double>(
      begin: widget.value ?? 0,
      end: widget.value ?? 0,
    );
    _controller = AnimationController(
      vsync: this,
      duration: _durationFor(widget),
    );
    if (widget.value == null) {
      _controller.repeat();
    } else {
      _controller.value = 1.0;
    }
  }

  static Duration _durationFor(WavyProgressIndicator widget) =>
      widget.value == null
      ? widget.indeterminateDuration
      : widget.animationDuration;

  @override
  void didUpdateWidget(covariant WavyProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.duration = _durationFor(widget);
    final wasIndeterminate = oldWidget.value == null;
    final isIndeterminate = widget.value == null;
    if (isIndeterminate != wasIndeterminate) {
      if (isIndeterminate) {
        _controller.repeat();
      } else {
        _controller
          ..stop()
          ..value = 1.0;
        _valueTween = Tween<double>(
          begin: widget.value,
          end: widget.value,
        );
      }
    } else if (!isIndeterminate && widget.value != oldWidget.value) {
      _valueTween = Tween<double>(
        begin: _valueTween.evaluate(_controller),
        end: widget.value!,
      );
      _controller
        ..value = 0.0
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    final color = widget.color ?? colorScheme.primary;
    final trackColor = widget.trackColor ?? colorScheme.secondaryContainer;
    final stopColor = widget.stopColor ?? color;
    final radius =
        widget.borderRadius ?? BorderRadius.circular(widget.height / 2);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    if (widget.value == null && reduceMotion) {
      return Semantics(
        label: widget.semanticLabel,
        child: _WavyProgressPainter(
          progress: null,
          color: color,
          trackColor: trackColor,
          stopColor: stopColor,
          radius: radius,
          wavelength: widget.wavelength,
          amplitude: widget.amplitude,
          phase: 0,
          sweep: 0.5,
          sweepExtent: 1,
        ).buildSizedBox(height: widget.height),
      );
    }

    return Semantics(
      label: widget.semanticLabel,
      value: widget.value == null ? null : '${(widget.value! * 100).round()}%',
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final progress = widget.value == null
              ? null
              : _valueTween.evaluate(_controller).clamp(0.0, 1.0);
          final t = _controller.value;
          return CustomPaint(
            size: Size.infinite,
            painter: _WavyProgressPainter(
              progress: progress,
              color: color,
              trackColor: trackColor,
              stopColor: stopColor,
              radius: radius,
              wavelength: widget.wavelength,
              amplitude: widget.amplitude,
              phase: reduceMotion || progress != null ? 0 : t * math.pi * 4,
              sweep: _sweepStart(t),
              sweepExtent: progress == null ? _sweepExtent(t) : 1,
            ),
            child: SizedBox(
              height: widget.height,
              width: double.infinity,
            ),
          );
        },
      ),
    );
  }

  /// Indeterminate sweep grows and shrinks like the M3 indeterminate linear bar.
  static double _sweepStart(double t) => -0.35 + 1.35 * t;

  static double _sweepExtent(double t) =>
      0.35 + 0.35 * math.sin(math.pi * t).abs();
}

class _WavyProgressPainter extends CustomPainter {
  _WavyProgressPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.stopColor,
    required this.radius,
    required this.wavelength,
    required this.amplitude,
    required this.phase,
    required this.sweep,
    required this.sweepExtent,
  });

  final double? progress;
  final Color color;
  final Color trackColor;
  final Color stopColor;
  final BorderRadius radius;
  final double wavelength;
  final double amplitude;
  final double phase;
  final double sweep;
  final double sweepExtent;

  Widget buildSizedBox({required double height}) => CustomPaint(
    painter: this,
    child: SizedBox(height: height, width: double.infinity),
  );

  @override
  void paint(Canvas canvas, Size size) {
    final height = size.height;
    final width = size.width;
    if (width <= 0 || height <= 0) return;

    final rrect = radius.toRRect(Offset.zero & size);
    canvas.drawRRect(rrect, Paint()..color = trackColor);

    final amp = amplitude.clamp(0.0, height / 2).toDouble();
    final bandHalf = math.max(0.0, (height - 2 * amp) / 2);
    final midY = height / 2;

    void drawBand(double left, double right) {
      if (right <= left) return;
      final waveWidth = right - left;
      final path = Path();
      final steps = math.max(2, (waveWidth / 2).ceil());
      for (var i = 0; i <= steps; i++) {
        final x = left + waveWidth * i / steps;
        final y =
            midY -
            bandHalf +
            amp * math.sin(2 * math.pi * x / wavelength + phase);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      for (var i = steps; i >= 0; i--) {
        final x = left + waveWidth * i / steps;
        final y =
            midY +
            bandHalf +
            amp * math.sin(2 * math.pi * x / wavelength + phase);
        path.lineTo(x, y);
      }
      path.close();
      canvas
        ..save()
        ..clipRRect(rrect)
        ..drawPath(path, Paint()..color = color)
        ..restore();
    }

    if (progress != null) {
      drawBand(0, width * progress!);
      // M3 stop indicator: a small dot pinned to the end of the track.
      canvas.drawCircle(
        Offset(width - height * 0.18, midY),
        math.max(1.5, height * 0.14),
        Paint()..color = stopColor.withValues(alpha: 0.6),
      );
    } else {
      final left = width * sweep;
      drawBand(left, left + width * sweepExtent);
    }
  }

  @override
  bool shouldRepaint(covariant _WavyProgressPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.stopColor != stopColor ||
      oldDelegate.radius != radius ||
      oldDelegate.wavelength != wavelength ||
      oldDelegate.amplitude != amplitude ||
      oldDelegate.phase != phase ||
      oldDelegate.sweep != sweep ||
      oldDelegate.sweepExtent != sweepExtent;
}
