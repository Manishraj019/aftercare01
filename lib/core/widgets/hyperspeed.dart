import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class Hyperspeed extends StatefulWidget {
  final double length;
  final double roadWidth;
  final double islandWidth;
  final int lanesPerRoad;
  final double fov;
  final double fovSpeedUp;
  final double speedUpFactor;
  final double carLightsFade;
  final int totalSideLightSticks;
  final int lightPairsPerRoadWay;
  final List<Color> leftCarColors;
  final List<Color> rightCarColors;
  final List<Color> stickColors;
  final Color roadColor;
  final Color islandColor;
  final Color shoulderLinesColor;
  final Color brokenLinesColor;
  final Color backgroundColor;
  final VoidCallback? onSpeedUp;
  final VoidCallback? onSlowDown;

  const Hyperspeed({
    super.key,
    this.length = 400.0,
    this.roadWidth = 12.0,
    this.islandWidth = 2.0,
    this.lanesPerRoad = 3,
    this.fov = 90.0,
    this.fovSpeedUp = 140.0,
    this.speedUpFactor = 2.5,
    this.carLightsFade = 0.4,
    this.totalSideLightSticks = 20,
    this.lightPairsPerRoadWay = 30,
    this.leftCarColors = const [
      Color(0xFFD856BF), // Neon Magenta
      Color(0xFF6750A2), // Violet
      Color(0xFFC247AC), // Pink-Purple
    ],
    this.rightCarColors = const [
      Color(0xFF03B3C3), // Neon Cyan
      Color(0xFF0E5EA5), // Royal Blue
      Color(0xFF324555), // Dark Blue-Grey
    ],
    this.stickColors = const [
      Color(0xFF03B3C3),
      Color(0xFFD856BF),
    ],
    this.roadColor = const Color(0xFF080808),
    this.islandColor = const Color(0xFF050505),
    this.shoulderLinesColor = const Color(0x88FFFFFF),
    this.brokenLinesColor = const Color(0x44FFFFFF),
    this.backgroundColor = Colors.black,
    this.onSpeedUp,
    this.onSlowDown,
  });

  @override
  State<Hyperspeed> createState() => _HyperspeedState();
}

class CarLight {
  final int lane;
  final double sideOffset; // -1 for left light, 1 for right light
  final double radius;
  final double length;
  final double speed;
  final Color color;
  double pz; // Position along Z axis (0 to length)

  CarLight({
    required this.lane,
    required this.sideOffset,
    required this.radius,
    required this.length,
    required this.speed,
    required this.color,
    required this.pz,
  });
}

class LightStick {
  final double x;
  final double width;
  final double height;
  final Color color;
  double pz; // Position along Z

  LightStick({
    required this.x,
    required this.width,
    required this.height,
    required this.color,
    required this.pz,
  });
}

