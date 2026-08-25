enum LeaderboardTab { global, friends }
enum LeaderboardPeriod { daily, weekly, monthly }

class LeaderboardEntry {
  final int rank;
  final String playerId;
  final String playerName;
  final int rating;
  final int wordsFound;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.rank,
    required this.playerId,
    required this.playerName,
    required this.rating,
    required this.wordsFound,
    this.isCurrentUser = false,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: json['rank'] as int? ?? 0,
      playerId: json['playerId'] as String? ?? '',
      playerName: json['playerName'] as String? ?? 'Player',
      rating: json['rating'] as int? ?? 0,
      wordsFound: json['wordsFound'] as int? ?? 0,
      isCurrentUser: json['isCurrentUser'] as bool? ?? false,
    );
  }
}
