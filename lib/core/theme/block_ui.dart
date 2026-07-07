import 'package:flutter/material.dart';

/// A heavily styled structural container adhering to the UI UX Pro Max "Vibrant & Block-based" style.
/// Replaces standard Cards and soft Containers.
class BlockContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? color;
  final double? elevation;
  final ShapeBorder? shape;
  final Clip? clipBehavior;
  final Color? borderColor;
  final double borderWidth;
  final Color? shadowColor;
  final double shadowOffset;
  final double? width;
  final double? height;

  const BlockContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor = Colors.white,
    this.color,
    this.elevation,
    this.shape,
    this.clipBehavior,
    this.borderColor,
    this.borderWidth = 4.0,
    this.shadowColor = Colors.black26,
    this.shadowOffset = 8.0,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderColor = borderColor ?? Theme.of(context).colorScheme.primary;
    
    return Container(
      width: width,
      height: height,
      margin: margin ?? const EdgeInsets.all(8.0),
      padding: padding ?? const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: color ?? backgroundColor,
        borderRadius: BorderRadius.zero, // Strict no border radius
        border: Border.all(
          color: effectiveBorderColor,
          width: borderWidth,
        ),
        boxShadow: shadowColor != null
            ? [
                BoxShadow(
                  color: shadowColor!,
                  offset: Offset(shadowOffset, shadowOffset),
                ),
              ]
            : null,
      ),
      clipBehavior: clipBehavior ?? Clip.none,
      child: child,
    );
  }
}

/// A bold, geometric button style matching the block aesthetics.
class BlockButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;

  const BlockButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? Theme.of(context).colorScheme.primary;
    final fg = foregroundColor ?? Theme.of(context).colorScheme.onPrimary;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        elevation: 0, // We rely on a custom container shadow if needed
      ),
      onPressed: onPressed,
      child: child,
    );
  }
}