class _HyperspeedState extends State<Hyperspeed> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  double _time = 0.0;
  double _speedMultiplier = 1.0;
  double _targetSpeedMultiplier = 1.0;
  double _currentFov = 90.0;
  double _targetFov = 90.0;

  final List<CarLight> _leftCars = [];
  final List<CarLight> _rightCars = [];
  final List<LightStick> _sticks = [];

  final Random _rand = Random();

  @override
  void initState() {
    super.initState();
    _currentFov = widget.fov;
    _targetFov = widget.fov;
    _initializeLights();
    _ticker = createTicker(_onTick);
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _initializeLights() {
    final double laneWidth = widget.roadWidth / widget.lanesPerRoad;
    final double leftRoadCenter = -widget.roadWidth / 2 - widget.islandWidth / 2;
    final double rightRoadCenter = widget.roadWidth / 2 + widget.islandWidth / 2;

    // Initialize left road cars (moving away, so speed is positive)
    for (int i = 0; i < widget.lightPairsPerRoadWay; i++) {
      final int lane = i % widget.lanesPerRoad;
      final double speed = _rand.nextDouble() * 20.0 + 50.0; // Speed [50, 70]
      final double radius = _rand.nextDouble() * 0.09 + 0.05; // Radius [0.05, 0.14]
      final double len = _rand.nextDouble() * 40.0 + 20.0; // Length [20, 60]
      final Color color = widget.leftCarColors[_rand.nextInt(widget.leftCarColors.length)];
      final double startZ = _rand.nextDouble() * widget.length;

      // Add a pair of lights representing one car
      _leftCars.add(CarLight(
        lane: lane,
        sideOffset: -1.0,
        radius: radius,
        length: len,
        speed: speed,
        color: color,
        pz: startZ,
      ));
      _leftCars.add(CarLight(
        lane: lane,
        sideOffset: 1.0,
        radius: radius,
        length: len,
        speed: speed,
        color: color,
        pz: startZ,
      ));
    }

    // Initialize right road cars (moving closer, so speed is negative relative to camera direction)
    for (int i = 0; i < widget.lightPairsPerRoadWay; i++) {
      final int lane = i % widget.lanesPerRoad;
      final double speed = _rand.nextDouble() * 30.0 + 70.0; // Speed [70, 100]
      final double radius = _rand.nextDouble() * 0.09 + 0.05;
      final double len = _rand.nextDouble() * 40.0 + 20.0;
      final Color color = widget.rightCarColors[_rand.nextInt(widget.rightCarColors.length)];
      final double startZ = _rand.nextDouble() * widget.length;

      _rightCars.add(CarLight(
        lane: lane,
        sideOffset: -1.0,
        radius: radius,
        length: len,
        speed: speed,
        color: color,
        pz: startZ,
      ));
      _rightCars.add(CarLight(
        lane: lane,
        sideOffset: 1.0,
        radius: radius,
        length: len,
        speed: speed,
        color: color,
        pz: startZ,
      ));
    }

    // Initialize side sticks
    final double stickInterval = widget.length / widget.totalSideLightSticks;
    for (int i = 0; i < widget.totalSideLightSticks; i++) {
      final double width = _rand.nextDouble() * 0.15 + 0.1;
      final double height = _rand.nextDouble() * 0.5 + 1.2;
      final Color color = widget.stickColors[_rand.nextInt(widget.stickColors.length)];
      final double pz = i * stickInterval + _rand.nextDouble() * (stickInterval * 0.5);

      // Stick on left side
      _sticks.add(LightStick(
        x: -(widget.roadWidth + widget.islandWidth / 2 + 0.5),
        width: width,
        height: height,
        color: color,
        pz: pz,
      ));

      // Stick on right side
      _sticks.add(LightStick(
        x: (widget.roadWidth + widget.islandWidth / 2 + 0.5),
        width: width,
        height: height,
        color: color,
        pz: pz,
      ));
    }
  }

  void _onTick(Duration elapsed) {
    const double dt = 0.016;

    // Smoothly lerp FOV and SpeedMultiplier
    _currentFov += (_targetFov - _currentFov) * 0.08;
    _speedMultiplier += (_targetSpeedMultiplier - _speedMultiplier) * 0.08;

    _time += dt * _speedMultiplier;

    final double speedFactor = _speedMultiplier;

    // Update left cars (moving away along Z)
    for (var car in _leftCars) {
      car.pz += car.speed * dt * speedFactor;
      if (car.pz > widget.length) {
        car.pz -= widget.length;
      }
    }

    // Update right cars (moving closer along Z)
    for (var car in _rightCars) {
      car.pz -= car.speed * dt * speedFactor;
      if (car.pz < 0) {
        car.pz += widget.length;
      }
    }

    // Update side sticks (moving closer along Z, matching camera progression)
    final double cameraProgressSpeed = 60.0;
    for (var stick in _sticks) {
      stick.pz -= cameraProgressSpeed * dt * speedFactor;
      if (stick.pz < 0) {
        stick.pz += widget.length;
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _handleSpeedUp() {
    widget.onSpeedUp?.call();
    setState(() {
      _targetFov = widget.fovSpeedUp;
      _targetSpeedMultiplier = widget.speedUpFactor;
    });
  }

  void _handleSlowDown() {
    widget.onSlowDown?.call();
    setState(() {
      _targetFov = widget.fov;
      _targetSpeedMultiplier = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _handleSpeedUp(),
      onPointerUp: (_) => _handleSlowDown(),
      onPointerCancel: (_) => _handleSlowDown(),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          color: widget.backgroundColor,
          width: double.infinity,
          height: double.infinity,
          child: CustomPaint(
            painter: _HyperspeedPainter(
              length: widget.length,
              roadWidth: widget.roadWidth,
              islandWidth: widget.islandWidth,
              lanesPerRoad: widget.lanesPerRoad,
              fov: _currentFov,
              time: _time,
              leftCars: _leftCars,
              rightCars: _rightCars,
              sticks: _sticks,
              roadColor: widget.roadColor,
              islandColor: widget.islandColor,
              shoulderLinesColor: widget.shoulderLinesColor,
              brokenLinesColor: widget.brokenLinesColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _HyperspeedPainter extends CustomPainter {
  final double length;
  final double roadWidth;
  final double islandWidth;
  final int lanesPerRoad;
  final double fov;
  final double time;
  final List<CarLight> leftCars;
  final List<CarLight> rightCars;
  final List<LightStick> sticks;
  final Color roadColor;
  final Color islandColor;
  final Color shoulderLinesColor;
  final Color brokenLinesColor;

  _HyperspeedPainter({
    required this.length,
    required this.roadWidth,
    required this.islandWidth,
    required this.lanesPerRoad,
    required this.fov,
    required this.time,
    required this.leftCars,
    required this.rightCars,
    required this.sticks,
    required this.roadColor,
    required this.islandColor,
    required this.shoulderLinesColor,
    required this.brokenLinesColor,
  });

  // ── Turbulent Distortion Formulas ──
  double _nsin(double val) => sin(val) * 0.5 + 0.5;

  double _getDistortionX(double p, double t) {
    // uFreq = (4, 8, 8, 1), uAmp = (25, 5, 10, 10)
    final double getX = cos(pi * p * 4.0 + t) * 20.0 +
        pow(cos(pi * p * 8.0 + t * 2.0), 2.0) * 4.0;
    final double getXCam = cos(pi * 0.0125 * 4.0 + t) * 20.0 +
        pow(cos(pi * 0.0125 * 8.0 + t * 2.0), 2.0) * 4.0;
    return getX - getXCam;
  }

  double _getDistortionY(double p, double t) {
    final double getY = -_nsin(pi * p * 8.0 + t) * 8.0 -
        pow(_nsin(pi * p * 1.0 + t / 8.0), 5.0) * 8.0;
    final double getYCam = -_nsin(pi * 0.0125 * 8.0 + t) * 8.0 -
        pow(_nsin(pi * 0.0125 * 1.0 + t / 8.0), 5.0) * 8.0;
    return getY - getYCam;
  }

  // ── Perspective 3D to 2D Projection ──
  Offset? _project(double px, double py, double pz, double halfW, double halfH, double fovScale, double camDx, double camDy) {
    // Camera is at (0, 8, -5)
    const double cameraX = 0.0;
    const double cameraY = 6.0;
    const double cameraZ = -5.0;

    final double p = pz / length;
    final double dx = _getDistortionX(p, time);
    final double dy = _getDistortionY(p, time);

    // Apply road distortion
    final double wx = px + dx;
    final double wy = py + dy;
    final double wz = pz;

    // Apply camera rotation / follow-road-tilt
    final double rx = wx - cameraX - camDx * p;
    final double ry = wy - cameraY - camDy * p;
    final double rz = wz - cameraZ;

    if (rz <= 0.1) return null;

    final double scale = fovScale / rz;
    final double sx = halfW + rx * scale;
    final double sy = halfH - ry * scale;

    return Offset(sx, sy);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double halfW = size.width / 2;
    final double halfH = size.height / 2;

    // Perspective fovScale
    final double fovRad = fov * pi / 180.0;
    final double fovScale = (size.height / 2.0) / tan(fovRad / 2.0);

    // Camera lookAt tilt vector (calculated at target progress 0.025)
    final double camDx = _getDistortionX(0.025, time) * -2.0;
    final double camDy = _getDistortionY(0.025, time) * -4.0;

    // Draw background color (fog/fade background)
    final Paint bgPaint = Paint()..color = Colors.black;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final double laneWidth = roadWidth / lanesPerRoad;
    final double leftRoadCenter = -roadWidth / 2 - islandWidth / 2;
    final double rightRoadCenter = roadWidth / 2 + islandWidth / 2;

    // ── 1. Draw Road and Island Mesh (Back to Front) ──
    const int segmentsCount = 25;
    final double stepZ = length / segmentsCount;

    for (int i = segmentsCount - 1; i >= 0; i--) {
      final double z1 = i * stepZ;
      final double z2 = (i + 1) * stepZ;

      // Draw Island (middle ground)
      final Offset? isLL = _project(-islandWidth / 2, 0.0, z1, halfW, halfH, fovScale, camDx, camDy);
      final Offset? isLR = _project(islandWidth / 2, 0.0, z1, halfW, halfH, fovScale, camDx, camDy);
      final Offset? isUR = _project(islandWidth / 2, 0.0, z2, halfW, halfH, fovScale, camDx, camDy);
      final Offset? isUL = _project(-islandWidth / 2, 0.0, z2, halfW, halfH, fovScale, camDx, camDy);

      if (isLL != null && isLR != null && isUR != null && isUL != null) {
        final Path islandPath = Path()
          ..moveTo(isLL.dx, isLL.dy)
          ..lineTo(isLR.dx, isLR.dy)
          ..lineTo(isUR.dx, isUR.dy)
          ..lineTo(isUL.dx, isUL.dy)
          ..close();
        canvas.drawPath(islandPath, Paint()..color = islandColor);
      }

      // Draw Left Road
      final Offset? rdLL = _project(leftRoadCenter - roadWidth / 2, 0.0, z1, halfW, halfH, fovScale, camDx, camDy);
      final Offset? rdLR = _project(leftRoadCenter + roadWidth / 2, 0.0, z1, halfW, halfH, fovScale, camDx, camDy);
      final Offset? rdUR = _project(leftRoadCenter + roadWidth / 2, 0.0, z2, halfW, halfH, fovScale, camDx, camDy);
      final Offset? rdUL = _project(leftRoadCenter - roadWidth / 2, 0.0, z2, halfW, halfH, fovScale, camDx, camDy);

      if (rdLL != null && rdLR != null && rdUR != null && rdUL != null) {
        final Path roadPath = Path()
          ..moveTo(rdLL.dx, rdLL.dy)
          ..lineTo(rdLR.dx, rdLR.dy)
          ..lineTo(rdUR.dx, rdUR.dy)
          ..lineTo(rdUL.dx, rdUL.dy)
          ..close();
        canvas.drawPath(roadPath, Paint()..color = roadColor);
      }

      // Draw Right Road
      final Offset? rRdLL = _project(rightRoadCenter - roadWidth / 2, 0.0, z1, halfW, halfH, fovScale, camDx, camDy);
      final Offset? rRdLR = _project(rightRoadCenter + roadWidth / 2, 0.0, z1, halfW, halfH, fovScale, camDx, camDy);
      final Offset? rRdUR = _project(rightRoadCenter + roadWidth / 2, 0.0, z2, halfW, halfH, fovScale, camDx, camDy);
      final Offset? rRdUL = _project(rightRoadCenter - roadWidth / 2, 0.0, z2, halfW, halfH, fovScale, camDx, camDy);

      if (rRdLL != null && rRdLR != null && rRdUR != null && rRdUL != null) {
        final Path roadPath = Path()
          ..moveTo(rRdLL.dx, rRdLL.dy)
          ..lineTo(rRdLR.dx, rRdLR.dy)
          ..lineTo(rRdUR.dx, rRdUR.dy)
          ..lineTo(rRdUL.dx, rRdUL.dy)
          ..close();
        canvas.drawPath(roadPath, Paint()..color = roadColor);
      }

      // Draw Lane broken lines (animated texture movement)
      final double movingOffset = (time * 80.0) % stepZ;
      final double lineZ1 = z1 + movingOffset;
      final double lineZ2 = lineZ1 + stepZ * 0.4; // Draw lines that cover 40% of the segment

      if (lineZ2 <= length) {
        // Draw markings for left road lanes
        for (int l = 1; l < lanesPerRoad; l++) {
          final double lx = leftRoadCenter - roadWidth / 2 + l * laneWidth;
          final Offset? p1 = _project(lx, 0.0, lineZ1, halfW, halfH, fovScale, camDx, camDy);
          final Offset? p2 = _project(lx, 0.0, lineZ2, halfW, halfH, fovScale, camDx, camDy);
          if (p1 != null && p2 != null) {
            final double depthAlpha = (1.0 - (lineZ1 / length)).clamp(0.0, 1.0);
            final double thickness = max(0.5, 4.0 * fovScale / lineZ1);
            canvas.drawLine(
              p1,
              p2,
              Paint()
                ..color = brokenLinesColor.withOpacity(brokenLinesColor.opacity * depthAlpha)
                ..strokeWidth = thickness,
            );
          }
        }

        // Draw markings for right road lanes
        for (int l = 1; l < lanesPerRoad; l++) {
          final double lx = rightRoadCenter - roadWidth / 2 + l * laneWidth;
          final Offset? p1 = _project(lx, 0.0, lineZ1, halfW, halfH, fovScale, camDx, camDy);
          final Offset? p2 = _project(lx, 0.0, lineZ2, halfW, halfH, fovScale, camDx, camDy);
          if (p1 != null && p2 != null) {
            final double depthAlpha = (1.0 - (lineZ1 / length)).clamp(0.0, 1.0);
            final double thickness = max(0.5, 4.0 * fovScale / lineZ1);
            canvas.drawLine(
              p1,
              p2,
              Paint()
                ..color = brokenLinesColor.withOpacity(brokenLinesColor.opacity * depthAlpha)
                ..strokeWidth = thickness,
            );
          }
        }
      }

      // Draw shoulder lines (outer boundaries)
      final Offset? sL1 = _project(leftRoadCenter - roadWidth / 2, 0.0, z1, halfW, halfH, fovScale, camDx, camDy);
      final Offset? sL2 = _project(leftRoadCenter - roadWidth / 2, 0.0, z2, halfW, halfH, fovScale, camDx, camDy);
      if (sL1 != null && sL2 != null) {
        final double depthAlpha = (1.0 - (z1 / length)).clamp(0.0, 1.0);
        final double thickness = max(0.8, 6.0 * fovScale / z1);
        canvas.drawLine(
          sL1,
          sL2,
          Paint()
            ..color = shoulderLinesColor.withOpacity(shoulderLinesColor.opacity * depthAlpha)
            ..strokeWidth = thickness,
        );
      }

      final Offset? sR1 = _project(rightRoadCenter + roadWidth / 2, 0.0, z1, halfW, halfH, fovScale, camDx, camDy);
      final Offset? sR2 = _project(rightRoadCenter + roadWidth / 2, 0.0, z2, halfW, halfH, fovScale, camDx, camDy);
      if (sR1 != null && sR2 != null) {
        final double depthAlpha = (1.0 - (z1 / length)).clamp(0.0, 1.0);
        final double thickness = max(0.8, 6.0 * fovScale / z1);
        canvas.drawLine(
          sR1,
          sR2,
          Paint()
            ..color = shoulderLinesColor.withOpacity(shoulderLinesColor.opacity * depthAlpha)
            ..strokeWidth = thickness,
        );
      }
    }

    // ── 2. Draw Side Light Sticks ──
    for (var stick in sticks) {
      final double z = stick.pz;
      final Offset? bottomProj = _project(stick.x, 0.0, z, halfW, halfH, fovScale, camDx, camDy);
      final Offset? topProj = _project(stick.x, stick.height, z, halfW, halfH, fovScale, camDx, camDy);

      if (bottomProj != null && topProj != null) {
        final double depthAlpha = (1.0 - (z / length)).clamp(0.0, 1.0);
        final double thickness = max(1.0, stick.width * 25.0 * fovScale / z);

        // Glow pass
        canvas.drawLine(
          bottomProj,
          topProj,
          Paint()
            ..color = stick.color.withOpacity(0.15 * depthAlpha)
            ..strokeWidth = thickness * 3.5
            ..strokeCap = StrokeCap.round,
        );

        // Core pass
        canvas.drawLine(
          bottomProj,
          topProj,
          Paint()
            ..color = stick.color.withOpacity(depthAlpha)
            ..strokeWidth = thickness
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    // ── 3. Draw Left Car Lights (Away, red/pink tail lights) ──
    for (var car in leftCars) {
      final double zStart = car.pz;
      final double zEnd = max(0.1, zStart - car.length);

      final double carWidth = laneWidth * 0.45;
      final double laneX = leftRoadCenter - roadWidth / 2 + car.lane * laneWidth + laneWidth / 2;
      final double px = laneX + (car.sideOffset * carWidth / 2);
      final double py = car.radius * 1.5;

      final Offset? startProj = _project(px, py, zStart, halfW, halfH, fovScale, camDx, camDy);
      final Offset? endProj = _project(px, py, zEnd, halfW, halfH, fovScale, camDx, camDy);

      if (startProj != null && endProj != null) {
        final double depthAlpha = (1.0 - (zStart / length)).clamp(0.0, 1.0);
        final double thickness = max(1.0, car.radius * 50.0 * fovScale / zStart);

        // Render light trail with dual-pass bloom
        // Outer glow
        canvas.drawLine(
          startProj,
          endProj,
          Paint()
            ..color = car.color.withOpacity(0.18 * depthAlpha)
            ..strokeWidth = thickness * 4.0
            ..strokeCap = StrokeCap.round,
        );
        // Inner core
        canvas.drawLine(
          startProj,
          endProj,
          Paint()
            ..color = car.color.withOpacity(depthAlpha)
            ..strokeWidth = thickness
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    // ── 4. Draw Right Car Lights (Towards, cyan/blue headlights) ──
    for (var car in rightCars) {
      final double zStart = car.pz;
      final double zEnd = min(length, zStart + car.length);

      final double carWidth = laneWidth * 0.45;
      final double laneX = rightRoadCenter - roadWidth / 2 + car.lane * laneWidth + laneWidth / 2;
      final double px = laneX + (car.sideOffset * carWidth / 2);
      final double py = car.radius * 1.5;

      final Offset? startProj = _project(px, py, zStart, halfW, halfH, fovScale, camDx, camDy);
      final Offset? endProj = _project(px, py, zEnd, halfW, halfH, fovScale, camDx, camDy);

      if (startProj != null && endProj != null) {
        final double depthAlpha = (1.0 - (zStart / length)).clamp(0.0, 1.0);
        final double thickness = max(1.0, car.radius * 50.0 * fovScale / zStart);

        // Glow
        canvas.drawLine(
          startProj,
          endProj,
          Paint()
            ..color = car.color.withOpacity(0.18 * depthAlpha)
            ..strokeWidth = thickness * 4.0
            ..strokeCap = StrokeCap.round,
        );
        // Core
        canvas.drawLine(
          startProj,
          endProj,
          Paint()
            ..color = car.color.withOpacity(depthAlpha)
            ..strokeWidth = thickness
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HyperspeedPainter oldDelegate) {
    return true; // Continuously updated by ticker loop
  }
}
