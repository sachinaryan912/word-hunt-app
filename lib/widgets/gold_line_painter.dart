import 'package:flutter/material.dart';
import '../models/word_search_grid.dart';
import '../theme/app_colors.dart';

/// Draws only the in-progress drag-selection stroke. Confirmed found words
/// are no longer drawn as a line here — that used to paint an opaque
/// colored stroke directly over the letter glyphs (see [markerColors] for
/// the colors, now used by LetterGridWidget to tint found-cell tiles
/// instead), which made letters shared between two words unreadable once
/// the first word's line covered them. Tinting each cell's own tile
/// background keeps the text crisp on top, at any overlap.
class GoldLinePainter extends CustomPainter {
  final int rows;
  final int cols;
  final List<FoundWordPath> foundWords;
  final List<GridPos> currentSelection;

  GoldLinePainter({
    required this.rows,
    required this.cols,
    required this.foundWords,
    required this.currentSelection,
  });

  static const List<Color> markerColors = [
    Color(0xFFFFD13B), // Warm Yellow
    Color(0xFF22C55E), // Fresh Green
    Color(0xFF38BDF8), // Sky Blue
    Color(0xFFFF6B6B), // Coral
    Color(0xFF8B5CF6), // Purple
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (rows <= 0 || cols <= 0) return;

    final cellWidth = size.width / cols;
    final cellHeight = size.height / rows;

    Offset getCellCenter(GridPos pos) {
      final x = (pos.col + 0.5) * cellWidth;
      final y = (pos.row + 0.5) * cellHeight;
      return Offset(x, y);
    }

    // Draw active drag selection path with active golden marker stroke
    if (currentSelection.length >= 2) {
      final activePaint = Paint()
        ..color = AppColors.primaryYellow.withAlpha(220)
        ..strokeWidth = 14.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final activeGlowPaint = Paint()
        ..color = AppColors.primaryOrange.withAlpha(140)
        ..strokeWidth = 18.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final selPath = Path();
      final startOffset = getCellCenter(currentSelection.first);
      selPath.moveTo(startOffset.dx, startOffset.dy);

      for (int i = 1; i < currentSelection.length; i++) {
        final point = getCellCenter(currentSelection[i]);
        selPath.lineTo(point.dx, point.dy);
      }

      canvas.drawPath(selPath, activeGlowPaint);
      canvas.drawPath(selPath, activePaint);
    }
  }

  @override
  bool shouldRepaint(covariant GoldLinePainter oldDelegate) {
    return oldDelegate.foundWords != foundWords ||
        oldDelegate.currentSelection != currentSelection ||
        oldDelegate.rows != rows ||
        oldDelegate.cols != cols;
  }
}
