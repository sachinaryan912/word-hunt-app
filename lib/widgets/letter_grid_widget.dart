import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/word_search_grid.dart';
import '../theme/app_colors.dart';
import 'gold_line_painter.dart';

class LetterGridWidget extends StatefulWidget {
  final WordSearchGrid grid;
  final Function(String word, List<GridPos> path)? onWordSelect;

  const LetterGridWidget({
    super.key,
    required this.grid,
    this.onWordSelect,
  });

  @override
  State<LetterGridWidget> createState() => _LetterGridWidgetState();
}

class _LetterGridWidgetState extends State<LetterGridWidget> {
  final List<GridPos> _currentSelection = [];
  GridPos? _startPos;

  void _onPanStart(DragDownDetails details, Size size) {
    final pos = _getGridPos(details.localPosition, size);
    if (pos != null) {
      setState(() {
        _startPos = pos;
        _currentSelection.clear();
        _currentSelection.add(pos);
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    if (_startPos == null) return;
    final currentPos = _getGridPos(details.localPosition, size);
    if (currentPos == null) return;

    final line = _calculateStraightLine(_startPos!, currentPos);
    if (line.isNotEmpty) {
      setState(() {
        _currentSelection.clear();
        _currentSelection.addAll(line);
      });
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_currentSelection.isNotEmpty) {
      final word = _currentSelection.map((p) => widget.grid.grid[p.row][p.col]).join();
      if (widget.onWordSelect != null) {
        widget.onWordSelect!(word, List.from(_currentSelection));
      }
    }
    setState(() {
      _startPos = null;
      _currentSelection.clear();
    });
  }

  /// The marker color of the found word this cell belongs to, if any. When a
  /// cell is shared by two found words, the later one wins — matching how
  /// the connecting-line painter used to layer them.
  Color? _foundColorFor(GridPos pos) {
    Color? color;
    for (int idx = 0; idx < widget.grid.foundWords.length; idx++) {
      if (widget.grid.foundWords[idx].path.contains(pos)) {
        color = GoldLinePainter.markerColors[idx % GoldLinePainter.markerColors.length];
      }
    }
    return color;
  }

  GridPos? _getGridPos(Offset localPosition, Size size) {
    final cellWidth = size.width / widget.grid.cols;
    final cellHeight = size.height / widget.grid.rows;

    final col = (localPosition.dx / cellWidth).floor();
    final row = (localPosition.dy / cellHeight).floor();

    if (row >= 0 && row < widget.grid.rows && col >= 0 && col < widget.grid.cols) {
      return GridPos(row, col);
    }
    return null;
  }

  List<GridPos> _calculateStraightLine(GridPos start, GridPos end) {
    final dRow = end.row - start.row;
    final dCol = end.col - start.col;

    if (dRow != 0 && dCol != 0 && dRow.abs() != dCol.abs()) {
      return [];
    }

    final stepRow = dRow == 0 ? 0 : dRow ~/ dRow.abs();
    final stepCol = dCol == 0 ? 0 : dCol ~/ dCol.abs();

    final count = (dRow != 0 ? dRow.abs() : dCol.abs()) + 1;
    final line = <GridPos>[];

    for (int i = 0; i < count; i++) {
      line.add(GridPos(start.row + (i * stepRow), start.col + (i * stepCol)));
    }
    return line;
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: widget.grid.cols / widget.grid.rows,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);

          return GestureDetector(
            onPanDown: (d) => _onPanStart(d, size),
            onPanUpdate: (d) => _onPanUpdate(d, size),
            onPanEnd: _onPanEnd,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceCardDark,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadowHard,
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
                border: Border.all(color: AppColors.surfaceBorderDark, width: 2.0),
              ),
              clipBehavior: Clip.antiAlias,
              padding: const EdgeInsets.all(6),
              child: Stack(
                children: [
                  // 2.5D Tactile Grid Tiles
                  Column(
                    children: List.generate(widget.grid.rows, (r) {
                      return Expanded(
                        child: Row(
                          children: List.generate(widget.grid.cols, (c) {
                            final pos = GridPos(r, c);
                            final isSelected = _currentSelection.contains(pos);
                            final foundColor = isSelected ? null : _foundColorFor(pos);

                            final topTileColor = isSelected
                                ? AppColors.primaryYellow
                                : (foundColor?.withAlpha(90) ?? AppColors.surfaceElevated);
                            final bevelTileColor = isSelected
                                ? AppColors.primaryYellowBevel
                                : (foundColor?.withAlpha(150) ?? AppColors.surfaceBorderDark);
                            final textColor = isSelected
                                ? AppColors.bgDarkNavy
                                : AppColors.textPrimaryLight;

                            return Expanded(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 100),
                                margin: const EdgeInsets.all(2.0),
                                transform: Matrix4.identity()
                                  ..scale(isSelected ? 1.05 : 1.0, isSelected ? 1.05 : 1.0),
                                decoration: BoxDecoration(
                                  color: bevelTileColor,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: AppColors.primaryYellow.withAlpha(140),
                                            blurRadius: 10,
                                            spreadRadius: 1,
                                          ),
                                        ]
                                      : [
                                          const BoxShadow(
                                            color: AppColors.shadowSoft,
                                            blurRadius: 3,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                ),
                                child: Container(
                                  margin: EdgeInsets.only(bottom: isSelected ? 1.0 : 3.0),
                                  decoration: BoxDecoration(
                                    color: topTileColor,
                                    borderRadius: BorderRadius.circular(9),
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.white.withAlpha(20),
                                      width: 1.0,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    widget.grid.grid[r][c],
                                    style: GoogleFonts.fredoka(
                                      color: textColor,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      );
                    }),
                  ),

                  // Overlay Cartoon Highlighter Marker Stroke Painter
                  Positioned.fill(
                    child: CustomPaint(
                      painter: GoldLinePainter(
                        rows: widget.grid.rows,
                        cols: widget.grid.cols,
                        foundWords: widget.grid.foundWords,
                        currentSelection: _currentSelection,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
