import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// A highly optimized Flutter port of the TiltedCard React component.
/// Uses a dedicated Ticker and ValueNotifier to ensure buttery-smooth 60fps
/// spring physics without rebuilding the widget tree on hover.
class TiltedCard extends StatefulWidget {
  final Widget child;
  final double rotateAmplitude;

  const TiltedCard({
    super.key,
    required this.child,
    this.rotateAmplitude = 12.0,
  });

  @override
  State<TiltedCard> createState() => _TiltedCardState();
}

class _TiltedCardState extends State<TiltedCard> with SingleTickerProviderStateMixin {
  final ValueNotifier<Matrix4> _transformNotifier = ValueNotifier(
    Matrix4.identity()..setEntry(3, 2, 0.001),
  );
  
  late Ticker _ticker;
  
  double _targetRotX = 0;
  double _targetRotY = 0;
  double _currentRotX = 0;
  double _currentRotY = 0;

  @override
  void initState() {
    super.initState();
    // Continuous ticker for buttery-smooth spring interpolation
    _ticker = createTicker((_) {
      // Spring lerp (stiffness/damping approximation)
      _currentRotX += (_targetRotX - _currentRotX) * 0.15;
      _currentRotY += (_targetRotY - _currentRotY) * 0.15;
      
      final matrix = Matrix4.identity()
        ..setEntry(3, 2, 0.001) // perspective
        ..rotateX(_currentRotX)
        ..rotateY(_currentRotY);
        
      _transformNotifier.value = matrix;
    });
    _ticker.start();
  }

  void _handleHover(PointerEvent event) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final localPosition = renderBox.globalToLocal(event.position);

    final offsetX = localPosition.dx - size.width / 2;
    final offsetY = localPosition.dy - size.height / 2;

    // Convert degrees to radians for Matrix4
    _targetRotX = (offsetY / (size.height / 2)) * -(widget.rotateAmplitude * pi / 180);
    _targetRotY = (offsetX / (size.width / 2)) * (widget.rotateAmplitude * pi / 180);
  }

  void _handleExit(PointerEvent event) {
    _targetRotX = 0;
    _targetRotY = 0;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _transformNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: _handleHover,
      onExit: _handleExit,
      child: ValueListenableBuilder<Matrix4>(
        valueListenable: _transformNotifier,
        builder: (context, transform, child) {
          return Transform(
            transform: transform,
            alignment: FractionalOffset.center,
            // Reusing the child widget directly avoids expensive rebuilds
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}
