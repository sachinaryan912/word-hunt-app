class AchievementItem {
  final String id;
  final String title;
  final String description;
  final bool isUnlocked;
  final String iconName;

  const AchievementItem({
    required this.id,
    required this.title,
    required this.description,
    required this.isUnlocked,
    required this.iconName,
  });

  static const Map<String, String> _iconByAchievementId = {
    'first_word': 'zap',
    'first_win': 'trophy',
    'speed_hunter': 'zap',
    'ten_wins': 'award',
    'hundred_words': 'grid',
    'perfect_level': 'check_circle',
    'comeback': 'trending_up',
    'ten_win_streak': 'flame',
    'daily_challenger': 'calendar',
    'global_top_100': 'star',
  };

  static String iconFor(String achievementId) => _iconByAchievementId[achievementId] ?? 'check_circle';
}

class PlayerProfile {
  final String id;
  final String name;
  final String? avatarId;
  final int level;
  final double xpProgress;
  final int xp;
  final int rating;
  final int totalGames;
  final int totalWins;
  final double winRate;
  final int bestScore;
  final int winStreak;
  final int bestStreak;
  final int wordsFoundTotal;
  final int soloLevelsCompleted;

  const PlayerProfile({
    required this.id,
    required this.name,
    this.avatarId,
    required this.level,
    required this.xpProgress,
    required this.xp,
    required this.rating,
    required this.totalGames,
    required this.totalWins,
    required this.winRate,
    required this.bestScore,
    required this.winStreak,
    required this.bestStreak,
    required this.wordsFoundTotal,
    required this.soloLevelsCompleted,
  });

  static int _xpForLevel(int level) => (level - 1) * 200;

  /// XP earned since the current level started (for "X / Y XP" display).
  int get xpIntoLevel => xp - _xpForLevel(level);

  /// XP required to reach the next level.
  int get xpForNextLevel => _xpForLevel(level + 1) - _xpForLevel(level);

  static double _xpProgressFor(int xp, int level) {
    final floor = _xpForLevel(level);
    final ceiling = _xpForLevel(level + 1);
    if (ceiling == floor) return 0;
    return ((xp - floor) / (ceiling - floor)).clamp(0.0, 1.0);
  }

  factory PlayerProfile.fromJson(Map<String, dynamic> json) {
    final level = json['level'] as int? ?? 1;
    final xp = json['xp'] as int? ?? 0;
    final gamesPlayed = json['gamesPlayed'] as int? ?? 0;
    final wins = json['wins'] as int? ?? 0;
    return PlayerProfile(
      id: json['uid'] as String? ?? '',
      name: json['displayName'] as String? ?? 'Guest',
      avatarId: (json['avatar'] as String?)?.isNotEmpty == true ? json['avatar'] as String : null,
      level: level,
      xpProgress: _xpProgressFor(xp, level),
      xp: xp,
      rating: json['rating'] as int? ?? 1200,
      totalGames: gamesPlayed,
      totalWins: wins,
      winRate: gamesPlayed > 0 ? (wins / gamesPlayed) * 100 : 0,
      bestScore: json['bestScore'] as int? ?? 0,
      winStreak: json['winStreak'] as int? ?? 0,
      bestStreak: json['bestStreak'] as int? ?? 0,
      wordsFoundTotal: json['wordsFoundTotal'] as int? ?? 0,
      soloLevelsCompleted: json['soloLevelsCompleted'] as int? ?? 0,
    );
  }

  static PlayerProfile empty(String id) => PlayerProfile(
        id: id,
        name: 'Guest',
        level: 1,
        xpProgress: 0,
        xp: 0,
        rating: 1200,
        totalGames: 0,
        totalWins: 0,
        winRate: 0,
        bestScore: 0,
        winStreak: 0,
        bestStreak: 0,
        wordsFoundTotal: 0,
        soloLevelsCompleted: 0,
      );
}
