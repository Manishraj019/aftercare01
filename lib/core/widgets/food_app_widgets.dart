import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:restaurantos/core/theme/app_theme.dart';

// ─── Glassmorphism Container ───────────────────────────────────────
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Border? border;
  final Color? color;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 15.0,
    this.opacity = 0.5,
    this.borderRadius,
    this.padding,
    this.margin,
    this.border,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final defaultRadius = borderRadius ?? BorderRadius.circular(16);
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: defaultRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: color ?? AppTheme.bgDarkPanel.withValues(alpha: opacity),
              borderRadius: defaultRadius,
              border: border ?? Border.all(color: AppTheme.borderLight, width: 1),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ─── Luxury Primary Button ──────────────────────────────────────────
class FoodPrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool isGold;

  const FoodPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.isGold = true,
  });

  @override
  State<FoodPrimaryButton> createState() => _FoodPrimaryButtonState();
}

class _FoodPrimaryButtonState extends State<FoodPrimaryButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isGold ? AppTheme.primaryGold : AppTheme.primaryBurgundy;
    final textColor = widget.isGold ? AppTheme.bgDarkCharcoal : AppTheme.pureWhite;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()..scale(_isHovered && widget.onPressed != null ? 1.02 : 1.0),
        child: ElevatedButton(
          onPressed: widget.isLoading ? null : widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: bgColor,
            foregroundColor: textColor,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8), // Refined smaller radius for luxury
            ),
            elevation: _isHovered ? 8 : 0,
            shadowColor: bgColor.withValues(alpha: 0.5),
          ),
          child: widget.isLoading
              ? SizedBox(
                  height: 24, width: 24,
                  child: CircularProgressIndicator(color: textColor, strokeWidth: 2),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.label,
                      style: GoogleFonts.karla(
                        fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: textColor,
                      ),
                    ),
                    if (widget.icon != null) ...[
                      const SizedBox(width: 8),
                      Icon(widget.icon, size: 20, color: textColor),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

// ─── Luxury Veg / Non-Veg Icon ─────────────────────────────────────
class VegNonVegIcon extends StatelessWidget {
  final bool isVeg;
  final double size;

  const VegNonVegIcon({super.key, required this.isVeg, this.size = 16});

  @override
  Widget build(BuildContext context) {
    final color = isVeg ? AppTheme.vegGreen : AppTheme.nonVegRed;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: Container(
        width: size * 0.5,
        height: size * 0.5,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ─── Luxury Add / Stepper Button ────────────────────────────────────
class AddStepperButton extends StatelessWidget {
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const AddStepperButton({
    super.key,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (quantity == 0) {
      return GestureDetector(
        onTap: onAdd,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.bgDarkCharcoal,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.primaryGold, width: 1),
            boxShadow: [
              BoxShadow(color: AppTheme.primaryGold.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2))
            ],
          ),
          child: Text(
            'ADD',
            style: GoogleFonts.karla(
              color: AppTheme.primaryGold,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryGold,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: AppTheme.primaryGold.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onRemove,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Icon(Icons.remove, color: AppTheme.bgDarkCharcoal, size: 18),
            ),
          ),
          SizedBox(
            width: 24,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: GoogleFonts.karla(
                color: AppTheme.bgDarkCharcoal,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          GestureDetector(
            onTap: onAdd,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Icon(Icons.add, color: AppTheme.bgDarkCharcoal, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Luxury Food Image Loader (Supports Network & Base64 Uploads) ───
class FoodImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? errorWidget;

  const FoodImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return errorWidget ?? Container(
        color: AppTheme.bgDarkPanel,
        child: const Icon(Icons.restaurant, size: 32, color: AppTheme.textMuted),
      );
    }

    if (imageUrl.startsWith('data:image') && imageUrl.contains('base64,')) {
      try {
        final base64String = imageUrl.split('base64,').last;
        final decodedBytes = base64Decode(base64String);
        return Image.memory(
          decodedBytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stack) => errorWidget ?? Container(
            color: AppTheme.bgDarkPanel,
            child: const Icon(Icons.restaurant, size: 32, color: AppTheme.textMuted),
          ),
        );
      } catch (_) {
        return errorWidget ?? Container(
          color: AppTheme.bgDarkPanel,
          child: const Icon(Icons.restaurant, size: 32, color: AppTheme.textMuted),
        );
      }
    }

    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stack) => errorWidget ?? Container(
        color: AppTheme.bgDarkPanel,
        child: const Icon(Icons.restaurant, size: 32, color: AppTheme.textMuted),
      ),
    );
  }
}

