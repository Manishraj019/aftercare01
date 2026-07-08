import 'dart:math';
import 'package:flutter/material.dart';

class BorderGlow extends StatefulWidget {
  final Widget child;
  final double edgeSensitivity;
  final Color glowColor;
  final Color backgroundColor;
  final double borderRadius;
  final double glowRadius;
  final double glowIntensity;
  final double coneSpread;
  final bool animated;
  final List<Color> colors;
  final double fillOpacity;

  const BorderGlow({
    super.key,
    required this.child,
    this.edgeSensitivity = 30.0,
    this.glowColor = const Color(0xFFFDE68A),
    this.backgroundColor = const Color(0xFF120F17),
    this.borderRadius = 28.0,
    this.glowRadius = 40.0,
    this.glowIntensity = 1.0,
    this.coneSpread = 25.0,
    this.animated = true,
    this.colors = const [
      Color(0xFFc084fc),
      Color(0xFFf472b6),
      Color(0xFF38bdf8),
    ],
    this.fillOpacity = 0.5,
  });

  @override
  State<BorderGlow> createState() => _BorderGlowState();
}

class _BorderGlowState extends State<BorderGlow> with TickerProviderStateMixin {
  double _edgeProximity = 0.0;
  double _cursorAngle = 45.0; // degrees
  bool _isHovered = false;

