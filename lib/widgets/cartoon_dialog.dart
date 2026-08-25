import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import 'cartoon_button.dart';
import 'cartoon_card.dart';
import 'mascot_widget.dart';

class CartoonDialog extends StatelessWidget {
  final String title;
  final String? subtitle;
  final MascotPose? mascotPose;
  final Widget? content;
  final String? primaryButtonText;
  final VoidCallback? onPrimaryPressed;
  final String? secondaryButtonText;
  final VoidCallback? onSecondaryPressed;
  final bool preventPop;

  const CartoonDialog({
    super.key,
    required this.title,
    this.subtitle,
    this.mascotPose,
    this.content,
    this.primaryButtonText,
    this.onPrimaryPressed,
    this.secondaryButtonText,
    this.onSecondaryPressed,
    this.preventPop = false,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? subtitle,
    MascotPose? mascotPose,
    Widget? content,
    String? primaryButtonText,
    VoidCallback? onPrimaryPressed,
    String? secondaryButtonText,
    VoidCallback? onSecondaryPressed,
    bool barrierDismissible = true,
    bool preventPop = false,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black.withAlpha(180),
      builder: (_) => CartoonDialog(
        title: title,
        subtitle: subtitle,
        mascotPose: mascotPose,
        content: content,
        primaryButtonText: primaryButtonText,
        onPrimaryPressed: onPrimaryPressed,
        secondaryButtonText: secondaryButtonText,
        onSecondaryPressed: onSecondaryPressed,
        preventPop: preventPop,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !preventPop,
      child: Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: CartoonCard(
        color: AppColors.surfaceCardDark,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (mascotPose != null) ...[
              MascotWidget(pose: mascotPose!, size: 90),
              const SizedBox(height: 12),
            ],
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryYellow,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
            if (content != null) ...[
              const SizedBox(height: 16),
              content!,
            ],
            if (primaryButtonText != null) ...[
              const SizedBox(height: 20),
              CartoonButton(
                text: primaryButtonText!,
                onPressed: onPrimaryPressed,
                variant: CartoonButtonVariant.primary,
                width: double.infinity,
                height: 48,
              ),
            ],
            if (secondaryButtonText != null) ...[
              const SizedBox(height: 10),
              CartoonButton(
                text: secondaryButtonText!,
                onPressed: onSecondaryPressed,
                variant: CartoonButtonVariant.outline,
                width: double.infinity,
                height: 44,
              ),
            ],
          ],
        ),
      ),
      ),
    );
  }
}
