import 'dart:math';
import 'package:flutter/material.dart';

class HexagonPattern extends StatefulWidget {
  final double radius;
  final double gap;
  final double xOffset;
  final double yOffset;
  final String direction;
  final String strokeDasharray;
  final List<Point<int>>? hexagons;
  final Color strokeColor;
  final Color fillColor;
  final Color highlightColor;
  final Color hoverColor;
  final double strokeWidth;

  const HexagonPattern({
    super.key,
    this.radius = 40.0,
    this.gap = 0.0,
    this.xOffset = -1.0,
    this.yOffset = -1.0,
    this.direction = "horizontal",
    this.strokeDasharray = "0",
    this.hexagons,
    this.strokeColor = const Color(0x0CFFFFFF), // Very subtle grid stroke
    this.fillColor = const Color(0x05FFFFFF),   // Translucent fill
    this.highlightColor = const Color(0x1B06B6D4), // Cyan highlight for preset hexagons
    this.hoverColor = const Color(0x333B82F6),     // Electric blue hover glow
    this.strokeWidth = 1.0,
  });

  @override
  State<HexagonPattern> createState() => _HexagonPatternState();
}

class _HexagonPatternState extends State<HexagonPattern> {
  Offset? _pointerPos;
  Point<int>? _hoveredHex;

  // Resolve which hexagon is closest to the pointer position
  Point<int>? _resolveHoveredHex(Size size) {
    if (_pointerPos == null) return null;

    final double r = widget.radius;
    final double g = widget.gap;
    final String dir = widget.direction;
    final double sqrt3 = 1.732050807568877;

    double colStep, rowStep;
    if (dir == "horizontal") {
      colStep = (3.0 * r) / 2.0 + (sqrt3 * g) / 2.0;
      rowStep = sqrt3 * r + g;
    } else {
      colStep = sqrt3 * r + g;
      rowStep = (3.0 * r) / 2.0 + (sqrt3 * g) / 2.0;
    }

    // Estimate range of columns/rows around the pointer to search
    final int minCol = ((_pointerPos!.dx - widget.xOffset - r) / colStep).floor() - 1;
    final int maxCol = ((_pointerPos!.dx - widget.xOffset + r) / colStep).ceil() + 1;
    final int minRow = ((_pointerPos!.dy - widget.yOffset - r) / rowStep).floor() - 1;
    final int maxRow = ((_pointerPos!.dy - widget.yOffset + r) / rowStep).ceil() + 1;

    double minDist = double.infinity;
    Point<int>? bestHex;

    for (int col = minCol; col <= maxCol; col++) {
      for (int row = minRow; row <= maxRow; row++) {
        final Offset center = _getHexCenter(col, row, r, dir, g);
        final double dx = _pointerPos!.dx - widget.xOffset - center.dx;
        final double dy = _pointerPos!.dy - widget.yOffset - center.dy;
        final double dist = sqrt(dx * dx + dy * dy);

        // A point is inside the hexagon if its distance to the center is <= r * cos(30 degrees)
        final double hexInnerRadius = r * 0.866; // 0.866 approx cos(30 deg)
        if (dist <= hexInnerRadius && dist < minDist) {
          minDist = dist;
          bestHex = Point(col, row);
        }
      }
    }

    return bestHex;
  }

