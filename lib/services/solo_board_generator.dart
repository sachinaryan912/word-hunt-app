import '../models/word_search_grid.dart';

enum _Dir { e, w, n, s, se, sw, ne, nw }

const Map<_Dir, GridPos> _vectors = {
  _Dir.e: GridPos(0, 1),
  _Dir.w: GridPos(0, -1),
  _Dir.n: GridPos(-1, 0),
  _Dir.s: GridPos(1, 0),
  _Dir.se: GridPos(1, 1),
  _Dir.sw: GridPos(1, -1),
  _Dir.ne: GridPos(-1, 1),
  _Dir.nw: GridPos(-1, -1),
};

const String _letterFrequency =
    'EEEEEEEEEEEETTTTTTTTTAAAAAAAAOOOOOOOOIIIIIIIINNNNNNNNSSSSSSSHHHHHHRRRRRRDDDDLLLLCCCUUUMMMWWFFGGYYPPBBVKJXQZ';

const List<String> _wordBank = [
  'CAT', 'DOG', 'SUN', 'RUN', 'BIG', 'TOP', 'RED', 'BOX', 'FOX', 'MAP',
  'STAR', 'MOON', 'FISH', 'BIRD', 'TREE', 'LAKE', 'GAME', 'WORD', 'HUNT', 'GOLD',
  'PARK', 'RAIN', 'SNOW', 'WIND', 'FIRE', 'ROCK', 'SAND', 'LEAF', 'SEED', 'ROOT',
  'PLANT', 'GRASS', 'CLOUD', 'RIVER', 'OCEAN', 'STORM', 'LIGHT', 'NIGHT', 'SPARK', 'FLAME',
  'QUICK', 'SWIFT', 'SHARP', 'BRAVE', 'QUIET', 'HAPPY', 'SMART', 'TIGER', 'EAGLE', 'SHARK',
  'PUZZLE', 'SEARCH', 'ISLAND', 'CASTLE', 'DRAGON', 'WIZARD', 'KNIGHT', 'ARCHER', 'FOREST',
  'DESERT', 'GLACIER', 'MYSTERY', 'JOURNEY', 'TREASURE', 'ADVENTURE', 'DISCOVERY', 'MOUNTAIN',
  'CHAMPION', 'VICTORY', 'GALAXY', 'PLANET', 'COMET', 'METEOR', 'ROCKET', 'ORBIT', 'ENERGY',
  'CRYSTAL', 'EMERALD', 'SAPPHIRE', 'DIAMOND', 'THUNDER', 'LIGHTNING', 'WHISPER', 'SHADOW',
  'PHOENIX', 'GRIFFIN', 'KRAKEN', 'PEGASUS', 'CENTAUR', 'WIZARDRY', 'ALCHEMY', 'ARCANE',
  'FALCON', 'PANTHER', 'JAGUAR', 'COBRA', 'VIPER', 'HAWK', 'WOLF', 'BEAR', 'LION', 'DEER',
];

class _Tier {
  final int rows, cols, wordCount, minLen, maxLen;
  final List<_Dir> directions;
  const _Tier(this.rows, this.cols, this.wordCount, this.minLen, this.maxLen, this.directions);
}

const List<_Tier> _tiers = [
  _Tier(8, 8, 5, 3, 5, [_Dir.e, _Dir.s]),
  _Tier(9, 9, 6, 4, 6, [_Dir.e, _Dir.s, _Dir.se, _Dir.ne]),
  _Tier(10, 10, 7, 4, 7, [_Dir.e, _Dir.s, _Dir.se, _Dir.ne, _Dir.sw, _Dir.nw]),
  _Tier(11, 11, 8, 5, 8, [_Dir.e, _Dir.s, _Dir.se, _Dir.ne, _Dir.sw, _Dir.nw, _Dir.w, _Dir.n]),
  _Tier(12, 12, 9, 5, 9, [_Dir.e, _Dir.s, _Dir.se, _Dir.ne, _Dir.sw, _Dir.nw, _Dir.w, _Dir.n]),
];

int tierForLevel(int level) => (level / 4).ceil().clamp(1, 5);

class _Rng {
  int _a;
  _Rng(String seed) : _a = _hash(seed);

