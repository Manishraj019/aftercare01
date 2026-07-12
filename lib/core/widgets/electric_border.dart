import 'dart:math';
import 'dart:ui' as ui;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// A Flutter port of the ElectricBorder React component.
/// Draws an animated, noise-distorted glowing border around its child.
class ElectricBorder extends StatefulWidget {
  final Widget child;
  final Color color;
  final double speed;
  final double chaos;
  final double borderRadius;
  final double thickness;

  const ElectricBorder({
    super.key,
    required this.child,
    this.color = const Color(0xFF00E5FF),
    this.speed = 1.0,
    this.chaos = 1.0,
    this.borderRadius = 8.0,
    this.thickness = 2.0,
  });

  @override
  State<ElectricBorder> createState() => _ElectricBorderState();
}

class _ElectricBorderState extends State<ElectricBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    if (kIsWeb || !Platform.environment.containsKey('FLUTTER_TEST')) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ElectricBorderPainter(
            color: widget.color,
            chaos: widget.chaos,
            borderRadius: widget.borderRadius,
            thickness: widget.thickness,
            time: _controller.value * widget.speed * 2 * pi,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Custom painter that draws the electric/noise-distorted border
class _ElectricBorderPainter extends CustomPainter {
  final Color color;
  final double chaos;
  final double borderRadius;
  final double thickness;
  final double time;

  _ElectricBorderPainter({
    required this.color,
    required this.chaos,
    required this.borderRadius,
    required this.thickness,
    required this.time,
  });

  // ── Noise Functions (ported from JS) ──

  double _random(double x) {
    return (sin(x * 12.9898) * 43758.5453) % 1;
  }

  double _noise2D(double x, double y) {
    final i = x.floor().toDouble();
    final j = y.floor().toDouble();
    final fx = x - i;
    final fy = y - j;

    final a = _random(i + j * 57);
    final b = _random(i + 1 + j * 57);
    final c = _random(i + (j + 1) * 57);
    final d = _random(i + 1 + (j + 1) * 57);

    final ux = fx * fx * (3.0 - 2.0 * fx);
    final uy = fy * fy * (3.0 - 2.0 * fy);

    return a * (1 - ux) * (1 - uy) + b * ux * (1 - uy) + c * (1 - ux) * uy + d * ux * uy;
  }

  double _octavedNoise(
    double x, {
    int octaves = 3, // Reduced from 10 for performance
    double lacunarity = 1.6,
    double gain = 0.7,
    required double amplitude,
    double frequency = 10,
    required double time,
    double seed = 0,
    double baseFlatness = 0,
  }) {
    double y = 0;
    double amp = amplitude;
    double freq = frequency;

    for (int i = 0; i < octaves; i++) {
      double octaveAmp = amp;
      if (i == 0) octaveAmp *= baseFlatness;
      y += octaveAmp * _noise2D(freq * x + seed * 100, time * freq * 0.3);
      freq *= lacunarity;
      amp *= gain;
    }

    return y;
  }

  // ── Rounded Rect Point Calculation ──

  Offset _getCornerPoint(double cx, double cy, double radius, double startAngle, double arcLength, double progress) {
    final angle = startAngle + progress * arcLength;
    return Offset(cx + radius * cos(angle), cy + radius * sin(angle));
  }

  Offset _getRoundedRectPoint(double t, double left, double top, double width, double height, double radius) {
    final straightWidth = width - 2 * radius;
    final straightHeight = height - 2 * radius;
    final cornerArc = (pi * radius) / 2;
    final totalPerimeter = 2 * straightWidth + 2 * straightHeight + 4 * cornerArc;
    final distance = t * totalPerimeter;

    double accumulated = 0;

    // Top edge
    if (distance <= accumulated + straightWidth) {
      final progress = (distance - accumulated) / straightWidth;
      return Offset(left + radius + progress * straightWidth, top);
    }
    accumulated += straightWidth;

    // Top-right corner
    if (distance <= accumulated + cornerArc) {
      final progress = (distance - accumulated) / cornerArc;
      return _getCornerPoint(left + width - radius, top + radius, radius, -pi / 2, pi / 2, progress);
    }
    accumulated += cornerArc;

    // Right edge
    if (distance <= accumulated + straightHeight) {
      final progress = (distance - accumulated) / straightHeight;
      return Offset(left + width, top + radius + progress * straightHeight);
    }
    accumulated += straightHeight;

    // Bottom-right corner
    if (distance <= accumulated + cornerArc) {
      final progress = (distance - accumulated) / cornerArc;
      return _getCornerPoint(left + width - radius, top + height - radius, radius, 0, pi / 2, progress);
    }
    accumulated += cornerArc;

    // Bottom edge
    if (distance <= accumulated + straightWidth) {
      final progress = (distance - accumulated) / straightWidth;
      return Offset(left + width - radius - progress * straightWidth, top + height);
    }
    accumulated += straightWidth;

    // Bottom-left corner
    if (distance <= accumulated + cornerArc) {
      final progress = (distance - accumulated) / cornerArc;
      return _getCornerPoint(left + radius, top + height - radius, radius, pi / 2, pi / 2, progress);
    }
    accumulated += cornerArc;

    // Left edge
    if (distance <= accumulated + straightHeight) {
      final progress = (distance - accumulated) / straightHeight;
      return Offset(left, top + height - radius - progress * straightHeight);
    }
    accumulated += straightHeight;

    // Top-left corner
    final progress = (distance - accumulated) / cornerArc;
    return _getCornerPoint(left + radius, top + radius, radius, pi, pi / 2, progress);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final displacement = 12.0 * chaos / 0.12; // Scale displacement with chaos
    final radius = min(borderRadius, min(size.width, size.height) / 2);

    final approximatePerimeter = 2 * (size.width + size.height) + 2 * pi * radius;
    // Reduce sample count heavily for performance (less points to calculate noise for)
    final sampleCount = (approximatePerimeter / 12).floor();

    // Build the distorted path
    final path = Path();
    for (int i = 0; i <= sampleCount; i++) {
      final progress = i / sampleCount;
      final point = _getRoundedRectPoint(progress, 0, 0, size.width, size.height, radius);

      final xNoise = _octavedNoise(
        progress * 8,
        amplitude: chaos,
        time: time,
        seed: 0,
      );
      final yNoise = _octavedNoise(
        progress * 8,
        amplitude: chaos,
        time: time,
        seed: 1,
      );

      final dx = point.dx + xNoise * displacement;
      final dy = point.dy + yNoise * displacement;

      if (i == 0) {
        path.moveTo(dx, dy);
      } else {
        path.lineTo(dx, dy);
      }
    }
    path.close();

    // ── Draw glow layers ──

    // Outer glow (blurred)
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness + 6
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, glowPaint);

    // Mid glow
    final midGlowPaint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness + 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, midGlowPaint);

    // Core stroke
    final strokePaint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, strokePaint);

    // Bright core (thin)
    final brightPaint = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness * 0.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, brightPaint);
  }

  @override
  bool shouldRepaint(covariant _ElectricBorderPainter oldDelegate) {
    return oldDelegate.time != time ||
        oldDelegate.color != color ||
        oldDelegate.chaos != chaos;
  }
}