  Offset _getHexCenter(int col, int row, double r, String direction, double gap) {
    final double sqrt3 = 1.732050807568877;
    if (direction == "horizontal") {
      final double colStep = (3.0 * r) / 2.0 + (sqrt3 * gap) / 2.0;
      final double rowStep = sqrt3 * r + gap;
      final double x = col * colStep + colStep / 2.0;
      final double y = row * rowStep + rowStep / 2.0 + (col % 2 != 0 ? rowStep / 2.0 : 0.0);
      return Offset(x, y);
    } else {
      final double colStep = sqrt3 * r + gap;
      final double rowStep = (3.0 * r) / 2.0 + (sqrt3 * gap) / 2.0;
      final double x = col * colStep + colStep / 2.0 + (row % 2 != 0 ? colStep / 2.0 : 0.0);
      final double y = row * rowStep + rowStep / 2.0;
      return Offset(x, y);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final Size size = Size(constraints.maxWidth, constraints.maxHeight);

        return MouseRegion(
          onHover: (event) {
            setState(() {
              _pointerPos = event.localPosition;
              _hoveredHex = _resolveHoveredHex(size);
            });
          },
          onExit: (_) {
            setState(() {
              _pointerPos = null;
              _hoveredHex = null;
            });
          },
          child: CustomPaint(
            size: size,
            painter: _HexagonPatternPainter(
              radius: widget.radius,
              gap: widget.gap,
              xOffset: widget.xOffset,
              yOffset: widget.yOffset,
              direction: widget.direction,
              strokeDasharray: widget.strokeDasharray,
              hexagons: widget.hexagons,
              strokeColor: widget.strokeColor,
              fillColor: widget.fillColor,
              highlightColor: widget.highlightColor,
              hoverColor: widget.hoverColor,
              strokeWidth: widget.strokeWidth,
              hoveredHex: _hoveredHex,
            ),
          ),
        );
      },
    );
  }
}

class _HexagonPatternPainter extends CustomPainter {
  final double radius;
  final double gap;
  final double xOffset;
  final double yOffset;
  final String direction;
  final String strokeDasharray;
  final List<Point<int>>? hexagons;
  final Color strokeColor;
  final Color fillColor;
  final Color highlightColor;
  final Color hoverColor;
  final double strokeWidth;
  final Point<int>? hoveredHex;

  _HexagonPatternPainter({
    required this.radius,
    required this.gap,
    required this.xOffset,
    required this.yOffset,
    required this.direction,
    required this.strokeDasharray,
    required this.hexagons,
    required this.strokeColor,
    required this.fillColor,
    required this.highlightColor,
    required this.hoverColor,
    required this.strokeWidth,
    required this.hoveredHex,
  });

  // Calculate hexagon center position
  Offset _getHexCenter(int col, int row, double r, String direction, double gap) {
    final double sqrt3 = 1.732050807568877;
    if (direction == "horizontal") {
      final double colStep = (3.0 * r) / 2.0 + (sqrt3 * gap) / 2.0;
      final double rowStep = sqrt3 * r + gap;
      final double x = col * colStep + colStep / 2.0;
      final double y = row * rowStep + rowStep / 2.0 + (col % 2 != 0 ? rowStep / 2.0 : 0.0);
      return Offset(x, y);
    } else {
      final double colStep = sqrt3 * r + gap;
      final double rowStep = (3.0 * r) / 2.0 + (sqrt3 * gap) / 2.0;
      final double x = col * colStep + colStep / 2.0 + (row % 2 != 0 ? colStep / 2.0 : 0.0);
      final double y = row * rowStep + rowStep / 2.0;
      return Offset(x, y);
    }
  }

  // Generate path for a single hexagon
  Path _getHexPath(Offset center, double r, String direction) {
    final double startAngle = direction == "horizontal" ? 0.0 : 30.0;
    final Path path = Path();
    for (int i = 0; i < 6; i++) {
      final double angle = ((startAngle + i * 60.0) * pi) / 180.0;
      final double px = center.dx + r * cos(angle);
      final double py = center.dy + r * sin(angle);
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    path.close();
    return path;
  }

  // Draw dashed line segments
  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, List<double> dashArray, Paint paint) {
    final double dx = p2.dx - p1.dx;
    final double dy = p2.dy - p1.dy;
    final double len = sqrt(dx * dx + dy * dy);
    final double ux = dx / len;
    final double uy = dy / len;
    double distance = 0.0;
    int index = 0;
    bool draw = true;
    while (distance < len) {
      final double step = dashArray[index];
      final double nextDistance = min(len, distance + step);
      if (draw) {
        canvas.drawLine(
          Offset(p1.dx + ux * distance, p1.dy + uy * distance),
          Offset(p1.dx + ux * nextDistance, p1.dy + uy * nextDistance),
          paint,
        );
      }
      distance = nextDistance;
      draw = !draw;
      index = (index + 1) % dashArray.length;
    }
  }

