class GridPos {
  final int row;
  final int col;

  const GridPos(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GridPos && runtimeType == other.runtimeType && row == other.row && col == other.col;

  @override
  int get hashCode => row.hashCode ^ col.hashCode;

  @override
  String toString() => 'GridPos($row, $col)';
}

class FoundWordPath {
  final String word;
  final List<GridPos> path;
  final String claimedBy; // 'player', 'opponent', or 'solo'

  const FoundWordPath({
    required this.word,
    required this.path,
    required this.claimedBy,
  });
}

class WordSearchGrid {
  final int rows;
  final int cols;
  final List<List<String>> grid;
  final List<String> targetWords;
  final List<FoundWordPath> foundWords;

  WordSearchGrid({
    required this.rows,
    required this.cols,
    required this.grid,
    required this.targetWords,
    this.foundWords = const [],
  });

  WordSearchGrid copyWith({
    List<FoundWordPath>? foundWords,
  }) {
    return WordSearchGrid(
      rows: rows,
      cols: cols,
      grid: grid,
      targetWords: targetWords,
      foundWords: foundWords ?? this.foundWords,
    );
  }

  factory WordSearchGrid.fromJson(Map<String, dynamic> json) {
    return WordSearchGrid(
      rows: json['rows'] as int,
      cols: json['cols'] as int,
      grid: (json['grid'] as List).map((row) => (row as List).map((c) => c as String).toList()).toList(),
      targetWords: (json['targetWords'] as List).map((w) => w as String).toList(),
    );
  }
}
