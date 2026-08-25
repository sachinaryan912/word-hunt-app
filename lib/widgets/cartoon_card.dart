import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CartoonCard extends StatefulWidget {
  final Widget child;
  final Color? color;
  final Color? bevelColor;
  final Color? borderColor;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final VoidCallback? onTap;

  const CartoonCard({
    super.key,
    required this.child,
    this.color,
    this.bevelColor,
    this.borderColor,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.borderRadius = 20.0,
    this.onTap,
  });

  @override
  State<CartoonCard> createState() => _CartoonCardState();
}

class _CartoonCardState extends State<CartoonCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final cardColor = widget.color ?? AppColors.surfaceCardDark;
    final bevelColor = widget.bevelColor ?? AppColors.surfaceBorderDark;
    final borderColor = widget.borderColor ?? AppColors.surfaceBorderDark.withAlpha(180);

    return Container(
      margin: widget.margin,
      child: GestureDetector(
        onTapDown: widget.onTap == null ? null : (_) => setState(() => _isPressed = true),
        onTapUp: widget.onTap == null
            ? null
            : (_) {
                setState(() => _isPressed = false);
                widget.onTap!();
              },
        onTapCancel: widget.onTap == null ? null : () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 60),
          transform: Matrix4.translationValues(0, _isPressed ? 3.0 : 0.0, 0),
          decoration: BoxDecoration(
            color: bevelColor,
            borderRadius: BorderRadius.circular(widget.borderRadius + 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowSoft,
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 4.0),
            padding: widget.padding,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
