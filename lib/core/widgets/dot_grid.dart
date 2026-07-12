import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class DotGrid extends StatefulWidget {
  final double dotSize;
  final double gap;
  final Color baseColor;
  final Color activeColor;
  final double proximity;
  final double speedTrigger;
  final double shockRadius;
  final double shockStrength;
  final double returnDuration;
  final double resistance;

  const DotGrid({
    super.key,
    this.dotSize = 6.0,
    this.gap = 24.0,
    this.baseColor = const Color(0x225227FF), // Low opacity indigo base
    this.activeColor = const Color(0xFF5227FF), // Vibrant indigo active
    this.proximity = 120.0,
    this.speedTrigger = 100.0,
    this.shockRadius = 200.0,
    this.shockStrength = 8.0,
    this.returnDuration = 1.5,
    this.resistance = 750.0,
  });

  @override
  State<DotGrid> createState() => _DotGridState();
}

class Dot {
  final double cx;
  final double cy;
  double xOffset = 0.0;
  double yOffset = 0.0;
  double vx = 0.0;
  double vy = 0.0;

  Dot({required this.cx, required this.cy});
}

class _DotGridState extends State<DotGrid> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  List<Dot> _dots = [];
  Offset? _pointerPos;
  Offset _lastPointerPos = Offset.zero;
  double _pointerSpeed = 0.0;
  DateTime? _lastMoveTime;
  Size? _lastSize;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (_dots.isEmpty) return;

    // Physics parameters for elastic spring return:
    const double dt = 0.016; // Fixed timestep approx (60fps)
    const double k = 220.0;  // Spring constant
    const double c = 12.0;   // Damping constant

    for (var dot in _dots) {
      // Hooke's Law: F_spring = -k * displacement
      double fxSpring = -k * dot.xOffset;
      double fySpring = -k * dot.yOffset;

      // Friction/Damping: F_damping = -c * velocity
      double fxDamping = -c * dot.vx;
      double fyDamping = -c * dot.vy;

      // Update acceleration, velocity, and offset
      dot.vx += (fxSpring + fxDamping) * dt;
      dot.vy += (fySpring + fyDamping) * dt;
      dot.xOffset += dot.vx * dt;
      dot.yOffset += dot.vy * dt;

      // Prevent microscopic oscillations from draining CPU
      if (dot.xOffset.abs() < 0.05 && dot.vx.abs() < 0.05) {
        dot.xOffset = 0.0;
        dot.vx = 0.0;
      }
      if (dot.yOffset.abs() < 0.05 && dot.vy.abs() < 0.05) {
        dot.yOffset = 0.0;
        dot.vy = 0.0;
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _generateGrid(Size size) {
    _lastSize = size;
    final double cell = widget.dotSize + widget.gap;
    final int cols = (size.width / cell).ceil() + 1;
    final int rows = (size.height / cell).ceil() + 1;

    final double gridW = cell * (cols - 1);
    final double gridH = cell * (rows - 1);

    final double startX = (size.width - gridW) / 2;
    final double startY = (size.height - gridH) / 2;

    List<Dot> newDots = [];
    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++) {
        newDots.add(Dot(
          cx: startX + x * cell,
          cy: startY + y * cell,
        ));
      }
    }
    _dots = newDots;
  }

  void _onPointerMove(PointerEvent event) {
    final Offset currentPos = event.localPosition;
    final DateTime now = DateTime.now();

    if (_lastMoveTime != null) {
      final double dt = (now.difference(_lastMoveTime!).inMicroseconds) / 1000000.0;
      if (dt > 0) {
        final double dx = currentPos.dx - _lastPointerPos.dx;
        final double dy = currentPos.dy - _lastPointerPos.dy;
        _pointerSpeed = sqrt(dx * dx + dy * dy) / dt;

        // If pointer speed is high enough, apply inertia push
        if (_pointerSpeed > widget.speedTrigger) {
          final double pushStrength = min(_pointerSpeed / widget.resistance, 10.0);

          for (var dot in _dots) {
            final double dxDot = (dot.cx + dot.xOffset) - currentPos.dx;
            final double dyDot = (dot.cy + dot.yOffset) - currentPos.dy;
            final double distSq = dxDot * dxDot + dyDot * dyDot;

            if (distSq < widget.proximity * widget.proximity) {
              final double dist = sqrt(distSq);
              final double falloff = 1.0 - (dist / widget.proximity);
              
              // Push direction
              final double angle = dist == 0 ? 0.0 : atan2(dyDot, dxDot);
              dot.vx += cos(angle) * pushStrength * falloff * 40;
              dot.vy += sin(angle) * pushStrength * falloff * 40;
            }
          }
        }
      }
    }

    _pointerPos = currentPos;
    _lastPointerPos = currentPos;
    _lastMoveTime = now;
  }

  void _onPointerDown(PointerEvent event) {
    final Offset clickPos = event.localPosition;

    // Shockwave click effect pushing dots away
    for (var dot in _dots) {
      final double dxDot = (dot.cx + dot.xOffset) - clickPos.dx;
      final double dyDot = (dot.cy + dot.yOffset) - clickPos.dy;
      final double distSq = dxDot * dxDot + dyDot * dyDot;

      if (distSq < widget.shockRadius * widget.shockRadius) {
        final double dist = sqrt(distSq);
        final double falloff = 1.0 - (dist / widget.shockRadius);
        final double angle = dist == 0 ? Random().nextDouble() * 2 * pi : atan2(dyDot, dxDot);
        final double force = widget.shockStrength * falloff * 80;

        dot.vx += cos(angle) * force;
        dot.vy += sin(angle) * force;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final Size size = Size(constraints.maxWidth, constraints.maxHeight);
        if (_dots.isEmpty || _lastSize != size) {
          _generateGrid(size);
        }

        return MouseRegion(
          onExit: (_) {
            _pointerPos = null;
            _lastMoveTime = null;
          },
          child: Listener(
            onPointerMove: _onPointerMove,
            onPointerDown: _onPointerDown,
            onPointerHover: _onPointerMove,
            child: CustomPaint(
              size: size,
              painter: _DotGridPainter(
                dots: _dots,
                pointerPos: _pointerPos,
                dotSize: widget.dotSize,
                proximity: widget.proximity,
                baseColor: widget.baseColor,
                activeColor: widget.activeColor,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DotGridPainter extends CustomPainter {
  final List<Dot> dots;
  final Offset? pointerPos;
  final double dotSize;
  final double proximity;
  final Color baseColor;
  final Color activeColor;

  _DotGridPainter({
    required this.dots,
    required this.pointerPos,
    required this.dotSize,
    required this.proximity,
    required this.baseColor,
    required this.activeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..style = PaintingStyle.fill;
    final double proxSq = proximity * proximity;

    for (var dot in dots) {
      final double ox = dot.cx + dot.xOffset;
      final double oy = dot.cy + dot.yOffset;

      Color color = baseColor;

      if (pointerPos != null) {
        final double dx = dot.cx - pointerPos!.dx;
        final double dy = dot.cy - pointerPos!.dy;
        final double distSq = dx * dx + dy * dy;

        if (distSq <= proxSq) {
          final double dist = sqrt(distSq);
          final double t = 1.0 - (dist / proximity);
          color = Color.lerp(baseColor, activeColor, t) ?? baseColor;
        }
      }

      paint.color = color;
      canvas.drawCircle(Offset(ox, oy), dotSize / 2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DotGridPainter oldDelegate) {
    return true; // Continuously updated by the physics ticker loop
  }
}
