import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum MascotPose {
  idle,
  searching,
  thinking,
  celebrating,
  losing,
}

class MascotWidget extends StatefulWidget {
  final MascotPose pose;
  final double size;
  // Named autoAnimate (not "animate") so it doesn't shadow flutter_animate's
  // `.animate()` extension method when chained directly onto a MascotWidget
  // instance, e.g. `MascotWidget(...).animate().fadeIn()`.
  final bool autoAnimate;

  const MascotWidget({
    super.key,
    this.pose = MascotPose.idle,
    this.size = 120.0,
    this.autoAnimate = true,
  });

  @override
  State<MascotWidget> createState() => _MascotWidgetState();
}

class _MascotWidgetState extends State<MascotWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    if (widget.autoAnimate) {
      _animController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final floatOffset = widget.autoAnimate ? (1.0 - _animController.value) * 6.0 : 0.0;
        return Transform.translate(
          offset: Offset(0, -floatOffset),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryYellow.withAlpha(40),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.size / 2),
              child: Image.asset(
                'assets/images/mascot_explorer.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.primaryYellow,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.search_rounded,
                    color: AppColors.bgDarkNavy,
                    size: 40,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
