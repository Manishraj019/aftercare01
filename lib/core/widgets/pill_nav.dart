import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PillNavItem {
  final String label;
  final String value;

  const PillNavItem({required this.label, required this.value});
}

class PillNav extends StatefulWidget {
  final List<PillNavItem> items;
  final String selectedValue;
  final ValueChanged<String> onChanged;
  final Color baseColor;
  final Color pillColor;
  final Color hoveredPillTextColor;
  final Color pillTextColor;

  const PillNav({
    super.key,
    required this.items,
    required this.selectedValue,
    required this.onChanged,
    this.baseColor = Colors.black,
    this.pillColor = const Color(0xFFF3F4F6),
    this.hoveredPillTextColor = Colors.white,
    this.pillTextColor = Colors.black,
  });

  @override
  State<PillNav> createState() => _PillNavState();
}

class _PillNavState extends State<PillNav> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3), // var(--pill-gap) padding
      decoration: BoxDecoration(
        color: widget.pillColor,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: widget.items.map((item) {
          final isSelected = widget.selectedValue == item.value;
          return _Pill(
            item: item,
            isSelected: isSelected,
            onTap: () => widget.onChanged(item.value),
            baseColor: widget.baseColor,
            hoveredTextColor: widget.hoveredPillTextColor,
            textColor: widget.pillTextColor,
          );
        }).toList(),
      ),
    );
  }
}

class _Pill extends StatefulWidget {
  final PillNavItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final Color baseColor;
  final Color hoveredTextColor;
  final Color textColor;

  const _Pill({
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.baseColor,
    required this.hoveredTextColor,
    required this.textColor,
  });

  @override
  State<_Pill> createState() => _PillState();
}

class _PillState extends State<_Pill> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300), // GSAP is 2s but 300ms is standard for Flutter UI
    );
  }

  @override
  void didUpdateWidget(_Pill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _controller.forward();
    } else if (!widget.isSelected && oldWidget.isSelected) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        if (!widget.isSelected) {
          _controller.forward();
        }
      },
      onExit: (_) {
        if (!widget.isSelected) {
          _controller.reverse();
        }
      },
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final progress = CurvedAnimation(
              parent: _controller,
              curve: Curves.easeOutCubic, // 'power3.easeOut' equivalent
            ).value;

            return CustomPaint(
              painter: _HoverCirclePainter(
                progress: progress,
                baseColor: widget.baseColor,
              ),
              child: Container(
                // Exact padding from CSS: padding: 0 18px (var(--pill-pad-x))
                padding: const EdgeInsets.symmetric(horizontal: 18),
                height: 36, // Approximate var(--nav-h) inner height minus padding
                alignment: Alignment.center,
                clipBehavior: Clip.hardEdge,
                decoration: const BoxDecoration(
                  color: Colors.transparent, // Background painted by CustomPaint
                ),
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.hardEdge,
                  children: [
                    // Original Label (translates up by -(h+8))
                    Transform.translate(
                      offset: Offset(0, -progress * (36.0 + 8.0)),
                      child: Text(
                        widget.item.label.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          letterSpacing: 0.2,
                          color: widget.textColor,
                          height: 1, // line-height: 0 approx
                        ),
                      ),
                    ),
                    
                    // Hover Label (translates up from h+100 to 0)
                    Transform.translate(
                      offset: Offset(0, (1 - progress) * (36.0 + 100.0)),
                      child: Opacity(
                        opacity: progress > 0.05 ? 1.0 : 0.0, // Fade in instantly like GSAP set
                        child: Text(
                          widget.item.label.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            letterSpacing: 0.2,
                            color: widget.hoveredTextColor,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HoverCirclePainter extends CustomPainter {
  final double progress;
  final Color baseColor;

  _HoverCirclePainter({
    required this.progress,
    required this.baseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0.0) return;

    final double w = size.width;
    final double h = size.height;

    // Mathematical calculations exactly mirroring the React GSAP implementation:
    // const R = ((w * w) / 4 + h * h) / (2 * h);
    // const D = Math.ceil(2 * R) + 2;
    // const delta = Math.ceil(R - Math.sqrt(Math.max(0, R * R - (w * w) / 4))) + 1;
    final double rVal = ((w * w) / 4 + h * h) / (2 * h);
    final double dVal = (2 * rVal).ceilToDouble() + 2;
    final double maxVal = rVal * rVal - (w * w) / 4;
    final double deltaVal = (rVal - sqrt(max(0.0, maxVal))).ceilToDouble() + 1;

    // The transform origin in GSAP is at `50% originYpx` where originY = D - delta
    // Translated to absolute canvas coordinates, this is exactly the bottom-center of the pill (w/2, h)
    final double centerY = deltaVal - dVal / 2;

    // Clip to pill bounds (borderRadius: 9999px) so the circle doesn't bleed outside the pill
    final RRect pillRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      const Radius.circular(9999),
    );
    canvas.clipRRect(pillRect);

    canvas.save();
    // Translate to bottom center for the transform origin
    canvas.translate(w / 2, h);
    // Scale by 1.2 like GSAP: tl.to(circle, { scale: 1.2 ... })
    canvas.scale(progress * 1.2);

    final paint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.fill;

    // Draw the calculated circle
    canvas.drawCircle(Offset(0, centerY), dVal / 2, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HoverCirclePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.baseColor != baseColor;
  }
}