  static int _hash(String str) {
    var h = 1779033703 ^ str.length;
    for (var i = 0; i < str.length; i++) {
      h = _imul(h ^ str.codeUnitAt(i), 3432918353);
      h = ((h << 13) | (h >>> 19)) & 0xFFFFFFFF;
    }
    h = _imul(h ^ (h >>> 16), 2246822507);
    h = _imul(h ^ (h >>> 13), 3266489909);
    h = (h ^ (h >>> 16)) & 0xFFFFFFFF;
    return h;
  }

  static int _imul(int a, int b) => (a * b) & 0xFFFFFFFF;

  double next() {
    _a = (_a + 0x6d2b79f5) & 0xFFFFFFFF;
    var t = _a;
    t = _imul(t ^ (t >>> 15), (t | 1));
    t = (t + _imul(t ^ (t >>> 7), (t | 61))) ^ t;
    t = (t ^ (t >>> 14)) & 0xFFFFFFFF;
    return t / 4294967296;
  }

  int nextInt(int max) => (next() * max).floor();
}

class SoloBoardGenerator {
  /// (rows, cols) for the board a given level will produce, without generating it.
  static (int, int) gridSizeForLevel(int level) {
    final tier = _tiers[tierForLevel(level) - 1];
    return (tier.rows, tier.cols);
  }

  /// Deterministic per-level board for offline solo play. Doesn't need to
  /// match the server's generator bit-for-bit — solo boards are never shared
  /// with another player.
  static WordSearchGrid generate(int level, {String? seedOverride}) {
    final tier = _tiers[tierForLevel(level) - 1];
    final seed = seedOverride ?? 'solo-level-$level';
    final rng = _Rng(seed);

    final grid = List.generate(tier.rows, (_) => List<String?>.filled(tier.cols, null));

    final candidates = _wordBank.where((w) => w.length >= tier.minLen && w.length <= tier.maxLen).toList();
    final shuffled = List<String>.from(candidates);
    for (var i = shuffled.length - 1; i > 0; i--) {
      final j = rng.nextInt(i + 1);
      final tmp = shuffled[i];
      shuffled[i] = shuffled[j];
      shuffled[j] = tmp;
    }
    final words = shuffled.take(tier.wordCount).toList()..sort((a, b) => b.length.compareTo(a.length));

    final placedWords = <String>[];

    for (final word in words) {
      var placed = false;
      for (var attempt = 0; attempt < 300 && !placed; attempt++) {
        final dir = tier.directions[rng.nextInt(tier.directions.length)];
        final vec = _vectors[dir]!;

        final rowRange = _axisRange(tier.rows, vec.row, word.length);
        final colRange = _axisRange(tier.cols, vec.col, word.length);
        if (rowRange == null || colRange == null) continue;

        final startRow = rowRange.$1 + rng.nextInt(rowRange.$2 - rowRange.$1 + 1);
        final startCol = colRange.$1 + rng.nextInt(colRange.$2 - colRange.$1 + 1);

        final cells = <GridPos>[];
        var fits = true;
        for (var i = 0; i < word.length; i++) {
          final r = startRow + vec.row * i;
          final c = startCol + vec.col * i;
          if (r < 0 || r >= tier.rows || c < 0 || c >= tier.cols) {
            fits = false;
            break;
          }
          final existing = grid[r][c];
          if (existing != null && existing != word[i]) {
            fits = false;
            break;
          }
          cells.add(GridPos(r, c));
        }

        if (fits) {
          for (var i = 0; i < cells.length; i++) {
            grid[cells[i].row][cells[i].col] = word[i];
          }
          placed = true;
          placedWords.add(word);
        }
      }
    }

    final finalGrid = grid
        .map((row) => row.map((cell) => cell ?? _letterFrequency[rng.nextInt(_letterFrequency.length)]).toList())
        .toList();

    return WordSearchGrid(
      rows: tier.rows,
      cols: tier.cols,
      grid: finalGrid,
      targetWords: placedWords,
    );
  }

  /// Inclusive (min, max) start-index range along one axis for a direction step, or
  /// null if the word can't fit along that axis at all.
  static (int, int)? _axisRange(int dim, int step, int wordLen) {
    if (step == 0) return (0, dim - 1);
    if (step > 0) {
      final max = dim - wordLen;
      return max < 0 ? null : (0, max);
    }
    final min = wordLen - 1;
    return min > dim - 1 ? null : (min, dim - 1);
  }
}