  late AnimationController _sweepController;
  late AnimationController _proximityController;
  late Animation<double> _sweepAnimation;
  late Animation<double> _proximityAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    if (widget.animated) {
      _startSweepAnimation();
    }
  }

  void _initAnimations() {
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _proximityController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _sweepAnimation = Tween<double>(begin: 110.0, end: 465.0).animate(
      CurvedAnimation(parent: _sweepController, curve: Curves.easeInOutCubic),
    )..addListener(() {
        if (!_isHovered) {
          setState(() {
            _cursorAngle = _sweepAnimation.value % 360;
          });
        }
      });

    _proximityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _proximityController, curve: Curves.easeInOutCubic),
    )..addListener(() {
        if (!_isHovered) {
          setState(() {
            _edgeProximity = _proximityAnimation.value;
          });
        }
      });
  }

  void _startSweepAnimation() async {
    _proximityController.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      await _sweepController.forward(from: 0.0);
    }
    if (mounted) {
      await _proximityController.reverse();
    }
  }

  @override
  void dispose() {
    _sweepController.dispose();
    _proximityController.dispose();
    super.dispose();
  }

  void _handlePointerMove(PointerEvent event) {
    _isHovered = true;
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    
    final size = box.size;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final dx = event.localPosition.dx - cx;
    final dy = event.localPosition.dy - cy;

    double kx = double.infinity;
    double ky = double.infinity;
    if (dx != 0) kx = cx / dx.abs();
    if (dy != 0) ky = cy / dy.abs();
    final edge = (1 / min(kx, ky)).clamp(0.0, 1.0);

    double degrees = 0;
    if (dx != 0 || dy != 0) {
      final radians = atan2(dy, dx);
      degrees = radians * (180 / pi) + 90;
      if (degrees < 0) degrees += 360;
    }

    setState(() {
      _edgeProximity = edge;
      _cursorAngle = degrees;
    });
  }

  void _handlePointerExit(PointerEvent event) {
    _isHovered = false;
    // Fade out proximity when leaving
    _proximityAnimation = Tween<double>(begin: _edgeProximity, end: 0.0).animate(
      CurvedAnimation(parent: _proximityController, curve: Curves.easeOut),
    );
    _proximityController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    // Opacity formulas based on CSS calc
    // opacity: calc((var(--edge-proximity) - var(--color-sensitivity)) / (100 - var(--color-sensitivity)));
    // We normalize to 0.0 - 1.0
    final colorSensitivity = (widget.edgeSensitivity + 20) / 100.0;
    final normalizedProximity = _edgeProximity;
    
    double glowOpacity = (normalizedProximity - (widget.edgeSensitivity / 100)) / (1.0 - (widget.edgeSensitivity / 100));
    glowOpacity = glowOpacity.clamp(0.0, 1.0);

    double meshOpacity = (normalizedProximity - colorSensitivity) / (1.0 - colorSensitivity);
    meshOpacity = meshOpacity.clamp(0.0, 1.0);

    return MouseRegion(
      onHover: _handlePointerMove,
      onExit: _handlePointerExit,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
              // Outer Glow Layer
              if (glowOpacity > 0)
                Positioned(
                  top: -widget.glowRadius * 2,
                  left: -widget.glowRadius * 2,
                  right: -widget.glowRadius * 2,
                  bottom: -widget.glowRadius * 2,
                  child: ShaderMask(
                    shaderCallback: (rect) {
                      return SweepGradient(
                        transform: GradientRotation((_cursorAngle - 90) * pi / 180),
                        stops: const [0.0, 0.025, 0.1, 0.9, 0.975, 1.0],
                        colors: const [
                          Colors.black,
                          Colors.black,
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black,
                          Colors.black,
                        ],
                      ).createShader(rect);
                    },
                    blendMode: BlendMode.dstIn,
                    child: Opacity(
                      opacity: glowOpacity,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            top: widget.glowRadius * 2,
                            left: widget.glowRadius * 2,
                            right: widget.glowRadius * 2,
                            bottom: widget.glowRadius * 2,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(widget.borderRadius),
                                boxShadow: [
                                  BoxShadow(
                                    color: widget.glowColor.withOpacity(0.5 * widget.glowIntensity),
                                    blurRadius: widget.glowRadius,
                                    spreadRadius: 2,
                                  ),
                                  BoxShadow(
                                    color: widget.glowColor.withOpacity(0.2 * widget.glowIntensity),
                                    blurRadius: widget.glowRadius / 2,
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Main Card Base
              Container(
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 32, offset: const Offset(0, 16)),
                  ],
                ),
              ),

              // Mesh Gradient Border
              if (meshOpacity > 0)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    child: ShaderMask(
                      shaderCallback: (rect) {
                        final spread = widget.coneSpread / 100;
                        return SweepGradient(
                          transform: GradientRotation((_cursorAngle - 90) * pi / 180),
                          stops: [
                            spread,
                            spread + 0.15,
                            (1.0 - spread - 0.15).clamp(0.0, 1.0),
                            (1.0 - spread).clamp(0.0, 1.0),
                            1.0
                          ],
                          colors: const [
                            Colors.black,
                            Colors.transparent,
                            Colors.transparent,
                            Colors.black,
                            Colors.black,
                          ],
                        ).createShader(rect);
                      },
                      blendMode: BlendMode.dstIn,
                      child: Opacity(
                        opacity: meshOpacity,
                        child: CustomPaint(
                          painter: _MeshGradientPainter(colors: widget.colors),
                        ),
                      ),
                    ),
                  ),
                ),

              // Inner Content
              Positioned.fill(
                child: Container(
                  margin: const EdgeInsets.all(1.5), // Inner border width gap
                  decoration: BoxDecoration(
                    color: widget.backgroundColor,
                    borderRadius: BorderRadius.circular(widget.borderRadius - 1.5),
                  ),
                  child: widget.child,
                ),
              ),
            ],
          ),
        );
  }
}

class _MeshGradientPainter extends CustomPainter {
  final List<Color> colors;

  _MeshGradientPainter({required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    
    // Map colors
    final c0 = colors[0];
    final c1 = colors[colors.length > 1 ? 1 : 0];
    final c2 = colors[colors.length > 2 ? 2 : 0];
    final map = [c0, c1, c2, c0, c1, c2, c1];
    
    final positions = [
      Offset(w * 0.80, h * 0.55),
      Offset(w * 0.69, h * 0.34),
      Offset(w * 0.08, h * 0.06),
      Offset(w * 0.41, h * 0.38),
      Offset(w * 0.86, h * 0.85),
      Offset(w * 0.82, h * 0.18),
      Offset(w * 0.51, h * 0.04),
    ];

    for (int i = 0; i < 7; i++) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [map[i], Colors.transparent],
        ).createShader(Rect.fromCircle(center: positions[i], radius: max(w, h) * 0.6));
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MeshGradientPainter oldDelegate) => false;
}
