import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/word_search_grid.dart';
import '../theme/app_colors.dart';

class WordListView extends StatelessWidget {
  final List<String> targetWords;
  final List<FoundWordPath> foundWords;

  const WordListView({
    super.key,
    required this.targetWords,
    required this.foundWords,
  });

  @override
  Widget build(BuildContext context) {
    final foundSet = foundWords.map((f) => f.word.toUpperCase()).toSet();

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: targetWords.map((word) {
        final isFound = foundSet.contains(word.toUpperCase());

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isFound ? AppColors.freshGreenBevel : AppColors.surfaceBorderDark,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isFound
                ? [
                    BoxShadow(
                      color: AppColors.freshGreen.withAlpha(100),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(bottom: 2.0),
            decoration: BoxDecoration(
              color: isFound ? AppColors.freshGreen : AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isFound ? Colors.white : AppColors.surfaceBorderDark,
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isFound) ...[
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  word.toUpperCase(),
                  style: GoogleFonts.fredoka(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: isFound ? Colors.white : AppColors.textPrimaryLight,
                    decoration: isFound ? TextDecoration.lineThrough : TextDecoration.none,
                    decorationColor: Colors.white,
                    decorationThickness: 2.5,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