  // Parse SVG strokeDasharray string to a list of dash values
  List<double>? _parseDashArray(String strokeDasharray) {
    final String trimmed = strokeDasharray.trim().replaceAll(RegExp(r'\s+'), ',');
    if (trimmed == "" || trimmed == "none" || trimmed == "0") return null;
    try {
      return trimmed.split(',').map((s) => double.parse(s.trim())).toList();
    } catch (_) {
      return null;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(xOffset, yOffset);

    final double r = radius;
    final double g = gap;
    final String dir = direction;
    final double sqrt3 = 1.732050807568877;

    double colStep, rowStep;
    if (dir == "horizontal") {
      colStep = (3.0 * r) / 2.0 + (sqrt3 * g) / 2.0;
      rowStep = sqrt3 * r + g;
    } else {
      colStep = sqrt3 * r + g;
      rowStep = (3.0 * r) / 2.0 + (sqrt3 * g) / 2.0;
    }

    // Determine grid bounds based on size and offset
    final int minCol = ((-xOffset - r) / colStep).floor() - 1;
    final int maxCol = ((size.width - xOffset + r) / colStep).ceil() + 1;
    final int minRow = ((-yOffset - r) / rowStep).floor() - 1;
    final int maxRow = ((size.height - yOffset + r) / rowStep).ceil() + 1;

    final Paint outlinePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final Paint fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final Paint highlightPaint = Paint()
      ..color = highlightColor
      ..style = PaintingStyle.fill;

    final Paint hoverPaint = Paint()
      ..color = hoverColor
      ..style = PaintingStyle.fill;

    final List<double>? dashArray = _parseDashArray(strokeDasharray);

    // ── 1. Draw Hexagon Fills ──
    for (int col = minCol; col <= maxCol; col++) {
      for (int row = minRow; row <= maxRow; row++) {
        final Offset center = _getHexCenter(col, row, r, dir, g);
        final Point<int> currentPoint = Point(col, row);

        // Highlight preset hexagons
        final bool isHighlighted = hexagons?.any((p) => p == currentPoint) ?? false;
        final bool isHovered = hoveredHex == currentPoint;

        if (isHovered || isHighlighted) {
          final Path path = _getHexPath(center, r - 1.0, dir);
          canvas.drawPath(path, isHovered ? hoverPaint : highlightPaint);
        } else {
          // Subtle default fill
          final Path path = _getHexPath(center, r - 1.0, dir);
          canvas.drawPath(path, fillPaint);
        }
      }
    }

    // ── 2. Draw Hexagon Outlines ──
    if (dashArray == null) {
      // Draw solid polygon lines (highly optimized path drawing)
      for (int col = minCol; col <= maxCol; col++) {
        for (int row = minRow; row <= maxRow; row++) {
          final Offset center = _getHexCenter(col, row, r, dir, g);
          final Path path = _getHexPath(center, r, dir);
          canvas.drawPath(path, outlinePaint);
        }
      }
    } else {
      // Draw dashed edges
      final Set<String> seenEdges = {};
      final double startAngle = dir == "horizontal" ? 0.0 : 30.0;

      for (int col = minCol; col <= maxCol; col++) {
        for (int row = minRow; row <= maxRow; row++) {
          final Offset center = _getHexCenter(col, row, r, dir, g);

          // Get vertex points
          final List<Offset> verts = List.generate(6, (i) {
            final double angle = ((startAngle + i * 60.0) * pi) / 180.0;
            return Offset(center.dx + r * cos(angle), center.dy + r * sin(angle));
          });

          // Draw the 6 edges
          for (int i = 0; i < 6; i++) {
            final Offset a = verts[i];
            final Offset b = verts[(i + 1) % 6];

            // Normalize edge key for deduplication
            final Offset p1 = a.dx < b.dx || (a.dx == b.dx && a.dy <= b.dy) ? a : b;
            final Offset p2 = p1 == a ? b : a;
            final String key = "${p1.dx.toStringAsFixed(3)},${p1.dy.toStringAsFixed(3)}|${p2.dx.toStringAsFixed(3)},${p2.dy.toStringAsFixed(3)}";

            if (!seenEdges.contains(key)) {
              seenEdges.add(key);
              _drawDashedLine(canvas, p1, p2, dashArray, outlinePaint);
            }
          }
        }
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HexagonPatternPainter oldDelegate) {
    return oldDelegate.hoveredHex != hoveredHex;
  }
}
