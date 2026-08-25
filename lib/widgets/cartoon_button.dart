import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

enum CartoonButtonVariant {
  primary,
  secondary,
  accentGreen,
  accentOrange,
  accentRed,
  outline,
}

class CartoonButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Widget? leading;
  final CartoonButtonVariant variant;
  final bool isLoading;
  final double height;
  final double? width;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const CartoonButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.leading,
    this.variant = CartoonButtonVariant.primary,
    this.isLoading = false,
    this.height = 52.0,
    this.width,
    this.fontSize = 16.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
  });

  @override
  State<CartoonButton> createState() => _CartoonButtonState();
}

class _CartoonButtonState extends State<CartoonButton> {
  bool _isPressed = false;

  (Color topColor, Color bevelColor, Color textColor) _getColors() {
    if (widget.onPressed == null) {
      return (const Color(0xFF64748B), const Color(0xFF334155), const Color(0xFF94A3B8));
    }
    switch (widget.variant) {
      case CartoonButtonVariant.primary:
        return (AppColors.primaryYellow, AppColors.primaryYellowBevel, AppColors.bgDarkNavy);
      case CartoonButtonVariant.secondary:
        return (AppColors.royalBlue, AppColors.royalBlueBevel, Colors.white);
      case CartoonButtonVariant.accentGreen:
        return (AppColors.freshGreen, AppColors.freshGreenBevel, Colors.white);
      case CartoonButtonVariant.accentOrange:
        return (AppColors.primaryOrange, AppColors.primaryOrangeBevel, Colors.white);
      case CartoonButtonVariant.accentRed:
        return (AppColors.coral, AppColors.coralBevel, Colors.white);
      case CartoonButtonVariant.outline:
        return (AppColors.surfaceCardDark, AppColors.surfaceBorderDark, AppColors.textPrimaryLight);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (topColor, bevelColor, textColor) = _getColors();
    final isDisabled = widget.onPressed == null || widget.isLoading;

    return GestureDetector(
      onTapDown: isDisabled ? null : (_) => setState(() => _isPressed = true),
      onTapUp: isDisabled
          ? null
          : (_) {
              setState(() => _isPressed = false);
              widget.onPressed?.call();
            },
      onTapCancel: isDisabled ? null : () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        curve: Curves.easeOut,
        width: widget.width,
        height: widget.height,
        margin: EdgeInsets.only(top: _isPressed ? 4.0 : 0.0),
        decoration: BoxDecoration(
          color: bevelColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: _isPressed || isDisabled
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withAlpha(90),
                    blurRadius: 8,
                    offset: const Offset(0, 5),
                  ),
                ],
        ),
        child: Container(
          height: widget.height - (_isPressed ? 1.0 : 5.0),
          margin: EdgeInsets.only(bottom: _isPressed ? 1.0 : 5.0),
          padding: widget.padding,
          decoration: BoxDecoration(
            color: topColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withAlpha(60),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isLoading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(textColor),
                  ),
                )
              else ...[
                if (widget.leading != null) ...[
                  widget.leading!,
                  const SizedBox(width: 8),
                ] else if (widget.icon != null) ...[
                  Icon(widget.icon, color: textColor, size: widget.fontSize + 4),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.text,
                  style: GoogleFonts.fredoka(
                    color: textColor,
                    fontSize: widget.fontSize,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
