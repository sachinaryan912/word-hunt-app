import 'word_search_grid.dart';

class MatchPlayer {
  final String id;
  final String name;
  final int score;
  final int rating;
  final bool isReady;

  const MatchPlayer({
    required this.id,
    required this.name,
    required this.score,
    required this.rating,
    this.isReady = false,
  });

  MatchPlayer copyWith({int? score}) => MatchPlayer(
        id: id,
        name: name,
        score: score ?? this.score,
        rating: rating,
        isReady: isReady,
      );
}

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final bool isUser;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    required this.isUser,
  });
}

class MultiplayerMatchState {
  final String matchId;
  final MatchPlayer player;
  final MatchPlayer opponent;
  final WordSearchGrid grid;
  final List<String> recentFeed;
  final List<ChatMessage> chatMessages;

  const MultiplayerMatchState({
    required this.matchId,
    required this.player,
    required this.opponent,
    required this.grid,
    required this.recentFeed,
    required this.chatMessages,
  });

  MultiplayerMatchState copyWith({
    MatchPlayer? player,
    MatchPlayer? opponent,
    WordSearchGrid? grid,
    List<String>? recentFeed,
    List<ChatMessage>? chatMessages,
  }) {
    return MultiplayerMatchState(
      matchId: matchId,
      player: player ?? this.player,
      opponent: opponent ?? this.opponent,
      grid: grid ?? this.grid,
      recentFeed: recentFeed ?? this.recentFeed,
      chatMessages: chatMessages ?? this.chatMessages,
    );
  }
}
