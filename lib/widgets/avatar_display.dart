import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

const List<Color> avatarPalette = [
  AppColors.primaryYellow,
  AppColors.royalBlue,
  AppColors.freshGreen,
  AppColors.primaryOrange,
  AppColors.purple,
  AppColors.coral,
  AppColors.skyBlue,
];

int _avatarIndex(String avatarId) => int.tryParse(avatarId.replaceFirst('avtar', '')) ?? 0;

Color colorForAvatarId(String avatarId) => avatarPalette[_avatarIndex(avatarId) % avatarPalette.length];

/// Renders a purchasable avatar from the SVG set at
/// `assets/avtars/avtarN.svg` (word-hunting-app/assets/avtars), falling back
/// to a generated placeholder if a given id has no matching file.
class AvatarDisplay extends StatelessWidget {
  final String? avatarId;
  final String fallbackInitial;
  final double size;

  const AvatarDisplay({super.key, required this.avatarId, required this.fallbackInitial, this.size = 54});

  @override
  Widget build(BuildContext context) {
    final id = avatarId;
    if (id == null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primaryYellow, width: 1.5),
        ),
        child: Center(
          child: Text(
            fallbackInitial,
            style: GoogleFonts.fredoka(fontSize: size * 0.4, fontWeight: FontWeight.w700, color: AppColors.primaryYellow),
          ),
        ),
      );
    }
    return ClipOval(
      child: SvgPicture.asset(
        'assets/avtars/$id.svg',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => avatarPlaceholder(id, size),
      ),
    );
  }
}

Widget avatarPlaceholder(String avatarId, double size) {
  final color = colorForAvatarId(avatarId);
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color.withAlpha(70), shape: BoxShape.circle, border: Border.all(color: color, width: 2)),
    child: Center(
      child: Text(
        '${_avatarIndex(avatarId)}',
        style: GoogleFonts.fredoka(fontSize: size * 0.35, fontWeight: FontWeight.w700, color: color),
      ),
    ),
  );
}
