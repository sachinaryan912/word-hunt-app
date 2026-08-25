import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

enum CartoonBackgroundMode {
  dashboard,
  gameplay,
  onboarding,
  matchmaking,
  profile,
  functional,
  loading,
}

class CartoonBackground extends StatefulWidget {
  final Widget child;
  final CartoonBackgroundMode mode;

  const CartoonBackground({
    super.key,
    required this.child,
    this.mode = CartoonBackgroundMode.dashboard,
  });

  @override
  State<CartoonBackground> createState() => _CartoonBackgroundState();
}

class _CartoonBackgroundState extends State<CartoonBackground> with SingleTickerProviderStateMixin {
  late AnimationController _floatingController;

  @override
  void initState() {
    super.initState();
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mode == CartoonBackgroundMode.functional) {
      return Container(
        color: AppColors.bgDarkNavy,
        child: widget.child,
      );
    }

    return AnimatedBuilder(
      animation: _floatingController,
      builder: (context, child) {
        return Stack(
          children: [
            // Base Gradient Background
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: widget.mode == CartoonBackgroundMode.gameplay
                        ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                        : [const Color(0xFF0F172A), const Color(0xFF1E1E38), const Color(0xFF0F172A)],
                  ),
                ),
              ),
            ),

            // Vector Decorative Elements (Floating Letters, Tiles, Stars)
            if (widget.mode != CartoonBackgroundMode.gameplay)
              Positioned.fill(
                child: CustomPaint(
                  painter: _CartoonVectorDecorationPainter(
                    mode: widget.mode,
                    animationValue: _floatingController.value,
                  ),
                ),
              ),

            // Main Content Body
            widget.child,
          ],
        );
      },
      child: widget.child,
    );
  }
}

class _CartoonVectorDecorationPainter extends CustomPainter {
  final CartoonBackgroundMode mode;
  final double animationValue;

  _CartoonVectorDecorationPainter({
    required this.mode,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rand = math.Random(42);
    final letters = ['W', 'O', 'R', 'D', 'H', 'U', 'N', 'T', 'A', 'Z'];

    // Draw floating alphabet tiles in background
    final numItems = mode == CartoonBackgroundMode.onboarding || mode == CartoonBackgroundMode.dashboard ? 12 : 6;
    for (int i = 0; i < numItems; i++) {
      final baseX = (rand.nextDouble() * size.width);
      final baseY = (rand.nextDouble() * size.height);
      final letter = letters[i % letters.length];

      // Offset based on animation
      final floatY = math.sin((animationValue * math.pi * 2) + i) * 12.0;
      final floatX = math.cos((animationValue * math.pi * 2) + i) * 6.0;

      final pos = Offset(baseX + floatX, baseY + floatY);

      // Draw subtle letter bubble/tile
      final tilePaint = Paint()
        ..color = (i % 2 == 0 ? AppColors.royalBlue : AppColors.primaryYellow).withAlpha(25)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: pos, width: 36, height: 36),
          const Radius.circular(10),
        ),
        tilePaint,
      );

      final textSpan = TextSpan(
        text: letter,
        style: GoogleFonts.fredoka(
          fontSize: 18,
          color: Colors.white.withAlpha(35),
          fontWeight: FontWeight.w700,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(pos.dx - textPainter.width / 2, pos.dy - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CartoonVectorDecorationPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
